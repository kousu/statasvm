/* svm_predict:  after fitting an SVM model with svm, construct predicted classes/values (depending on the type of the active SVM) */

/* load the C extension */
svm_ensurelib           // check for libsvm
program _svmachines, plugin    // load the wrapper for libsvm

program define svm_predict, eclass
  version 13
  syntax newvarname [if] [in], [PROBability] [scores] [Verbose]
  local target = "`varlist'"
  local _in = "`in'" //these need to be stashed because the hack below will smash them
  local _if = "`if'"

  if("`probability'"!="" & "`scores'"!="") {
    di as err "Error: probability and scores are mutually exclusive options."
    exit 2
  }
  
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
  if("`e(svm_type)'"!="ONE_CLASS") {
    gettoken y varlist : varlist  // pop the first variable
    assert "`y'" == "`e(depvar)'" // and check consistency with the svm_train

    // make the target column
    // it is safe to assume that `target' is a valid variable name: "syntax" above enforces that
    //  and it should be safe to assume the same about `e(depvar)': unless the user is messing with us (in which case, more power to them), it should have been created by svm_train and validated at that point
    quietly clone `target' `e(depvar)' if 0 //'if 0' leaves the values as missing, which is important: we don't want a bug in the plugin to translate to source values sitting in the variable (and thus inflating the observed prediction rate)
    local L : variable label `target'
    if("`L'"!="") {
      label variable `target' "Predicted `L'"
    }
  }
  else {
    //ONE_CLASS
    quietly gen int `target' = .
    label variable `target' "Within support"
  }
  
  if("`probability'"!="") {
    // allocate space (we use new variables) to put probability estimates for each class for each prediction

    // ensure model is a classification
    // this duplicates code over in svm_train, but I think this is safest:
    //  svm_import allows you to pull in svm_models created by other libsvm
    //  interfaces, and they mostly don't have this protection. 
    if("`e(svm_type)'" != "SVC" & "`e(svm_type)'" != "NU_SVC") {
      // in svm-predict.c, the equivalent section is:
      /*
       *        if (predict_probability && (svm_type==SVC || svm_type==NU_SVC))
       *                predict_label = svm_predict_probability(model,x,prob_estimates);
       *        else
       *                predict_label = svm_predict(model,x);
       */
      // it is cleaner to error out, rather than silently change the parameters, which is what the command line tools do
      di as error "Error: trained model is a `e(svm_type)'. You can only use the probability option with classification models (SVC, NU_SVC)."
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
    foreach l in `e(levels)' {
      // l is the "label" for each class, but it's just an integer (whatever was in the original data table)
      
      // We try to label each column by the appropriate string label, for readability,
      //  but if it doesn't exist we fall back on the integer label.
      //
      // The command to do this is poorly documented. What this line does is
      //  look up the value label for value `l'
      //  *or* give back `l' unchanged if `target' has no labels
      //  which is precisely what we want it to do here.
      local L : label (`e(depvar)') `l'
      
      // compute the full variable name for level `l'
      local stemmed = "`target'_`L'"
      local stemmed = strtoname("`stemmed'") //sanitize the new name; this summarily avoids problems like one of your classes being "1.5"
      
      // finally, allocate it
      // unlike `target' which clones its source, we use doubles
      // because these are meant to hold probabilities
      
      // TODO: what happens if there's a name collision partially through this loop?
      //       what I want to happen is for any name collision or other bug to abort (i.e. rollback) the entire operation
      //       This can be achieved with "snapshot": snapshot; capture {}; if(fail) { rollback to snapshot }"
      quietly generate double `stemmed' = .
      label variable `stemmed' "Pr(`D'==`L')"
      
      // attach the newcomers to the varlist so the plugin is allowed to edit them
      local varlist = "`varlist' `stemmed'"
    }
  }
  else if("`scores'"!="") { // else-if because these options are mutually exclusive (which is enforced above)
    // Allocate space for the decision values
    // This is more complicated because we need to go down a lower triangle of a matrix -- so, a length-changing nested loop.
    // we have to use word("`e(levels)'", i) to extract the ith level
    // which means we have an extra layer of indirection to deal with, so there's x_i the index into e(labels), x the integer label, and X the string (or possibly integer) label
    
    // we need to split the cases of classification and non-classification models
    //  reason i:  non-classification models have model->label == NULL which means e(levels) is missing which breaks this code
    //  reason ii: non-classification models only have one decision value, so the sensible label is just "`target'_score"
    if("`e(svm_type)'" == "ONE_CLASS" | "`e(svm_type)'" == "SVR" | "`e(svm_type)'" == "NU_SVR") {
      // generate the name of the new column.
      // it is, unfortunate, somewhat terse, in hopes of keeping within 32 characters
      local stemmed = "`target'_score"
      local stemmed = strtoname("`stemmed'")  //make it Stata-safe
      
      // allocate the decision value column
      quietly generate double `stemmed' = .
      label variable `stemmed' "`target' svm score"
      
      // attach the newcomers to the varlist so the plugin is allowed to edit them
      local varlist = "`varlist' `stemmed'"
    }
    else if("`e(svm_type)'" == "SVC" | "`e(svm_type)'" == "NU_SVC") {
      local no_levels = `e(N_class)'
      forvalues l_i = 1/`no_levels' {
        //di "l_i = `l_i'"
        local l = word("`e(levels)'", `l_i')
        local L : label (`e(depvar)') `l'
        forvalues r_i = `=`l_i'+1'/`no_levels' {
          //di "r_i = `r_i'"
          local r = word("`e(levels)'", `r_i')  // map the index into the labels
          local R : label (`e(depvar)') `r'
          //di "generating svm score column (`l_i',`r_i') <=> (`l',`r') <=> (`L',`R')"
          
          // generate the name of the new column.
          // it is, unfortunate, somewhat terse, in hopes of keeping within 32 characters
          local stemmed = "`target'_`L'_`R'"
          local stemmed = strtoname("`stemmed'")  //make it Stata-safe
        
          // allocate the decision value column
          quietly generate double `stemmed' = .
          label variable `stemmed' "`target' svm score `L' vs `R'"
          
          // attach the newcomers to the varlist so the plugin is allowed to edit them
          local varlist = "`varlist' `stemmed'"
        }
      }
    }
    else {
      di as error "Unrecognized svm_type `e(svm_type)'; unable to define svm score columns."
      exit 2
    }
  }
  
  // call down into C
  // we indicate "probability" mode by passing a non-empty list of levels
  //  this list implicitly *removes* from the set range of variables to predict from: the trailing variables are instead write locations
  //  (this feels like programming a hardware driver)
  // Subtlety: we don't quote levels, on the assumption that it is always a list of integers;
  //           that way, the levels are pre-tokenized and the count easily available as argc
  
  plugin call _svmachines `target' `varlist' `_if' `_in', `verbose' predict `probability' `scores'

  if("`e(svm_type)'"=="ONE_CLASS") {    
    // libsvm gives {1,-1} for its one-class predictions;
    // normalize these to {1,0}
    qui replace `target' = 0 if `target' == -1
  }
