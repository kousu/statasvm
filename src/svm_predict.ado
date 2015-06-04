
/* load the C extension */
ensurelib_aberrance svm // check for libsvm
program _svm, plugin    // load _svm.plugin, the wrapper for libsvm

program define svm_predict, eclass
  version 13
  syntax newvarname [if] [in], [PROBability]
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
  gettoken y varlist : varlist /*remove the first column*/
  assert "`y'" == "`e(depvar)'"
  
  // make the target column
  // it is safe to assume that `target' is a valid variable name: "syntax" above enforces that
  //  and it should be safe to assume the same about `e(depvar)': unless the user is messing with us (in which case, more power to them), it should have been created by svm_train and validated at that point
  generate_clone `e(depvar)' `target'
  
  // allocate space (we use new variables) to put probability estimates for each class for each prediction
  // this only makes sense in a classification problem, but we do not check for that
  if("`probability'"!="") {
    // ensure type is categorical
    local T : type `e(depvar)'
    if("`T'"=="float" | "`T'"=="double") {
      di as error "Warning: `e(depvar)' is a `T', which is usually used for continuous variables."
      di as error "         It makes no sense to ask for category probabilities of continuous variables."
      di as error ""
      di as error "         If your variable is actually categorical, consider storing it as one:"
      di as error "         . tempvar B"
      di as error "         . generate byte \`B' = `e(depvar)'"   //CAREFUL: B is meant to be quoted and depvar is meant to be unquoted.
      di as error "         . drop `e(depvar)'"
      di as error "         . rename \`B' `e(depvar)'"
      di as error " "
      di as error "         SVM prediction is now being performed, but if your results are absurd, check that you have fit the right variable."
    }
    
    // save the top level description to splay across the stemmed variables
    local D : variable label `target'
    
    // loop over the possible (integer) values
    // this is the construction given at http://www.stata.com/support/faqs/data-management/try-all-values-with-foreach/
    // trying to loop over r(levels) directly fails with a syntax error because Stata
    quietly levelsof `e(depvar)', local(levels)
    // XXX the order of iteration here is critical:
    //     it MUST match the order in svm_model->labels or results will silently be permuted
    //     (and with several classes this becomes a big problem)
    foreach c of local levels {
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
  
  //di as txt "svm_predict: plugin call _svm `target' `varlist' `_if' `_in', predict `probability'" /*DEBUG*/
  plugin call _svm `target' `varlist' `_if' `_in', predict `probability'
end
