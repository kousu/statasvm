
/* load the C extension */
ensurelib_aberrance svm // check for libsvm
program _svm, plugin    // load _svm.plugin, the wrapper for libsvm

* export a libsvm model file
program define svm_export
  version 13
  syntax using/
  
  // ensure that there (should be) a svm_model in memory
  if("`e(model)'"!="svm") {
    di as error "svm_export: you need to run an svm first\n");
    exit 1;
  }

  plugin call _svm, "export" "`using'"
end