end





/* clone.ado: generate a perfect copy of a variable: type, labels, etc.

 syntax:
  clone newvar oldvar [if] [in]
 
 You can use 'if' and 'in' to control what values; values that don't match will be set to missing.
 If you want to clone a variable's metadata but not values use the idiom ". clone new old if 0".

 NB: The reason the syntax is not "clone newvar = oldvar", even though that would fit the pattern
     set by generate and egen, is that syntax's =/exp option insists on parsing numeric expressions,
     so string variables wouldn't be cloneable.
 */
 

program define clone
  version 13
  
  // parse once to extract the basic pieces of syntax
  syntax namelist [if] [in]
  local _if = "`if'" //save these for later; the other syntax commands will smash them
  local _in = "`in'"
  
  gettoken target source : namelist
  
  // enforce types
  confirm new variable `target'
  confirm variable `source'
  
  // save attributes
  local T : type `source' //the data type
  local N : variable label `source' //the human readable description
  local V : value label `source' // the name of the label map in use, if there is one
                                 // Stata maintains a dictionary of dictionaries, each of which
                                 // maps integers to strings. Multiple variables can share a dictionary,
                                 // though it is rare except for e.g. "boolean"
  
  // make new variable
  generate `T' `target' = `source' `_if' `_in'
  
  // clone attributes if they exist
  // (except for type, which always exists and cannot be reassigned without
  //  another 'generate' doing a whole new malloc())
  if("`N'"!="") {
    label variable `target' "`N'"  //Yes, the setters and getters are...
  }
  if("`V'"!="") {
    label value `target' "`V'"     //...in fact reverses of each other
  }
end
