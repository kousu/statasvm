  //plugin call refuses to handle factor variables
  // so I need to use xi to pre-expand factors into indicator columns
  // however xi interacts badly with plugin call: it runs in the global scope and can't access inner routines like svm_train._svm.

program define svm_train, eclass
  version 13

  //syntax varlist (numeric fv) [if] [in],
  xi: _svm_train `0'          
end
