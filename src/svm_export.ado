program _svm, plugin /*load the C extension if not already loaded*/

* export a libsvm model file
program define svm_export
  syntax using/
  
  plugin call _svm, "export" "`using'"
end
