program _svm, plugin /*load the C extension if not already loaded*/

/* TODO: give a probability option, which triggers svm_predict_probability() and does stemming to generate a bunch of new variables to hold the results */
// (we do not support svm_predict_values() because there's no good way to squish it into Stata's interface and it's not very interesting anyway

program define svm_predict, eclass
  version 13
  syntax newvarname [if] [in], [PROBability]
  local target = "`varlist'"
  local _in = "`in'" //these need to be stashed because the hack below will smash them
  local _if = "`if'"
  
  * C plugins can only speak to variables mentioned in the varlist they are called with
  * that is, if we are going predict on some vectors, we need to know what X variables we're
  * predicting on in their entirety before we call down to C--and they should match what 
  
  * I haven't discovered how regress and friends manage to know which variables to predict on
  * the only place I see them record what they did is in e(cmdline)
  * but that has cruft in it
  * the easiest way I can think to extract the predictor list is to *reparse* the command line
  * TODO: consider if it's saner to simply store e(indepvars) or e(predictors) or something
  local 0 = "`e(cmdline)'"
  gettoken cmd 0 : 0 /*remove the command which was artificially tacked on by svm_train*/
  syntax varlist [if] [in], * //* puts the remainder in `options' and allows this code to be isolated from svm_train (it's not like we actually could tweak anything, since the svm_model is stored on the plugin's C heap)
  gettoken y varlist : varlist /*remove the first column*/
  assert "`y'" == "`e(depvar)'"
  
  * make the target column
  generate_clone `e(depvar)' `target'
  
  * allocate space (we use new variables) to put probability estimates for each class for each prediction
  * this only makes sense in a classification problem, but we do not check for that
  if("`probability'"!="") {
    // ensure type is categorical
    local T : type `target'
    if("`T'"!="byte" & "`T'"!="int" & "`T'"!="long") {
      di as error "It makes no sense to ask for class probability estimates for `target', as it is a `T'"
      exit 1
    }
    
    // save the top level description to splay across the stemmed variables
    local D : variable label `target'
    
    // loop over the possible (integer) values
    // this is the construction given at http://www.stata.com/support/faqs/data-management/try-all-values-with-foreach/
    // trying to loop over r(levels) directly fails with a syntax error because Stata
    quietly levelsof `e(depvar)', local(levels) 
    foreach c of local levels {
      // this command is obscure; what it does is look up the
      // value label for variable `target' for value `c'
      // *or* give back `c' unchanged if `target' has no labels
      // which is precisely what we want it to do here
      local L : label (`target') `c'
      // make L safe for use as a variable name. hopefully.
      local L = subinstr("`L'"," ","_",.)
      // compute the full variable name for level `c'
      local stemmed = "`target'_`L'"
      
      // finally, allocate it
      // unlike `target' which clones its source, we use doubles
      // because these are meant to hold probabilities
      
      // TODO: what happens if there's a name collision partially through this loop?
      //       what I want to happen is for any name collision to abort (i.e. rollback) the entire operation
      quietly generate double `stemmed' = .
      label variable `stemmed' "Probability of `D' being category `L'"
      
      // attach the newcomers to the varlist so the plugin is allowed to edit them
      local varlist = "`varlist' `stemmed'"
    }
  }
  else {
    // for good measure, make sure levels is allocated in either case
    local levels = ""
  }
  
  * call down into C
  // Subtlety: we don't quote levels, on the assumption that it is always a list of integers;
  //           that way, the levels are pre-tokenized and the count easily available as argc
  *di as txt "svm_predict: plugin call _svm `target' `varlist' `_if' `_in', predict `levels'" /*DEBUG*/
  plugin call _svm `target' `varlist' `_if' `_in', predict `levels'
end
