capture program _svm, plugin /*load the C extension if not already loaded*/ 

* subroutine to convert the global struct svm_model that lives in the DLL to a mixture of e() entries, variables, and matrices
* this needs to be its own subroutine because, due to limitations in the Stata C API,th 
* it does an awkward dance where _svm.plugin writes to the (global!) scalar dict and then this code copies those entries to r()
* as with svm_load, the extension function is called multiple times with sub-sub-commands, because it doesn't have permission to perform all the operations needed
program define _svm_model2stata, eclass
  
  * as with loading, this has to call in and out of the plugin because chicken/egg:
  *   the plugin doesn't have permission to allocate Stata memory (in this case matrices),
  *   but we don't know how much to allocate before interrogating the svm_model
  
  * Phase 1
  plugin call _svm, "_model2stata" 1
  
  * the total number of (detected?) classes
  ereturn scalar nr_class = _model2stata_nr_class
  scalar drop _model2stata_nr_class
  
  * the number of support vectors
  ereturn scalar l = _model2stata_l
  scalar drop _model2stata_l
  
  
  * Phase 2
  
  * nSV tells how many support vectors went into each class
  * The sum of the entries in nSV should be l
  matrix nSV = J(e(nr_class),1,.)
  matrix colnames nSV = "nSV"
  matrix rownames nSV = . . 
  * TODO: also label the rows according to model->label (libsvm's "labels" are just more integers, but it helps to be consistent anyway);
  *  I can easily extract ->label with the same code, but attaching it to the rownames of the other is tricky
  plugin call _svm, "_model2stata" 2
  
  *TODO: SV and sv_indices are probably best translated jointly by adding an indicator variable column to the original dataset telling if that observation was chosen as a support vector (of course, this will mean we need to further clamp the upper limit)
  *TODO: rho, probA and probB are n(n-1)/2-long arrays, which *probably* means they are actually symmetric nxn matrices; they should be extracted to matrix form. They don't always exist, though!!
  
  * Phase 3: extract the model parameters (XXX should this be its own subroutine?)
  
end
