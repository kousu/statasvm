TODO
====

* [x] Agree upon a License
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


- [x] make .sthlp files
   - [ ] svm.sthlp is the primary one, covering svm_train and svm_predict in one (since users should never explicitly call svm_predict themselves)

- [ ] renames
  - [ ] svm_train to svm
  - [ ] svm_predict to svm_p (to match regress_p)
  
- [x] figure out a way to install the .dll with the package
   - [x] write a plugin to setenv() and then hack up the environment and hope that the loader pays attention to this on loading the real plugin
   - [ ] write a patch_dependencies.ado file which uses _setenv
   - [ ] write a plugin that simply calls dlopen() to test if a library is installed
         because if a DLL is missing all you get is "unable to load plugin" with no explanation of what went wrong.

- [ ] pull svm_load out to a separate plugin: _svmlight.plugin
   - [ ] import_svmlight
   - [ ] export_svmlight
   - [ ] make a separate project for this (tho after I see where the factor points are)

- [ ] Use the libsvm API
 >  struct svm_model stores the model obtained from the training procedure.
 >  It is not recommended to directly access entries in this structure.
 >  Programmers should use the interface functions to get the values.
 Oooops
    
- [x] expose svm_param as options to svm_train

- [ ] make the matrices in _model2stata all optional
      (with capture on the stata side and error catching and discarding on the C side)
      so that if they are too large to allocate you get a warning but not a crash
       (afterall, it's not like the C side of things is artificially memory limited)
      then you can still run the regression and get predictions, even

- [ ] add e(estat_cmd)

- [ ] on error, *reset state*
   - 'snapshot' can be used to rollback the dataset, but the things in ereturn list cannot. hmm. conundrum.
  --> well, actually, that's 

- [ ] investigate subcommands; it seems "help a b" will try to look up "a_b.sthlp", but I don't think "a b" will call a_b.ado. hmm.q

- [ ] handle fvs (i.varname, etc)
  - plugin call can't handle fvs, but I can use xi to fudge them
    however there is a strange bug: xi doesn't work as advertised; is it just with plugin call??

- [ ] BUG: svm_predict_probability() gives opposite answers to svm_predict()
  - [ ] test on a multiclass dataset
  - [ ] test if svm-train has the same bug and if so report the damn thing. fucking libsvm.
        (easiest to do this after svmlight_save() is available)

- [ ] BUG: tests/export on the auto data records strange y values
      rather than 0s and 1s, it records 0.4375 and -1.
      despite this, predict works as expected. HMMM. another bug in libsvm? i.e. in svm_save()?
- [ ] BUG: svm predicts all to the same class in


- [ ] indent the ado code
- [ ] switch to // over * comments

- [ ] hide the makefiles in mk/

- [ ] label the output matrix rows/columns according to the depvar's value labels, if any
  -> be careful to get the order right
  - [ ] don't expose the labels matrix; 
- [ ] factor the code that generates svm_node[]s
  -> stata2svm_node(int i, int start, int end), returns NULL if it finds missing data or otherwise fucks up
     -> or maybe we want to be able to signal errors

- [x] BUG: predict assumes all the varrrriables are the predictors, which is like, demonstrably not true usually. i am surprised my predict test is making sense, actually.... store the list of predictor variables from svm_train (how the fuck does regress (aka OLS) do this?? or GLM?? does it put e(cmdline) into `0' and run 'syntax' again??)


- [WONTFIX] change all to "program define svm subcommand" because *that's* the hidden canonical way to do subcommands
    (the thing is, Stata is full of nubs so the ones who bother to program figure out *a way* to get it working, not *the way* and shit remainds undocumented)
   -- this doesn't work. what was a i smoking?

- [x] silence tests/helpers/settings.do
- [x] BUG: svm turn price mpg; predict P --> crash on trying to set an empty label, or something
 use joe_dutch_merged
 svm category q_ar* in 1/100
 the 1/100 range is to restrict the size of the , but if you 'tab category in 1/100' there's definitely a good mix of classes that should come up, so wtf???
- [x] switch to webuse auto

- [x] in predict(), any missing data should cause the row to be *skipped*, not crash
- [x] Windows testing bug: fucking trailing spaces
- [x] pick a license
- [x] indent the damn code
- [x] make SF_error have vargs

- [x] copy depvar style
  see help extended_fcn
   --> type variable
   --> data label
   --> label
, if it has any
  "label values `newvar' `oldvarlabel'"


* [ ] Test the svmlight parser against files with excessively long (>512) tokens. It should error out, but I fear instead it'll just keep parsing.

* [x] Compare svm_save_model results from svm-train and my code. They /should/ always be identical on the same data.


* [ ] add auto-valgrinding to the makefile (e.g. make VALGRIND=1 or make VALGRIND="--show-...." to trigger a lookup and addition of valgrind to the mix
* [ ] auto-scale/centering

* [ ] consider pros and cons of committing svm.h and libsvm.lib and libsvm.dll to the local repo, for the sake of wwwWandows, as in  http://blog.nuclex-games.com/2012/03/how-to-consume-dlls-in-visual-cxx/
  * pro: build is simpler: there's no need to download and build libsvm -- and so there's no intrinsic dependency on VS
  * con: cannot control architecture; or else there'd have to be duplicate .dlls
  
make:
* [ ] On Windows, it appears that forward-slashes aren't recognized as path separators in targets. They are in prerequisites, though.
   Set up a test case and submit a bug report.

boost.ado:
* [ ] backport putting subdirectories for packages
* [ ] "local k : word count `varlist'" better written "scalar k = wordcount("`varlist'")"
* [ ] backport .pkg's (new?) feature of 'g WIN64 boost64.dll boost.plugin' + 'h boost.plugin'
* [ ] backport auto-loading the plugin

libsvm:
* [ ] the python code is pretty hacky. A lot of it could be rolled into libsvm's core, and what's left can be replaced by things like argparse and multiprocessing
* [ ] since they say svm_check_param() should always be called before svm_train(), *why not just roll it in?*
  * fixing this is related the doing better polymorphism via a union type
* [ ] make svm_type_table[] and char *kernel_type_table[] non-private (now, you can't link /directly/ against variables, but you can provide accessor functions to map both ways)
* [ ] link the programs dynamically instead of statically; there's no point distributing a DLL if you're not going to use it
* [ ] submit pprint() functions as patches
* [x] patch the Makefile to be saner
  * use implicit rules as much as possible
* [ ] make print_func support printf arguments
* [ ] replace all `fprintf(stderr, )`s with error_func (and make it also support printf args)
  * -> and then linkup error_func to Stata
* [ ] canonicalize the freeing functions so that they all behave the same (the distinction between free_and_destroy() vs destroy() makes it difficult to use)
* [ ] add svm_problem_free()
* [ ] kill x_space from svm-train.c; it's not needed; just Malloc the space directly onto svm_problem->svm_node
* [ ] rename 'svm_node' to something less generic.
* [ ] Models read via svm_load_model leak x_space: it's never ever freed! (which is again a side effect of x_space sucking)
* [ ] svm_parameter is an inheritence tree, awkwardly implemeneted in C by simply adding more fields than they will ever use at once. They *should* be using a union.
* [ ] do away with free_sv, in favour of *always* copying the SVs; then you can (and should) free the svm_problem separately from the svm (give me an instance where you actually have so many support vectors that this is a problem)

