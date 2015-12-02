/* svmachines: the entry point to the support vector fitting algorithm */

program define svmachines
  version 13
  
  //plugin call does not handle factor variables.
  // xi can pre-expand factors into indicator columns and then evaluate some code.
  // However xi interacts badly with "plugin call"; just tweaking the code that calls into
  // the plugin to read "xi: plugin call _svm, train" fails. xi needs to run pure Stata.
  // Further, xi runs its passed code in the global scope and can't access inner routines,
  // which means the pure Stata must be in a *separate file* (_svm_train.ado).
  xi: _svm_train `0'        
end
