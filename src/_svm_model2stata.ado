
/* load the C extension */
ensurelib_aberrance svm // check for libsvm
program _svm, plugin    // load _svm.plugin, the wrapper for libsvm

* subroutine to convert the global struct svm_model that lives in the DLL to a mixture of e() entries, variables, and matrices
* this needs to be its own subroutine because, due to limitations in the Stata C API,th 
* it does an awkward dance where _svm.plugin writes to the (global!) scalar dict and then this code copies those entries to r()
* as with svm_load, the extension function is called multiple times with sub-sub-commands, because it doesn't have permission to perform all the operations needed
* if passed, SV specifies a column to create and record svm_model->sv_indecies into
program define _svm_model2stata, eclass
  version 13

  
  syntax [if] [in], [SV(string)]
  
  * as with loading, this has to call in and out of the plugin because chicken/egg:
  *   the plugin doesn't have permission to allocate Stata memory (in this case matrices),
  *   but we don't know how much to allocate before interrogating the svm_model
  
  local strLabels = ""
  local have_sv_indices = 0
  local have_rho = 0
  local have_probA = 0 /*an undefined macro will inconsistently cause an eval error because `have_rho'==1 will eval to ==1 will eval to "unknown variable"*/
  local have_probB = 0 /*so just define them ahead of time to be safe*/
  
  
  * Phase 1
  plugin call _svm `if' `in', "_model2stata" 1
  
  * the total number of (detected?) classes
  ereturn scalar nr_class = _model2stata_nr_class
  scalar drop _model2stata_nr_class
  
  * the number of support vectors
  ereturn scalar l = _model2stata_l
  scalar drop _model2stata_l
  
  
  
  * Phase 2
  * Allocate Stata matrices and copy the libsvm matrices and vectors
  
  *TODO: SV and sv_indices are probably best translated jointly by adding an indicator variable column to the original dataset telling if that observation was chosen as a support vector (of course, this will mean we need to further clamp the upper limit)
  
  

  * nSV tells how many support vectors went into each class
  * The sum of the entries in nSV should be l
  matrix nSV = J(e(nr_class),1,.)
  matrix colnames nSV = "nSV"
  /*matrix rownames nSV = . . */
  
  if(`e(nr_class)'>0) {
    matrix labels = J(e(nr_class),1,.)
    matrix colnames labels = "labels"
  }
  
  if(`e(nr_class)'>1 & `e(l)'>0) {
    capture noisily {
      matrix sv_coef = J(e(nr_class)-1,e(l),.)
      
      // there doesn't seem to be an easy way to generate a list of strings with a prefix in Stata
      // so: the inefficient way
      local cols = ""
      forval j = 1/`e(l)' {
        local cols = "`cols' SV`j'"
      }
      matrix colnames sv_coef = `cols'
      
      // TODO: rows
      //  there is one row per class *less one*. the rows probably represent decision boundaries, then. I'm not sure what this should be labelled.
      // matrix rownames sv_coef = class1..class`e(l)'
    }
  }
  
  if(`have_rho'==1 & `e(nr_class)'>0) {
    capture noisily matrix rho = J(e(nr_class),e(nr_class),.)
  }
  if(`have_probA'==1 & `e(nr_class)'>0) {
    capture noisily matrix probA = J(e(nr_class),e(nr_class),.)
  }
  if(`have_probB'==1 & `e(nr_class)'>0) {
    capture noisily matrix probB = J(e(nr_class),e(nr_class),.)
  }
  

  
  * TODO: also label the rows according to model->label (libsvm's "labels" are just more integers, but it helps to be consistent anyway);
  *  I can easily extract ->label with the same code, but attaching it to the rownames of the other is tricky
  capture noisily {
    plugin call _svm `if' `in', "_model2stata" 2


    // Label the resulting matrices and vectors with the 'labels' array, if we have it
    if("`strLabels'"!="") {
      capture matrix rownames nSV = `strLabels'
      
      capture matrix rownames rho = `strLabels'
      capture matrix colnames rho = `strLabels'
      
      capture matrix rownames probA = `strLabels'
      capture matrix colnames probA = `strLabels'
      
      capture matrix rownames probB = `strLabels'
      capture matrix colnames probB = `strLabels'
    }
  }
  
  * Phase 3
  * Export the SVs 
  capture noisily {
    if("`sv'"!="") {
      quietly generate byte `sv' = .
      quietly replace `sv' `if' `in' = 0  //because the internal format is a list of indices, to translate to indicators we need to *start* with 0s and if we see them in the list, overwrite with 1s 
      if(`have_sv_indices'==1 & `e(l)'>0) {
        plugin call _svm `sv' `if' `in', "_model2stata" 3
      }
    }
  }
  
  * Phase 4
  * Export the rest of the values to e()
  * We *cannot* export matrices to e() from the C interface, hence we have to do this very explicit thing
  * NOTE: 'ereturn matrix' erases the old name (unless you specify ,copy), which is why we don't have to explicitly drop things
  *       'ereturn scalar' doesn't do this, because Stata loves being consistent. Just go read the docs for 'syntax' and see how easy it is. 
  * All of these are silenced because various things might kill any of them, and we want failures to be independent of each other
  
  //quietly capture ereturn matrix SVs = SVs
  capture matrix drop SVs
  
  quietly capture ereturn matrix nSV = nSV
  //quietly capture ereturn matrix labels = labels
  capture matrix drop labels
  
  quietly capture ereturn matrix sv_coef = sv_coef
  quietly capture ereturn matrix rho = rho
  //quietly capture ereturn matrix probA = probA //XXX disabled: these are probably not something you care to look at directly
  //quietly capture ereturn matrix probB = probB //              rather, use "predict, prob"; if a compelling reason to expose these comes up we can
  capture matrix drop probA
  capture matrix drop probB
  
end
