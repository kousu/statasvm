
* Stata is *very* single-threaded
* Stata has a global and a local namespace; the local namespace is actually just the global namespace with "_" prefixed to everything (so a local variable u is global variable _u, and gets autodeleted when it goes out of scope)
* Stata has a three global dictionaries called 'r', 'e' and 's' which are meant to be used for multiple-return.
  * writing syntax:
  *   `return 6` just sets a single key named '6'
  *   `return scalar u = 9` sets r(u) = 9
  *   `ereturn scalar h = 3` sets e(h) = 3
 *  These *are shared between* and the Stata docs warn clearly about this: "It  is,  therefore,  of  great  importance  that  you  access  results  stored  in r() immediately  after  the command  that  sets  them."
  *  but to partially mitigate this, only 'programs' (i.e. subroutines) declared 'eclass' can edit e(), and only those declared 'rclass' can edit r().. I think.
* Stata has scalars, "variables", and matrices. "variables" refer to vector variables in the one current global data table
*  scalars and matrices need to be declared with e.g. "scalar h = 1".
*  for some reason, Stata often uses macros instead of scalar variables, e.g. this is how "foreach" and "file read" behave. Perhaps Stata at one point had no scalars and therefore people fell back on macros, and now it's stuck and it's horrible.

program define svm
  version 13
  svm_train `0'
end

