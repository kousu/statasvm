TODO
====

Copyright
---------

* [x] Agree upon a License

Build
-----
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
     -> _dlopenable

       but they can't call each others handle to it ("svm_train._svm" is invalid syntax, even though that's the name listed in 'program dir')


* [ ] make ensurelib a separate project/pkg
* [ ] make _{get,set}env.plugin a separate project/pkg

* [x] pull svm_load out to a separate plugin: _svmlight.plugin
  * [x] import_svmlight
  * [x] export_svmlight


Features
--------

* [x] write svmload.ado which handles reading svmlight format files
   * -> "a plugin cannot create
* [ ] make 'svm' a suite of subcommands; put everything into a single file, even, so that users cannot call them directly.
   this might not be possible because of scoping rules... Stata's native, core, regress command has prediction in regres_p.ado, a separate file.
  * [x] investigate subcommands; it seems "help a b" will try to look up "a_b.sthlp", but I don't think "a b" will call a_b.ado. hmm.q

* [ ] weighting
  * stata's "syntax" provides this as an option; so does libsvm's svm_parameter; I should just have to plug them together

* [ ] use rownames/colnames to label the return matrices with which classes is which 
  * nSV
  * probA / probB

* [ ] instead of returning the SVs matrix, add a boolean column marking if something is a support vector
  (to ensure uniqueness, it should be passed as an option; if not passed, don't mark it)

* [ ] provide svm_classify and svm_regress as convenience shortcuts to something like "svm `0', type(C_SVC)"  "svm `0', type(EPSILON_SVR)"
   -> and if you specify 'nu' as an option, trigger nu-SVM instead (NU_SVC, NU_SVR)
   -> this is a nicetohave/prematureoptimization, so leave it for version 2

* [x] make generate_clone into a more sensible API: "clone new = old, [nocopy]", and get 'syntax' to validate both the new and old varnames for us


- [ ] make the matrices in _model2stata all optional
      (with capture on the stata side and error catching and discarding on the C side)
      so that if they are too large to allocate you get a warning but not a crash
       (afterall, it's not like the C side of things is artificially memory limited)
      then you can still run the regression and get predictions, even

- [x] expose svm_param as options to svm_train
- [ ] support e(estat_cmd)
  * I don't really know what this is for; something to do with getting even more estimates after estimating your estimates

- [ ] handle fvs (i.varname, etc)
  - plugin call can't handle fvs, but I can use xi: to fudge them
    however there is a strange bug: xi doesn't work as advertised; is it just with plugin call??


- [x] make .sthlp files
   - [x] svm.sthlp is the primary one, covering svm_train and svm_predict in one (since users should never explicitly call svm_predict themselves)
   - [ ] svmlight.sthlp (how do I make 'help import svmlight' bring this up?)

Maintenance
-----------


- [ ] renames
  - [ ] svm_train to svm
  - [ ] svm_predict to svm_p (to match regress_p)

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


Bugs
----

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

* [ ] BUG:
 . sysuse auto
 . order foreign //put foreign first
 . drop make //forget string vars
 . svm * if !missing(rep78), prob
 . predict P
 . predict P2, prob
 --> P and P2 have *opposite* results. is this because I'm mis-ordering the results somehow???? what happens in sklearn?
* [ ] svm_predict, prob gives the columns in the order stata gives them, *not* in the order in labels. this is a problem.
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

