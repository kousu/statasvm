capture program _svm, plugin /*load the C extension if not already loaded*/

program define svm_train, eclass
  syntax varlist [if] [in], [options_go_here]
  
  /* call down into C */
  plugin call _svm `varlist' `if' `in', "train"
  
  ereturn clear 
  /* fixup the e() dictionary */
  
  * set standard Stata regression properties
  ereturn local cmd = "svm_train"
  ereturn local cmdline = "`e(cmd)' `0'"
  ereturn local predict = "svm_predict"
  ereturn local model = "svm" /*TODO: be more specific? e.g. svr, nu-SVC, etc?*/
  ereturn local title = "Support Vector Machine"
  
  gettoken depvar : varlist
  ereturn local depvar = "`depvar'"
  
  * export the svm_model structure
  _svm_model2stata
end
