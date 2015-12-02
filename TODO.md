TODO
====

quicklist:
- memory leaks
- oneclass example
- rename ensurelib, clockseed and clone to svm_{ensurelib,clockseed,clone} to avoid dist conflicts
- take cv.ado and mlogit_predict.ado out of mainline.

Copyright
---------

* [x] Agree upon a License

Build
-----

* [x] stata.trk (click-to-run) bug
* [ ] Handle looking up libsvm.dll using .LIBPATTERNS + using -lsvm as a dependency, instead of special-casing it (FIXED_LIBS)
   - see 4.5.6 Directory Search for Link Libraries in the make manual

* [ ] check if there's a way to use pattern rules for .c -> .plugin

* [ ] Set up a cross-platform makefile
  * [?] Linux (32 bit and 64 bit should be identical; it's just a matter of compiling 
  * [x] Windows
    * [x] 32 bit
    * [x] 64 bit
  * [?] 64 bit OS X
    * [x] Mountain Lion (10.8)
    * [?] Mavericks (10.9)
    * [?] Yosemite (10.10)
  * [-] 32 bit OS X (does this even exist anymore?)
* [ ] Set up a cross-compiler (this is much harder!)

* [-] Add stata/ to the include path instead of "stata/stplugin.h"? maybe?
* [ ] Define a DEFINES macro in the makefile which works cross-platform like LIBS
* [ ] Factor the generic cross-platform make parts from the svm-specific parts.


* [ ] add `make lint`
* [ ] add 'make memcheck'
* [ ] add `make indent`
* [ ] hide the makefiles in mk/

* [x] consider pros and cons of committing svm.h and libsvm.lib and libsvm.dll to the local repo, for the sake of wwwWandows, as in  http://blog.nuclex-games.com/2012/03/how-to-consume-dlls-in-visual-cxx/
  * pro: build is simpler: there's no need to download and build libsvm -- and so there's no intrinsic dependency on VS
  * con: cannot control architecture; or else there'd have to be duplicate .dlls
   for now, they're committed; I don't know if I'll keep it like this.


Dist
---


* [ ] from StataJournal: rename svm->svmachine (or svectorm), because three letter commands are reserved
* [ ] Figure out a way to automatically cull things in .gitignore from being put into dist/;
   Maybe the best way is to just enforce that "git clean -x" is clean before? But that will require some reworking..
   [x] For now, add a warning to the user to check it every time.
* [ ] Check for memory leaks
* [ ] Implement package checksumming
  -> see help usersite
  -> this is probably reasonably quick to automate by pumping Stata from Make
[x] 'make dist-clean' and *don't* erase dist/ during clean
  that way you should be able to:
  - net-mount the repo remotely from several systems
  - 'make clean; make dist' on all of them
  - 'make deploy' on any (non Windows) one
 this will be a lot more reliable than my ritual of manually copying bin/ around

* [x] Support installing without root (..i.e. distribute libsvm and install it next to the things)
* [x] Figure out the best way to autoload the plugin
 * one: make everything a subcommand in a single svm.ado file, which only gets loaded once
 * two: 
 * three: use 'program list' to detect if it's 
 * four: ...are loaded plugins private variables? it sort of seems like they might be!!
    -> loaded plugins get loaded at most once (at a time; you can drop and reload them) but attached to the private internal namespace of the .ado file
       you can see this with "program dir" after you've run several subcommands
       other processes which have imported the same plugin will be using the same datastructures in it---Stata doesn't dlopen() multiple times ((it probably couldn't; dlopen() says "If  the same library is loaded again with dlopen(), the same library handle is returned.")
  
- [x] figure out a way to install the .dll with the package
   - [x] write a plugin to setenv() and then hack up the environment and hope that the loader pays attention to this on loading the real plugin
   - [x] write a patch_dependencies.ado file which uses _setenv
     -> ensurelib.ado
   - [x] write a plugin that simply calls dlopen() to test if a library is installed
         because if a DLL is missing all you get is "unable to load plugin" with no explanation of what went wrong.
     ->[x] _dlopenable

       but they can't call each others handle to it ("svm_train._svm" is invalid syntax, even though that's the name listed in 'program dir')


* [ ] make ensurelib a separate project/pkg
* [ ] make ensurepkg a separate package
  - note: Stata allows multiple packages to have the same files, but only if they are *exactly* identical
