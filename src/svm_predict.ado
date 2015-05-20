capture program _svm, plugin /*load the C extension if not already loaded*/

program define svm_predict, eclass
  syntax namelist(max=1) [if] [in]
  local target = "`namelist'"
  
  * C plugins can only speak to variables mentioned in the varlist they are called with
  * that is, if we are going predict on some vectors, we need to know what X variables we're
  * predicting on in their entirety before we call down to C--and they should match what 
  
  
  * We assume svmlight format: first column is the response, the rest are predictors 
  * We use the 'ds' ('DataSet') command, on a tip from Nick Cox (the only working Stata Programmer, apparently) not to use it:
  * http://www.stata-journal.com/article.html?article=dm0048
  * it is not very good but it is built in
  quiet ds *
  local varlist = "`r(varlist)'"
  gettoken y varlist : varlist /*remove the first column*/
  local varlist = subinword("`varlist'", "`target'", "",.) /*remove the target, if it's in the list*/
    
  * make the target column if it doesn't exist
  * (but it is okay if it does: the plugin will just overwrite any values; the user might be using
  *  'if'/'in' to do the prediction in stages, trying things out with generated samples, etc)
  capture generate `target' = .
  
  * double-check that target doesn't appear in varlist
  if(`= strpos("`varlist'","`target'")'!=0) {
    di as error "svm_predict: you may not specify a predictor as the output variable"
    exit 1
  } 
  
  *di "svm_predict: plugin call _svm `target' `varlist' `if' `in', predict" /*DEBUG*/
  plugin call _svm `target' `varlist' `if' `in', predict

  ereturn clear
  /*fixup the e() dictionary*/
  /* TODO: currently this is empty, but svm_predict_probability() or svm_predict_values() give information;;; perhaps we can request them via a flag */
  
end
