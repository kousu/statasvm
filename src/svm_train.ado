capture program _svm, plugin /*load the C extension if not already loaded*/

program define svm_train, eclass
  syntax [varlist] [if] [in]
  
  * load _svm if it's not already loaded
  * TODO: speedtest this; does it make a difference if loading happens outside or inside?
  capture program _svm, plugin
  
  if word count `varlist' < 2 {
    di as error "Two few variables: need one dependent and at least one independent variable.".
    exit
  }
	
  plugin call _svm `varlist' `if' `in', "tfrain"

  ereturn clear
  
end
