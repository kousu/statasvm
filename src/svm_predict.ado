capture program _svm, plugin /*load the C extension if not already loaded*/

program define svm_predict, eclass
  gettoken name 0 : 0
  syntax name [if] [in]
  
  * C plugins can only speak to variables mentioned in the varlist they are called with
  * so if we want to write into an unused column we must first make it up here, and then pass it down *along with all the others*
  
  * We use the 'ds' command, on a tip from Nick Cox (the only Stata Programmer, apparently), because it is built in
  * http://www.stata-journal.com/article.html?article=dm0048
  ds *
  
  * make the column if it doesn't exist
  * (but be okay if it does: the plugin will just overwrite any values, but the user might be using 'if'/'in' to do the prediction in stages, for some reason)
  capture generate `namelist' = .
  
  
  
  plugin call _svm `namelist'  `if' `in', "predict"

  ereturn clear
  /*fixup the e() dictionary*/
  
end
