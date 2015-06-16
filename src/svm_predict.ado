
/* load the C extension */
ensurelib_aberrance svm // check for libsvm
program _svm, plugin    // load _svm.plugin, the wrapper for libsvm

program define svm_predict, eclass
  version 13
  syntax newvarname [if] [in], [PROBability] [Verbose]
  local target = "`varlist'"
  local _in = "`in'" //these need to be stashed because the hack below will smash them
  local _if = "`if'"
  
  // C plugins can only speak to variables mentioned in the varlist they are called with
  // that is, if we are going predict on some vectors, we need to know what X variables we're
  // predicting on in their entirety before we call down to C--and they should match what 
  
  // I haven't discovered how regress and friends manage to know which variables to predict on
  // the only place I see them record what they did is in e(cmdline)
  // but that has cruft in it
  // the easiest way I can think to extract the predictor list is to *reparse* the command line
  // TODO: consider if it's saner to simply pre-store e(indepvars) or e(predictors) or something
  local 0 = "`e(cmdline)'"
  gettoken cmd 0 : 0 /*remove the command which was artificially tacked on by svm_train*/
  syntax varlist [if] [in], * //* puts the remainder in `options' and allows this code to be isolated from svm_train (it's not like we actually could tweak anything, since the svm_model is stored on the plugin's C heap)
  gettoken y varlist : varlist // remove the first column to check
  assert "`y'" == "`e(depvar)'" // consistency with the svm_train
  
  // make the target column
  // it is safe to assume that `target' is a valid variable name: "syntax" above enforces that
  //  and it should be safe to assume the same about `e(depvar)': unless the user is messing with us (in which case, more power to them), it should have been created by svm_train and validated at that point
  quietly clone `target' `e(depvar)' if 0 //'if 0' leaves the values as missing, which is important: we don't want a bug in the plugin to translate to source values sitting in the variable (and thus inflating the observed prediction rate)
  local L : variable label `target'
  label variable `target' "Predicted `L'"
  
  // allocate space (we use new variables) to put probability estimates for each class for each prediction
  // this only makes sense in a classification problem, but we do not check for that
  if("`probability'"!="") {
    // ensure model is a classification
    // this duplicates code over in svm_train, but I think this is safest:
    //  svm_import allows you to pull in svm_models created by other libsvm
    //  interfaces, and they mostly don't have this protection. 
    if("`e(svm_type)'" != "C_SVC" & "`e(svm_type)'" != "NU_SVC") {
      // in svm-predict.c, the equivalent section is:
      /*
       *        if (predict_probability && (svm_type==C_SVC || svm_type==NU_SVC))
       *                predict_label = svm_predict_probability(model,x,prob_estimates);
       *        else
       *                predict_label = svm_predict(model,x);
       */
      // it is cleaner to error out, rather than silently change the parameters, which is what the command line tools do
      di as error "Error: trained model is a `e(svm_type)'. You can only use the probability option with classification models (C_SVC, NU_SVC)."
      exit 2
    }
    
    // save the top level description to splay across the stemmed variables
    local D : variable label `target'
    
    // Collect (and create) the probability columns
    // TODO:  get it to generate the columns in the "levelsof" order, but actually use them in the libsvm order
    //         -> right now it is in the libsvm order, which is fine. the results are correct. they're just not as convenient. 
    // BEWARE: the order of iteration here is critical:
    //     it MUST match the order in svm_model->labels or results will silently be permuted
    //     the only way to achieve this is to record the order in svm_model->labels and loop over that explicitly, which is what e(levels) is for
    assert "`e(levels)'" != ""
    foreach c in `e(levels)' {
      // this command is obscure; what it does is look up the
      // value label for variable `target' for value `c'
      // *or* give back `c' unchanged if `target' has no labels
      // which is precisely what we want it to do here
      local L : label (`target') `c'
      // compute the full variable name for level `c'
      local stemmed = "`target'_`L'"
      local stemmed = strtoname("`stemmed'") //sanitize the new name; this summarily avoids problems like one of your classes being "1.5"
      
      // finally, allocate it
      // unlike `target' which clones its source, we use doubles
      // because these are meant to hold probabilities
      
      // TODO: what happens if there's a name collision partially through this loop?
      //       what I want to happen is for any name collision or other bug to abort (i.e. rollback) the entire operation
      //       This can be achieved with "snapshot": snapshot; capture {}; if(fail) { rollback to snapshot }"
      quietly generate double `stemmed' = .
      label variable `stemmed' "Probability of `D' being category `L'"
      
      // attach the newcomers to the varlist so the plugin is allowed to edit them
      local varlist = "`varlist' `stemmed'"
    }
  }
  
  
  // call down into C
  // we indicate "probability" mode by passing a non-empty list of levels
  //  this list implicitly *removes* from the set range of variables to predict from: the trailing variables are instead write locations
  //  (this feels like programming a hardware driver)
  // Subtlety: we don't quote levels, on the assumption that it is always a list of integers;
  //           that way, the levels are pre-tokenized and the count easily available as argc
  
  plugin call _svm `target' `varlist' `_if' `_in', `verbose' predict `probability'
end
