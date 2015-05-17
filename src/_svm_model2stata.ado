capture program _svm, plugin /*load the C extension if not already loaded*/ 

* subroutine to convert the global struct svm_model that lives in the DLL to a mixture of e() entries, variables, and matrices
* this needs to be its own subroutine because, due to limitations in the Stata C API,th 
* it does an awkward dance where _svm.plugin writes to the (global!) scalar dict and then this code copies those entries to r()
* as with svm_load, the extension function is called multiple times with sub-sub-commands, because it doesn't have permission to perform all the operations needed
program define _svm_model2stata, eclass
  
  * as with loading, this has to call in and out of the plugin because chicken/egg:
  *   the plugin doesn't have permission to allocate Stata memory (in this case matrices),
  *   but we don't know how much to allocate before interrogating the svm_model
  
  local have_sv_indices = 0
  local have_rho = 0
  local have_probA = 0 /*an undefined macro will inconsistently cause an eval error because `have_rho'==1 will eval to ==1 will eval to "unknown variable"*/
  local have_probB = 0 /*so just define them ahead of time to be safe*/
  
  
  * Phase 1
  plugin call _svm, "_model2stata" 1
  
  * the total number of (detected?) classes
  ereturn scalar nr_class = _model2stata_nr_class
  scalar drop _model2stata_nr_class
  
  * the number of support vectors
  ereturn scalar l = _model2stata_l
  scalar drop _model2stata_l
  
  
  
  * Phase 2
  
  * Allocate Stata matrices to copy the libsvm matrices and vectors
  
  *TODO: SV and sv_indices are probably best translated jointly by adding an indicator variable column to the original dataset telling if that observation was chosen as a support vector (of course, this will mean we need to further clamp the upper limit)
  
  if(`have_sv_indices'==1) {
    matrix SVs = J(e(l),1,.) /*but for now we can just copy out sv_indices*/
    matrix colnames SVs = "SVs"
  }
  
  * nSV tells how many support vectors went into each class
  * The sum of the entries in nSV should be l
  matrix nSV = J(e(nr_class),1,.)
  matrix colnames nSV = "nSV"
  /*matrix rownames nSV = . . */
  
  matrix labels = J(e(nr_class),1,.)
  matrix colnames labels = "labels"
  
  matrix sv_coef = J(e(nr_class)-1,e(l),.)
  if(`have_rho'==1) {
    matrix rho = J(e(nr_class),e(nr_class),.)
  }
  if(`have_probA'==1) {
    matrix probA = J(e(nr_class),e(nr_class),.)
  }
  if(`have_probB'==1) {
    matrix probB = J(e(nr_class),e(nr_class),.)
  }
  
  
  * TODO: also label the rows according to model->label (libsvm's "labels" are just more integers, but it helps to be consistent anyway);
  *  I can easily extract ->label with the same code, but attaching it to the rownames of the other is tricky
  plugin call _svm, "_model2stata" 2
  
  
  
end
