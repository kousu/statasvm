capture program _svm, plugin /*load the C extension if not already loaded*/

* import a libsvm model file
program define svm_import
  syntax using/
  
  plugin call _svm, "import" "`using'"
  
end
