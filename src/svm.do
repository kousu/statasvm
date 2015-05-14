
* Stata is *very* single-threaded
* Stata has a global and a local namespace; the local namespace is actually just the global namespace with "_" prefixed to everything (so a local variable u is global variable _u, and gets autodeleted when it goes out of scope)
* Stata has a three global dictionaries called 'r', 'e' and 's' which are meant to be used for multiple-return.
  * writing syntax:
  *   `return 6` just sets a single key named '6'
  *   `return scalar u = 9` sets r(u) = 9
  *   `ereturn scalar h = 3` sets e(h) = 3
 *  These *are shared between* and the Stata docs warn clearly about this: "It  is,  therefore,  of  great  importance  that  you  access  results  stored  in
r() immediately  after  the command  that  sets  them."
  *  but to partially mitigate this, only 'programs' (i.e. subroutines) declared 'eclass' can edit e(), and only those declared 'rclass' can edit r().. I think.

program define svm, eclass

  version 0.0.1
  syntax [varlist] [if] [in], []
  
  capture program _svm, plugin
  
  if word count `varlist' < 2 {
    di as error "Need at least 2 variables: a regressor and a regressee".
    exit
  }
  
  plugin call _svm `varlist', "train"

  ereturn clear
  
end