* [ ] make clone a separate package
* [ ] make example a separate package
* [ ] make _{get,set}env.plugin a separate project/pkg

* [x] pull svm_load out to a separate plugin: _svmlight.plugin
  * [x] import_svmlight
  * [x] export_svmlight


Documentation
-------------

* [ ] oneclass_example.do:
  * there should actually be four plots on each of the outputs, to demonstrate how (training set, outlier) correlate.
    we can probably arrange that both training plots have the same colour, and both outlier plots have the same shape
* [ ] svm, predict in svm.sthlp should be under svm_postestimation.sthlp
* [ ] svmlight should have its own .sthlp file
* [x] I should probably undocument svm_import because it causes problems
  - there's no easy way to make it work with predict because the libsvm export format doesn't remember which variables go where.
* [x] p(0.1) -> eps(0.1)
* [x]  squash all the TODOs
* [ ] figure out what is up with the definition of nu
* [ ] check up on my explanation of what SVR does
* [ ] describe 

[x] comment out norm, until we decide what we are going to do with it
[ ] better parameter descriptions (mine sklearn for this)

[ ] make examples
  [x] BUG: example.ado crashes *if the dataset has been edited*
  [x] "optimal" -> "good" to avoid pickiness
  [x] probability -> class_probabilities
  [x] don't use "svm *" because that's poor form
  [x] roll the factor example into a passing comment in one of the others
  [x] don't stuff spare lines between each whitespace---instead put it on switch between modes
  [ ???? ] first example doesn't work: something is wrong with 'verbose'
  [x ] the examples should all show variants of exactly one process:
    split, train, predict, error rate
    my idea of evolving examples to demonstrate should be left for the paper
  ---> examples should all involve
  ---> examples should all involve normalizing the data
      egen a = std(b)
      this does mean/variance standardization
      problem: it does *not* record the parameters used to standardize the things
  
  = [x] duplicate all these as both ancillary .do files and do 'click to run' in the docs
  * [x] binary classification
      "auto" dataset
     --> show 

  * [x] multiclass classification with 'prob'
    also demonstrate the sv() option, including crosstabbing it with the 
      so I want a dataset with a *lot* of rows:

      the "highschool" dataset is perfect
      demonstrate tuning c() changes the results
  * [x] svr
    and demonstrate tuning eps() changes the results
  * [ ] one class
    the same lots-of-rows dataset
  * [x] tuning
  * [x] sv()
  * [x] , prob
  * [x] factor variables
        also show off "predict, replace" here
  * [x] demonstrate that predict and predict, prob are different
  * [ ] custom kernel (port from sklearn?)


[x] make click-to-run examples in the docs
  --> twoway_area.sthlp shows how to do this

