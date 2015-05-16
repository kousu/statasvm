capture program _svm, plugin /*load the C extension if not already loaded*/

* subroutine to convert the global struct svm_model that lives in the DLL to a mixture of e() entries, variables, and matrices
* this needs to be its own subroutine because, due to limitations in the Stata C API,
* it does an awkward dance where _svm.plugin writes to the (global!) scalar dict and then this code copies those entries to r()
program define _svm_model2stata, eclass
  
  plugin call _svm, "_model2stata"
  
  ereturn clear
  
  ereturn scalar nr_class = _model2stata_nr_class
  scalar drop _model2stata_nr_class
  
end
