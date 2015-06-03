Crash course in Stata programming
=================================

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

*

* the "program" command creates a new
*  it is an error to redefine a program without "program drop"ing it first
*   however when used to load extensions with "program <name>, plugin" it (apparently) is smart enough to create the name binding in whatever namespace it is being run in *without actually reloading the plugin*
*   this means that you can just put "program <name>, plugin" at the top of each .ado file that needs it, each will load it into their namespace, and behind the scenes the single instance of the plugin can share data between the ado files
  this is a lot like how python works, actually: "program <name>, plugin" is like "import" rather than "define" (but program define is something else)