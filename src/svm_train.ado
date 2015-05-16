capture program _svm, plugin /*load the C extension if not already loaded*/

program define svm_train, eclass
  syntax varlist [if] [in]
  
  if(wordcount("`varlist'") < 2) {
    di as error "Two few variables: need one dependent and at least one independent variable.".
    exit
  }
	
  plugin call _svm `varlist' `if' `in', "train"

  _svm_model2stata /*fixup the e() dictionary*/
  
end
