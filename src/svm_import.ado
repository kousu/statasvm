capture program _svm, plugin /*load the C extension if not already loaded*/

* import a libsvm model file
program define svm_import, eclass
  syntax using/
  
  plugin call _svm, "import" "`using'"
  
  _svm_model2stata /*fixup the e() dictionary, as if we'd just called svm_train*/
end
