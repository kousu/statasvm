/* model2stata: a subroutine to convert the global struct svm_model that lives in the DLL to a mixture of e() entries, variables, and matrices.
 *
 * Besides being usefully modular, this *must* be its own subroutine because it needs to be marked eclass.
 * This is because, due to limitations in the Stata C API, there has to be an awkward dance to get the information out:
 *   _svmachines.plugin writes to the (global!) scalar dictionary and then this subroutine code copies those entries to e().
 *
 * as with svm_load, the extension function is called multiple times with sub-sub-commands, because it doesn't have permission to perform all the operations needed

 * if passed, SV specifies a column to create and then record svm_model->sv_indecies into
 */

/* load the C extension */
svm_ensurelib           // check for libsvm
program _svmachines, plugin    // load the wrapper for libsvm

program define _svm_model2stata, eclass
  version 13
  
  syntax [if] [in], [SV(string)] [Verbose]
  
  * as with loading, this has to call in and out of the plugin because chicken/egg:
  *   the plugin doesn't have permission to allocate Stata memory (in this case matrices),
  *   but we don't know how much to allocate before interrogating the svm_model
  
  
  * Phase 1
  
  * the total number of observations
  * this gets set by _svmachines.c::train(); it doesn't exist for a model loaded via import().
  * nevertheless it is in this file instead of svm_train.ado, because it is most similar here
  * but we cap { } around it so the other case is tolerable
  capture {
    ereturn scalar N = _model2stata_N
    scalar drop _model2stata_N
  }
  
  
  /*an undefined macro will inconsistently cause an eval error because `have_rho'==1 will eval to ==1 will eval to "unknown variable"*/
  /*so just define them ahead of time to be safe*/
  local have_sv_indices = 0
  local have_sv_coef = 0
  local have_rho = 0
  local labels = ""
  
  
  plugin call _svmachines `if' `in', `verbose' "_model2stata" 1
  
  * the total number of (detected?) classes
  ereturn scalar N_class = _model2stata_nr_class
  scalar drop _model2stata_nr_class
  
  * the number of support vectors
  ereturn scalar N_SV = _model2stata_l
  scalar drop _model2stata_l
  
  
  
  * Phase 2
  * Allocate Stata matrices and copy the libsvm matrices and vectors
  if(`have_sv_coef'==1 & `e(N_class)'>1 & `e(N_SV)'>0) {
    capture noisily {
      matrix sv_coef = J(e(N_class)-1,e(N_SV),.)
      
      // there doesn't seem to be an easy way to generate a list of strings with a prefix in Stata
      // so: the inefficient way
      local cols = ""
      forval j = 1/`e(N_SV)' {
        local cols = "`cols' SV`j'"
      }
      matrix colnames sv_coef = `cols'
      
      // TODO: rows
      //  there is one row per class *less one*. the rows probably represent decision boundaries, then. I'm not sure what this should be labelled.
      // matrix rownames sv_coef = class1..class`e(N_SV)'
    }
  }
  
  if(`have_rho'==1 & `e(N_class)'>0) {
    capture noisily matrix rho = J(e(N_class),e(N_class),.)
  }
  

  
  * TODO: also label the rows according to model->label (libsvm's "labels" are just more integers, but it helps to be consistent anyway);
  *  I can easily extract ->label with the same code, but attaching it to the rownames of the other is tricky
  capture noisily {
    plugin call _svmachines `if' `in', `verbose' "_model2stata" 2
	
    // Label the resulting matrices and vectors with the 'labels' array, if we have it
    if("`labels'"!="") {
      ereturn local levels = strtrim("`labels'")
      
      capture matrix rownames rho = `labels'
      capture matrix colnames rho = `labels'
    }
  }
  
  * Phase 3
  * Export the SVs 
  if("`sv'"!="") {
    if(`have_sv_indices'==0) {
      di as err "Warning: SV statuses missing. Perhaps your underlying version of libsvm is too old to support sv()."
    }
    else {
      capture noisily {
        // he internal libsvm format is a list of indices
        // we want indicators, which are convenient for Stata
        // so we  *start* with all 0s (rather than missings) and overwrite with 1s as we discover SVs
        quietly generate `sv' `if' `in' = 0
        plugin call _svmachines `sv' `if' `in', `verbose' "_model2stata" 3
      }
    }
  }
  
  * Phase 4
  * Export the rest of the values to e()
  * We *cannot* export matrices to e() from the C interface, hence we have to do this very explicit thing
  * NOTE: 'ereturn matrix' erases the old name (unless you specify ,copy), which is why we don't have to explicitly drop things
  *       'ereturn scalar' doesn't do this, because Stata loves being consistent. Just go read the docs for 'syntax' and see how easy it is. 
  * All of these are silenced because various things might kill any of them, and we want failures to be independent of each other
    
  quietly capture ereturn matrix sv_coef = sv_coef
  quietly capture ereturn matrix rho = rho
end