[WONTFIX] duplicate the See Alsos to an actual section (because smcl isn't smart enough to figure this out for us)
  -- hm. none of the built in commands do this

- [x] say "1/[# indepvars]"
- [x] add a variant command format for type(ONE_CLASS) -- it shouldn't take a Y
- [x] lowercase all the parameter values, which is Stata-style
  - see glm.sthlp for examples
- [x] put the parameter values in the option font
  - see glm.sthlp for examples
- [x] add () after options which take them, and inside put a link to their fuller descriptions
  - see glm.sthlp for examples

- [x] param sectioning:
    - model: type, kernel, degree
    - tuning: gamma, coef0

- [x] make .sthlp files
   - [x] svm.sthlp is the primary one, covering svm_train and svm_predict in one (since users should never explicitly call svm_predict themselves)
   - [ ] svmlight.sthlp (how do I make 'help import svmlight' bring this up?)


* [ ] Give import_svmlight a pseudo-varlist of columns to import (
  * "numlist" should allow this "import_svmlight 1/10 17/28 99 23 23 25/36"
    but you have to, of course, do it roundabout: run numlist on the *string* of the *entire* numlist, then look in r(numlist)
  * [ ] remove the 'clip' option
     but document its replacement: import_svmlight 1/`=c(max_k_theory)' using fname.svmlight

- [ ] clone.sthlp
- [ ] _env.sthlp
- [ ] ensurelib.sthlp
- [ ] ensureado.sthlp

Features
--------

* [x] export dec_values from svm_predict_values()
  * tricky because dec_values is a lower-triangular matrix (as a list) and labelling is tricky
* [/] svm_predict needs to take varlist optionally, because svm_import has no way to know what variables it goes with;
  - the libsvm people, following on svmlight, simply assume that the variables are given in order in the data matrix passed to it, and that all train/test split files are in the identical (and totally unlabelled) order. Since Stata is actually meant for humans to use in daily work, it is all about labelled variables.
  - WONTFIX: instead I culled svm_{export,import}; there is no sensible way to integrate saved models with Stata's workflow, and most Stata people save their workflow as .do files to be run from scratch anyhow.
* [/] svm_import does not set all the same macros as svm_train
* [x] Stata in -e mode writes to its logfile as it runs, so there should be a way to wrap it such that it behaves like other scripting languages: printing/taking output as it gets it but also quitting when the program ends
  Actually, 'exit' has a 'STATA' option which does a proper exit() call
  the next step is to output _rc somewhere and wrap a script around the whole thing which exits with _rc as a proper error code
 
* [ ] set e(sample)
  see 'help predict' for a confusing introduction to what this is supposed to be

* [ ] scaling (??)

* [ ] cross-validation
  * I could wrap svm_cross_validation(), but all that does is stuff we could do in Stata
    what it does have built in, which I would have to figure out how to replicate in Stata,
    is stratification: for classification problems it automatically makes sure to keep class proportions about even
    
* [ ] grid-search
 - tricky to do in general, because you need to specify a function and a set of parameters and a region of those parameters to check; just look at how complicated basic use of sklearn's is: http://scikit-learn.org/stable/modules/grid_search.html -- and that's in a language which is fully enthralled with metaprogramming.
 - there could be an svm_grid function just to be practical...maybe.

* [ ] predict, replace
   stanard predict doesn't have this, but writing cross validation will be a lot easier if we can just predict all into different slices of a single variable


* [x] 'verbose' option which sets/unsets svm_print_function as required.
  * [ ] implement reading c() to tweak off the dupe output: http://www.statalist.org/forums/forum/general-stata-discussion/general/1295308-bundling-dlls-in-pkgs?p=1296985#post1296985
     -> output should be duped when in c(mode)==batch, because it's a thing I use for debugging the batch runs lest they crash, but otherwise should only go to Stata's normal output
  * [ ] svm_parameter_pprint() should always be run, but it should be run *through the libsvm print function* so that the 'verbose' setting controls it,
        I can't actually access that function directly, so I'll need to wrap


* [x] handle fvs (i.varname, etc)
  - plugin call can't handle fvs, but I can use xi: to fudge them
    however there is a strange bug: xi doesn't work as advertised; is it just with 
    bug: xi runs in the global scope and so can't access my inner routines.
    fix: break up svm_train so that I have a global to call xi upon


* [ ] sklearn's fork of libsvm adds
  * [ ] svm_param->max_iter
  * [ ] svm_param->random_state (i.e. RNG seed)
 either get this in upstream or just switch to sklearn's fork

* [ON HOLD] 'normalize' to automatically normalize the data
   -> implement this with the 'center' package
      -> use ensureado with it, *but only if the user tries to use normalize*, so that if it's not installed or if the package somehow leaves ssc it's not a problem
    [ ] Schonlau: ask Ben Jann about running center on a column with variance 0
      - the intuitive result is to leave the column unchanged,
         but instead center gves missing values. Is this expected? Is it a bug? Is this a case Ben's ever thought about?
    - generate a short testcase demonstrating the bug
   -> or, implement it ourselves (but Nick is against this)

[x] ensureado
  - check for and autoinstall dependencies as needed


* [x] write svmload.ado which handles reading svmlight format files
   * -> "a plugin cannot create
* [ ] make 'svm' a suite of subcommands; put everything into a single file, even, so that users cannot call them directly.
   this might not be possible because of scoping rules... Stata's native, core, regress command has prediction in regres_p.ado, a separate file.
  * [x] investigate subcommands; it seems "help a b" will try to look up "a_b.sthlp", but I don't think "a b" will call a_b.ado. hmm.q

* [WONTFIX] weighting
  * stata's "syntax" provides this as an option; so does libsvm's svm_parameter; I should just have to plug them together
  * sklearn has an 'auto' mode where it weights classes by their proportion in the dataset. this is a good idea.

* [x] use rownames/colnames to label the return matrices with which classes is which 
  * nSV
  * probA / probB

* [x] instead of returning the SVs matrix, add a boolean column marking if something is a support vector
  (to ensure uniqueness, it should be passed as an option; if not passed, don't mark it)

* [ ] convenience shortcuts:
   svclassify / svc
   svregress / svr
   svoneclass
 as convenience shortcuts to something like "svm `0', type(C_SVC)"  "svm `0', type(EPSILON_SVR)"
   -> and if you specify 'nu' as an option, trigger nu-SVM instead (NU_SVC, NU_SVR)
   -> this is a nicetohave/prematureoptimization, so leave it for version 2

* [x] make generate_clone into a more sensible API: "clone new = old, [nocopy]", and get 'syntax' to validate both the new and old varnames for us


- [x] make the matrices in _model2stata all optional
      (with capture on the stata side and error catching and discarding on the C side)
      so that if they are too large to allocate you get a warning but not a crash
       (afterall, it's not like the C side of things is artificially memory limited)
      then you can still run the regression and get predictions, even

- [x] expose svm_param as options to svm_train
- [ ] support e(estat_cmd)
  * I don't really know what this is for; something to do with getting even more estimates after estimating your estimates


Maintenance
-----------

Code cleanups:

* [x] factor stata2libsvm and predict() back into one code base
  -> struct svm_node* stata_to_svm_node(int x_l, int x_u)
     then turn the current stata2libsvm into stata_to_svm_prob(int y, int x_l, int x_u)
 

* [x] Give one-liner introductions on each code file.

* [x] Roll ensurelib_aberrances into ensurelib
   -> and for brevity, roll the plugins it depends on (dlopenable, getenv, setenv) into a single _ensurelib.plugin
   and make this into a separate project
* [ ] put ado_from as a subroutine inline in example.ado
   -> possibly also ensurepkg?
   and make this into a separate project
* [ ] Move testing subroutines elsewhere
   -[ ] cv.ado
   -[ ] mlogit_predict.ado

* [ ] do `search subroutine` for each *.ado to find out whose toes I'm stepping on

* [ ] Label prediction columns with "Prediction"
* [ ] 
* [ ] make use of Stata's "confirm" command to give better error messages


- [ ] renames
  - [ ] svm_train to svm
  - [ ] svm_predict to svm_p (to match regress_p)
  - {epsilon, p} -> {tol, epsilon}; this is what sklearn did: http://scikit-learn.org/stable/modules/generated/sklearn.svm.SVR.html#sklearn.svm.SVR
* [ ] Unlike mata, I can't write to r() from a Stata plugin, as far as I can tell
      The closest I can get to encapsulated, local, variables is to use in Stata tempname, and pass that along in argv to the plugin
      (almost like passing a pointer for an out argument in C). But that's tedious and I haven't done it yet.
      (Instead I hard-code everything with Globally Unique(TM) prefixes, which is about equivalent to using r() anyway)

* [ ] Use the libsvm API (svm_get_*()) instead of touching the internals
  --> though, currently, the API literally just copies internals to externals (including requiring you to pre-allocate space to store results that are of type list)
      so this could actually be extremely expensive for little gain on large datasets....
 >  struct svm_model stores the model obtained from the training procedure.
 >  It is not recommended to directly access entries in this structure.
 >  Programmers should use the interface functions to get the values.
 Oooops

- [ ] indent the ado code
- [ ] switch to // over * comments

- [ ] factor the code that generates svm_node[]s
  -> stata2svm_node(int i, int start, int end), returns NULL if it finds missing data or otherwise fucks up
     -> or maybe we want to be able to signal errors

- [ ] silence now OBunnecessary complaints about unable-to-write-to this-or-that

Bugs
----

* [ ] memory leak: the svm_model hangs around between calls, and there is nowhere good to free it because Stata doesn't give a shutdown hook.
  - this is only a smallll memory leak, and it gets cleaned up when the program exits
  - the only option that might be feasible is to use the (platform specific!!) DLL unload hooks.  Or also, when a C++ DLL is unloaded (this might be cross-platform!) all the destructors of its globals get run.
* [ ] cv should be able to handle multiple outcomes
  - mlogit_p under certain options
  - svm_predict, prob
  - others??
  I don't know if it's better to diff the set of columns
   or to assume that target columns will be named the same way
   mlogit_p does (and make svm_predict match)
* [x] cv is not respecting 'if'/'in':
  --> it was putting those not marked for any fold---those with missing values---into the every-other-fold block because I used != without testing enough.
```
. use icpsr_survey
. cv Ys_cv svm `model' if !missing(HSMINORITY) & !missing(HSMAJORITY) & !missing(INFORMED_VOTING) & !missing(HSDIVERSE), c(1)  gamma(1)
[fold 1/5: training on 3929 observations]
svm cannot handle missing data
svm failed
--Break--
r(1);


snapshot 1 created at 18 Jun 2015 18:32

. cv Ys_cv svm `model' if !missing(HSMINORITY) & !missing(HSMAJORITY) & !missing(INFORMED_VOTING) & !missing(HSDIVERSE), c(1)  gamma(1)
[fold 1/5: training on 3929 observations]
svm cannot handle missing data
svm failed
--Break--
r(1);

. drop if !missing(HSMINORITY) & !missing(HSMAJORITY) & !missing(INFORMED_VOTING) & !missing(HSDIVERSE),
options not allowed
r(101);

. drop if !( !missing(HSMINORITY) & !missing(HSMAJORITY) & !missing(INFORMED_VOTING) & !missing(HSDIVERSE))
(1,715 observations deleted)

. cv Ys_cv svm `model' if !missing(HSMINORITY) & !missing(HSMAJORITY) & !missing(INFORMED_VOTING) & !missing(HSDIVERSE), c(1)  gamma(1)
[fold 1/5: training on 2214 observations]
error writing to sv_coef
[fold 1/5: predicting on 554 observations]
[fold 2/5: training on 2214 observations]
error writing to sv_coef
[fold 2/5: predicting on 554 observations]
[fold 3/5: training on 2215 observations]
error writing to sv_coef
[fold 3/5: predicting on 553 observations]
[fold 4/5: training on 2214 observations]
error writing to sv_coef
[fold 4/5: predicting on 554 observations]
[fold 5/5: training on 2215 observations]
error writing to sv_coef
[fold 5/5: predicting on 553 observations]

. restore snapshot 1
```


* [x] Click-to-run is broken if done in a second session after installing
* [ ] is there any way to sync the Stata and srand seeds?
  - they use different RNGs, but if they are at least seeded together then results should be consistent
   - but setting srand() on every call is poor form (not actually random!)
         setting it only at DLL init will miss if the user runs 'set seed' *after* loading the plugin
  - different OSes also use different RNGs (*especially* with rand(), which is deprecated twenty times over), so we'll never get universal reproducibility unless we edit libsvm :(

* [ ] memory leaks:
  - run gridsearch.do and observe the amount of RAM go up and up and up
  1) a small leak (inside of libsvm itself?? or is it something I'm doing that's triggering something they're doing?):
==19705== 8 bytes in 1 blocks are still reachable in loss record 3 of 79
==19705==    at 0x4C29F90: malloc (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)
==19705==    by 0xB4F776F: svm_train (in /usr/lib/libsvm.so.2)
==19705==    by 0xB0D87E6: train (in /home/kousu/src/statasvm/src/_svm.plugin)
==19705==    by 0xB0D9026: sttrampoline (in /home/kousu/src/statasvm/src/_svm.plugin)
==19705==    by 0xB0D8E85: stata_call (in /home/kousu/src/statasvm/src/_svm.plugin)
==19705==    by 0x95D550: ??? (in /usr/local/stata/stata)
==19705==    by 0x95D80B: ??? (in /usr/local/stata/stata)
==19705==    by 0x8C15CE: ??? (in /usr/local/stata/stata)
==19705==    by 0x52954A: ??? (in /usr/local/stata/stata)
==19705==    by 0x52A70B: ??? (in /usr/local/stata/stata)
==19705==    by 0x5499AC: ??? (in /usr/local/stata/stata)
==19705==    by 0x529EB8: ??? (in /usr/local/stata/stata)
==19705== 

==19705== 184 bytes in 1 blocks are still reachable in loss record 20 of 79
==19705==    at 0x4C29F90: malloc (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)
==19705==    by 0xB4F5FE8: svm_train (in /usr/lib/libsvm.so.2)
==19705==    by 0xB0D87E6: train (in /home/kousu/src/statasvm/src/_svm.plugin)
==19705==    by 0xB0D9026: sttrampoline (in /home/kousu/src/statasvm/src/_svm.plugin)
==19705==    by 0xB0D8E85: stata_call (in /home/kousu/src/statasvm/src/_svm.plugin)
==19705==    by 0x95D550: ??? (in /usr/local/stata/stata)
==19705==    by 0x95D80B: ??? (in /usr/local/stata/stata)
==19705==    by 0x8C15CE: ??? (in /usr/local/stata/stata)
==19705==    by 0x52954A: ??? (in /usr/local/stata/stata)
==19705==    by 0x52A70B: ??? (in /usr/local/stata/stata)
==19705==    by 0x5499AC: ??? (in /usr/local/stata/stata)
==19705==    by 0x529EB8: ??? (in /usr/local/stata/stata)


  2) stata2libsvm
==19705== 7,696 bytes in 14 blocks are indirectly lost in loss record 65 of 79
==19705==    at 0x4C2C29E: realloc (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)
==19705==    by 0xB0D79DE: stata2libsvm (in /home/kousu/src/statasvm/src/_svm.plugin)
==19705==    by 0xB0D8704: train (in /home/kousu/src/statasvm/src/_svm.plugin)
==19705==    by 0xB0D9026: sttrampoline (in /home/kousu/src/statasvm/src/_svm.plugin)
==19705==    by 0xB0D8E85: stata_call (in /home/kousu/src/statasvm/src/_svm.plugin)
==19705==    by 0x95D550: ??? (in /usr/local/stata/stata)
==19705==    by 0x95D80B: ??? (in /usr/local/stata/stata)
==19705==    by 0x8C15CE: ??? (in /usr/local/stata/stata)
==19705==    by 0x52954A: ??? (in /usr/local/stata/stata)
==19705==    by 0x52A70B: ??? (in /usr/local/stata/stata)
==19705==    by 0x5499AC: ??? (in /usr/local/stata/stata)
==19705==    by 0x529EB8: ??? (in /usr/local/stata/stata)

[...]

  3) inside of Stata  (you can tell it's Stata because all the syms are stripped)
==19705== 1,057,632 bytes in 1 blocks are still reachable in loss record 78 of 79
==19705==    at 0x4C29F90: malloc (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)
==19705==    by 0x906404: ??? (in /usr/local/stata/stata)
==19705==    by 0x8FE245: ??? (in /usr/local/stata/stata)
==19705==    by 0x5F76D4: ??? (in /usr/local/stata/stata)
==19705==    by 0x8FE37D: ??? (in /usr/local/stata/stata)
==19705==    by 0x8FE835: ??? (in /usr/local/stata/stata)
==19705==    by 0x8FE898: ??? (in /usr/local/stata/stata)
==19705==    by 0x923B14: ??? (in /usr/local/stata/stata)
==19705==    by 0x90647B: ??? (in /usr/local/stata/stata)
==19705==    by 0x5B4C78F: (below main) (in /usr/lib/libc-2.21.so)


* [ ] SVR produces nr_class=2 for some reason, which means that my code allocates a 2x2 rho and a 2x1 nSV,
   but then nSV doesn't get filled in (presumably this is my safeties kicking in: something screws)
   and rho just has a single entry
   it would be better if they weren't constructed at all, if that's how it's going to be
   i need to investigate what's going on here
    and possibly
     - axe nSV and nr_class
     - replace rho with a scalar (since it only has one entry)

* [?] okay, i';m 99% sure judging from tracing the sklearn source code that in OneClass mode, Y is *ignored*. sklearn passes an empty array, which gets translated to a 0-length memoryview which should get translated to a NULL pointer internally, and then is copied verbatim (as NULL) into the svm_problem
  so what this means for me is that right now:
 
I should probably do this:
 
 svm `varlist', type(ONE_CLASS) -->
 tempvar B
 svm `B' `varlist', type(ONE_CLASS)

* [ ] from sklearn/svm/base.py: "
        # In binary case, we need to flip the sign of coef, intercept and
        # decision function. Use self._intercept_ and self._dual_coef_ internally."

* [ ] SVR doesn't output strLabels. which makes sense: there's no labels to output. but it does output 'rho' (but only a single rho long?? maybe we should output a scalar in this case??) and 
  * it also sets nr_class, even though there's no classes to speak of?? libsvm quirk??

* [x] there's an off-by-one-ish bug in the new exporting SVs code, zwhich crops up if the list of SVs doesn't include the last sample.
This code will trigger it:
. sysuse auto
. drop make
. order gear_ratio
. svm * if !missing(rep78), sv(Is_SV) type(EPSILON_SVR)
_model2stata phase 3: warning: overflowed sv_indices before all rows filled. i=74, s=49, l=49
 and it seems that if this happens it also breaks labelling of

* [x] sv_indices is *relative to the data given*; in particular, data that was dropped on account of an if condition *is mis-counted*
       run tests/predict_float to see: all but the last 5 are not marked as SVs and there are exactly 5 rows which were skipped due to missing data

* [-] Verify that Stata turns missing values into NaNs before libsvm eats them
  -> it doesn't. Stata missing is a particular large floating point number (and Stata is not wise enough to treat it specially in >! instead you 
     i've 

* [ ] In console mode, the duplicate-writes in stutil.c actually show up twice
      But in non-console mode, I definitely want them to happen twice.
      Problem: plugins cannot detect if they are in console or non-console mode, since that information is in c(), which is inaccessible to them.
       tip: Stata C plugins can access only global macros, scalars, and matrices (oh and variables in the current dataset, of course)
                they can access local macros only because of a quirk which is now enshrined in the API:
                they are just global macros with "_" prefixed (which get deleted when they go out of scope)
      Workaround: prefix every "plugin call" with a wrapper that copies everything out of r(), e(), s() and c() into scalars (you can even use strtoname() to canonicalize names)
         http://www.statalist.org/forums/forum/general-stata-discussion/general/1295308-bundling-dlls-in-pkgs?p=1296985#post1296985
       tip: you can access the list of existent things programmatically with Mata's st_dir() command, e.g.
            mata st_dir("e()","macro","*")
          gets you a list of strings of the names of things in e() which are macros
          UNFORTUNATELY, (see [M-5] st_dir(), page 844) st_dir() will not let you search c(). So I would have to hardcode the contents of c(). Which is not impossible, but not something I want to do anytime soon.
       tip: "copyin_plugin_call myplugin, arg1 arg2 -> [do all the copyins, making sure they are *locals*; also maybe set a special one to flag that you were called with copyin_plugin_call]; plugin call `0'"

* [-] BUG:
 . sysuse auto
 . order foreign //put foreign first
 . drop make //forget string vars
 . svm * if !missing(rep78), prob
 . predict P
 . predict P2, prob
 --> P and P2 have *opposite* results. is this because I'm mis-ordering the results somehow???? what happens in sklearn? or on the command line??
It's not a bug in my code: it's libsvm being weird again. The equivalent command lines (after a suitable export_svmlight) give
```
[kousu@galleon src]$ svm-train -q -b 1 tests/auto.svmlight 
[kousu@galleon src]$ svm-predict -b 0 tests/auto.svmlight auto.svmlight.model P
Model supports probability estimates, but disabled in prediction.
Accuracy = 100% (69/69) (classification)
[kousu@galleon src]$ svm-predict -b 1 tests/auto.svmlight auto.svmlight.model P2
Accuracy = 0% (0/69) (classification)
[kousu@galleon src]$ 
 ```


* [x] svm_predict, prob can gives the columns in the wrong order, so that the listed probabilities appear to disagree with the listed predictions
   The trouble is that predict_prob() gives results back ordered by the values in labels[] which are ordered by the order Stata ran into the classes
   the *other* trouble is, those labels are arbitary--they are the values libsvm discovered in the data--, and mapping them to actual columns is tricky because libsvm doesn't 
   I fixed it sorta by mapping from k -> label[k], on datasets where that the categories are 0-based
   but in general this will fail
   hmmm
   sooooo I need to do something else. I guess I do need to look at labels
    i need to...
     insight: strLabels is really strLevels
              instead of looping over levelsof I loop over strLevels
  -->> is sklearn.svm.SVC.classes_ === svm_model->labels[]? if so, i think we should copy their approach.


* [x] sanitize variable names before generating new ones
  -> built in strtoname() function


* [ ] duke.svmlight is actually a terrible dataset, or I'm misusing it: it thinks *everything* is a support vector which defeats the purpose


* [ ] what happens if you predict, prob on a continuous variable??
* [x] what happens if you predict, prob on an SVR? does it refuse?
* [ ] On errors, automatically erase newly generated variables.
  * wrap the body of predict and use 'snapshot' so that failures get rolled back.
* [x] BUG: silent failure if you mix SVR with "prob";
  -> denied
  [ ] XXX what is up with double svm_get_svr_probability()? It seems to suggest there is a corner case where it is legal to mix the two!
      however svm_predict_probability() (silently) falls back on svm_predict() if the model is not a classification, so I stand by what I've done.
* [x] the libsvm_patches.c::_pprint() functions *should run through the print function stored in libsvm*, obviously.

- [ ] BUG: is sterror() not printing to SF_error()??? what's going wrong?

* [x] BUG: mark the bin/<platform>/* files as .SECONDARY so they don't get auto-erased by make

* [x] BUG: noprobability isn't working

* [x] since export writes "total_sv" maybe I should rename l->total_sv, instead??

* [x] *don't* typecheck in predict, because in principle you could have non-integer classes
  -> changed to a warning with sample code showing how to disable the warning.
* [x] move the warning to svm_train, because that's really where it belongs (note: the way libsvm handles classification of floating points is to silently cast them to ints first)


- [x] BUG: svm_predict_probability() gives opposite answers to svm_predict()
  ---> it's a tuning issue. svm_predict_probability is an entirely different method than svm_predict
    the sklearn people explain this a bit. the libsvm people give it a sparse and confusing one line answer in their FAQ.
  - [x] test on a multiclass dataset
  - [x] test if svm-train has the same bug and if so report the damn thing. fucking libsvm.
        (easiest to do this after svmlight_save() is available)

- [ ] BUG: tests/export on the auto data records strange y values
      rather than 0s and 1s, it records 0.4375 and -1.
      despite this, predict works as expected. HMMM. another bug in libsvm? i.e. in svm_save()?




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



Paper
=====

We are going to submit a paper to the [Stata Journal](http://www.stata-journal.com/).

[ ] [Submission](http://www.stata-journal.com/submissions/) format
 - the archived articles (e.g. http://www.stata-journal.com/top-articles/downloaded/) sure look like they are done up in LaTeX
 - but the instructions say "ASCII and Word contributions will be accepted."

[ ] find Nick Cox papers and read them
[x] read Schonlau's papers to get an idea of style
[x] read the entire libsvm guide carefully
[ ] read the libsvm implementation paper

 

Sections:
--------

[ ] abstract
[ ] intro
    - mini TOC in the last paragraph
[ ] history and mathematics of SVM
   = not super in depth, just enough to let give our users intuition about what the parameters are.
    They can read the references, or, at this point, google, if they care
    - [ ] svc
    - [ ] svr
    - [WONT] one_class 
   review train/test splits and cross-validation
[ ] Stata-svm ("the svm package")
  - installation (??? some papers include this, others don't?)
  - syntaxes
  - options
  - introduce svmlight, briefly
  - introduce ensurelib, ensurepkg, clone, and example??
   
[ ] tuning issues
  - scaling
    -- keeping the *same* scaling around
  - parameter selection (grid search! cross validation!)
  - predictor selection
    -> support vectors will always be predicted (..wait.. this isn't true... hm)
    -> if you have perfect correlation between outcome and one or more predictors (e.g. a unique sample ID), 

[ ] examples
  * 1) classification
     - demonstrate the improvements to the fit as tuning is done, like in the libsvm guide
     - compare efficiency to logistic
       is this glm, family(binomial) or logistic??
  * 2) regression
     - compare to, say, least squares

[ ] Discussion
   - mention that libsvm has more features than mentioned here, and see their implementation paper and 
   - Small Stata limits: what happens if you have too many variables and what happens if you overflow matsize
   - tips on writing stata plugins / bring up the ensurelib and ensurepkg commands
[ ] Acknowledgements:
    - the libsvm authors, for their library which made developing SVM for Stata rapid and reasonably painless
    - [Andreas Mueller](https://github.com/amueller) for correcting our misconceptions about libsvm
    - [Sergiy Radyakin](http://www.worldbank.org/en/about/people/sergiy-radyakin) of the World Bank and
    - [Sergio Correia](https://github.com/sergiocorreia) of Duke University
       for offering their experience in the tiny details of Stata
    - [Ben Jann](https://ideas.repec.org/e/pja61.html#subaffil-body-0), Institute of Sociology, University of Bern, for his center package
  [ ] namedrop open source     
[ ] References

    



GNU make
========
* [ ] On Windows, it appears that forward-slashes aren't recognized as path separators in targets. They are in prerequisites, though.
   Set up a test case and submit a bug report.

boost.ado
=========
* [x] backport putting subdirectories for packages
* [x] "local k : word count `varlist'" better written "scalar k = wordcount("`varlist'")"
* [x] backport .pkg's (new?) feature of 'g WIN64 boost64.dll boost.plugin' + 'h boost.plugin'
* [x] backport auto-loading the plugin


libsvm
======
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

