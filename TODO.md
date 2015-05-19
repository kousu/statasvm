TODO
====

* [ ] Agree upon a License
* [ ] Set up a cross-platform makefile
  * [?] Linux (32 bit and 64 bit should be identical; it's just a matter of compiling 
    * [x] ArchLinux
    * [?] Debian
    * [?] Fedora
  * [ ] Windows
    * [ ] XP (32 bit!)
    * [ ] 7  (64 bit!)
    * [ ] 8  (64 bit!)
  * [?] 64 bit OS X
    * [x] Mountain Lion (10.8)
    * [?] Mavericks (10.9)
    * [?] Yosemite (10.10)
  * [-] 32 bit OS X (does this even exist anymore?)
* [ ] Set up a cross-compiler (this is much harder!)
* [ ] Support installing without root (..i.e. distribute libsvm and install it next to the things)

* [ ] write svmload.ado which handles reading svmlight format files
   * -> "a plugin cannot create
* [ ] Add stata/ to the include path instead of "stata/stplugin.h"? maybe?
* [ ] Define a DEFINES macro in the makefile which works like LIBS
* [ ] Separate the generic cross-platform make parts from the svm-specific parts.

* [ ] Verify that Stata turns missing values into NaNs before libsvm eats them

* [ ] Investigate loading direct to Stata matrices to speed things up
   Stata has some severe memory limitations on its matrices: no more than 800x800 in Stata-IC, which makes it useless for machine learning

* [ ] Figure out the best way to autoload the plugin
 * one: make everything a subcommand in a single svm.ado file, which only gets loaded once
 * two: 
 * three: use 'program list' to detect if it's 
 * four: ...are loaded plugins private variables? it sort of seems like they might be!!
* [ ] make 'svm' a suite of subcommands; put everything into a single file, even, so that users cannot call them directly.

* [ ] Stata doesn't provide any way to work with lists, except as variables in its global data table.
  libsvm returns a list marking which observations are the suppart vectors; probaaaabbly nathe most natural way to return this to the user is to add an extra boolean column to mark them. But I will have to talk to Schonlau
* [ ] provide svm_classify and svm_regress as s convenience shortcuts to something like "svm
 
* [ ] The closest I can get to local variables is to use in Stata tempname, and pass that along in argv to the plugin. Right now I hard-code everything with Globally Unique(TM) prefixes

* [ ] duke.svmlight is actually a terrible dataset, or I'm misusing it: it thinks *everything* is a support vector which defeats the purpose
* [ ] rather than exposing svm-scale, autoscaling should be an option of svm_train

* [ ] add `make lint`


* [ ] Test the svmlight parser against files with excessively long (>512) tokens. It should error out, but I fear instead it'll just keep parsing.

* [ ] Compare svm_save_model results from svm-train and my code. They /should/ always be identical on the same data.

make:
* [ ] On Windows, it appears that forward-slashes aren't recognized as path separators in targets. They are in prerequisites, though.
   Set up a test case and submit a bug report.

boost.ado:
* [ ] "local k : word count `varlist'" better written "scalar k = wordcount("`varlist'")"
* [ ] backport my multi-platform plugin packager/loader, so that it works everywhere

libsvm:
* [ ] make svm_type_table[] and char *kernel_type_table[] non-private (now, you can't link /directly/ against variables, but you can provide accessor functions to map both ways)
* [ ] link the programs dynamically instead of statically; there's no point distributing a DLL if you're not going to use it
* [ ] submit pprint() functions as patches
* [x] patch the Makefile to be saner
* [ ] make print_func support printf arguments
* [ ] replace all `fprintf(stderr, )`s with error_func (and make it also support printf args)
  * -> and then linkup error_func to Stata
* [ ] canonicalize the freeing functions so that they all behave the same (the distinction between free_and_destroy() vs destroy() makes it difficult to use)
* [ ] add svm_problem_free()
* [ ] kill x_space from svm-train.c; it's not needed; just Malloc the space directly onto svm_problem->xvm_node
* [ ] rename 'svm_node' to something less generic.
* [ ] Models read via svm_load_model leak x_space: it's never ever freed! (which is again a side effect of x_space sucking)
* [ ] svm_parameter is an inheritence tree, awkwardly implemeneted in C by simply adding more fields than they will ever use at once. They *should* be using a union.
