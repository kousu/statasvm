
/* load the C extension */
ensurelib_aberrance svm // check for libsvm
program _svm, plugin    // load _svm.plugin, the wrapper for libsvm

* import a libsvm model file
* XXX because of how the libsvm variable labels don't necessarily align with the Stata ones,
*  this is of limited usefulness; you are better off svm_train'ing from scratch, to make sure everything is in place
program define svm_import, eclass
  version 13
  syntax using/, [Verbose]
  
  plugin call _svm, `verbose' "import" "`using'"
  
  ereturn clear
  _svm_model2stata, `verbose' /*fixup the e() dictionary, as if we'd just called svm_train; except in this path we don't have a dataset linked, so we don't pass sv() and we don't expect to get */
end
