program _svm, plugin /*load the C extension if not already loaded*/

/* TODO: give a probability option, which triggers svm_predict_probability() and does stemming to generate a bunch of new variables to hold the results */
// (we do not support svm_predict_values() because there's no good way to squish it into Stata's interface and it's not very interesting anyway

program define svm_predict, eclass
  version 13
  syntax newvarname [if] [in]
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
  
  * call down into C
  *di "svm_predict: plugin call _svm `target' `varlist' `_if' `_in', predict" /*DEBUG*/
  plugin call _svm `target' `varlist' `_if' `_in', predict
end
