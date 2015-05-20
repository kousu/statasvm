capture program _svm, plugin /*load the C extension if not already loaded*/

program define svm_train, eclass
  syntax varlist [if] [in]
	
  plugin call _svm `varlist' `if' `in', "train"

  ereturn clear
  _svm_model2stata /*fixup the e() dictionary*/
  
end
