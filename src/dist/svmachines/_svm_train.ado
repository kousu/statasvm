/* _svm_train: this is the meat of the Stata interface to the fitting algorithm.
  This is called by svm_train; though Stata programs can call subprograms defined in the same file as them,
  similar to Matlab, this has to be a separate file as the special command 'xi' used there apparently cannot
*/
  

/* load the C extension */
svm_ensurelib           // check for libsvm
program _svmachines, plugin    // load the wrapper for libsvm

program define _svm_train, eclass
  version 13
  
  /* argument parsing */
  // these defaults were taken from svm-train.c
  // (except that we have shrinking off by default)
  #delimit ;
  syntax varlist (numeric)
         [if] [in]
         [,
           // strings cannot have default values
           // ints and reals *must*
           // (and yes the only other data types known to syntax are int and real, despite the stata datatypes being str, int, byte, float, double, ...)
           // 
           // also be careful of the mixed-case shenanigans
           
           Type(string)
           
           Kernel(string)
           
           Gamma(real 0) COEF0(real 0) DEGree(int 3)
           
            C(real 1) EPSilon(real 0.1) NU(real 0.5)
           
           // weights() --> char* weight_label[], double weight[nr_weight] // how should this work?
           // apparently syntax has a special 'weights' argument which is maybe meant just for this purpose
           // but how to pass it on?
           TOLerance(real 0.001)
           
           SHRINKing PROBability
           
           CACHE_size(int 100)
           
           // if specified, a column to generate to mark which rows were detected as SVs
           SV(string)
           
           // turn on internal libsvm printing
           Verbose
		   
		   //set the C random seed
		   seed(int 1)
         ];
  #delimit cr
  // stash because we run syntax again below, which will smash these
  local cmd = "`0'"
  local _varlist = "`varlist'"
  local _if = "`if'"
  local _in = "`in'"
  
  // make the string variables case insensitive (by forcing them to CAPS and letting the .c deal with them that way)
  local type = upper("`type'")
  local kernel = upper("`kernel'")
  
  // translate the boolean flags into integers
  // the protocol here is silly, because syntax special-cases "no" prefixes:
  // *if* the user gives the no form of the option, a macro is defined with "noprobability" in lower case in it
  // in all *other* cases, the macro is undefined (so if you eval it you get "")
  // conversely, with regular option flags, if the user gives it you get a macro with "shrinking" in it, and otherwise the macro is undefined  
  if("`shrinking'"=="shrinking") {
    local shrinking = 1
  }
  else {
    local shrinking = 0
  }

  if("`probability'"=="probability") {
    local probability = 1
  }
  else {
    local probability = 0
  }


  /* fill in default values (only for the string vars, because syntax doesn't support defaults for them) */
  if("`type'"=="") {
    local type = "SVC"
  }
  
  if("`kernel'"=="") {
    local kernel = "RBF"
  }

  /* preprocessing */
  if("`type'" == "ONE_CLASS") {
    // handle the special-case that one-class is unsupervised and so takes no
    //  libsvm still reads a Y vector though; it just, apparently, ignores it
    //  rather than tweaking numbers to be off-by-one, the easiest is to silently
    //  duplicate the pointer to one of the variables.
    gettoken Y : _varlist
    local _varlist = "`Y' `_varlist'"
  }
  else {
    gettoken depvar indepvars : _varlist
  }

  /* sanity checks */
  if("`type'" == "SVC" | "`type'" == "NU_SVC") {
    // "ensure" type is categorical
    local T : type `depvar'
	/*
    if("`T'"=="float" | "`T'"=="double") {
      di as error "Warning: `depvar' is a `T', which is usually used for continuous variables."
      di as error "         SV classification will cast real numbers to integers before fitting." //<-- this is done by libsvm with no control from us
      di as error
      di as error "         If your outcome is actually categorical, consider storing it so:"
      di as error "         . tempvar B"
      di as error "         . generate byte \`B' = `depvar'"   //CAREFUL: B is meant to be quoted and depvar is meant to be unquoted.
      di as error "         . drop `depvar'"
      di as error "         . rename \`B' `depvar'"
      di as error "         (If your category coding uses floating point levels you must choose a different coding)"
      di as error
      di as error "         Alternately, consider SV regression: type(SVR) or type(NU_SVR)."
      di as error
    }
	*/
  }

  if(`probability'==1) {
    // ensure model is a classification
    if("`type'" != "SVC" & "`type'" != "NU_SVC") {
      // the command line tools *allow* this combination, but at prediction time silently change the parameters
      // "Errors should never pass silently. Unless explicitly silenced." -- Tim Peters, The Zen of Python
      di as error "Error: requested model is a `type'. You can only use the probability option with classification models (SVC, NU_SVC)."
      exit 2
    }
  }
  
  if("`sv'"!="") {
    // fail-fast on name errors in sv()
    local 0 = "`sv'"
    syntax newvarname
    
  }

  
  /* call down into C */
  /* CAREFUL: epsilon() => svm_param->p and tol() => svm_param->epsilon */ 
  #delimit ;
  plugin call _svmachines `_varlist' `_if' `_in',
      `verbose'  // notice: this is *not* in quotes, which means that if it's not there it's not there at all
      "train"
      "`type'" "`kernel'"
      "`gamma'" "`coef0'" "`degree'"
      "`c'" "`epsilon'" "`nu'"
      "`tolerance'"
      "`shrinking'" "`probability'"
      "`cache_size'" "`seed'"
      ;
  #delimit cr
  
  // *reparse* the command line in order to fix varlist at it's current value.
  // If "varlist" includes tokens that get expanded to multiple variables
  // then when svm_predict reparses it again, it will get a different set.
  local 0 = "`cmd'"
  syntax varlist [if] [in], [*]
  local cmd = "`varlist' `if' `in', `options'"
  
  /* fixup the e() dictionary */
  ereturn clear
  
  // set standard Stata estimation (e()) properties
  ereturn local cmd = "svmachines"
  ereturn local cmdline = "`e(cmd)' `cmd'"
  ereturn local predict = "svm_predict" //this is a function pointer, or as close as Stata has to that: causes "predict" to run "svm_predict"
  ereturn local estat = "svm_estat"     //ditto. NOT IMPLEMENTED
  
  ereturn local title = "Support Vector Machine"
  ereturn local model = "svmachines"
  ereturn local svm_type = "`type'"
  ereturn local svm_kernel = "`kernel'"
  
  ereturn local depvar = "`depvar'" //NB: if depvar is "", namely if we're in ONE_CLASS, then Stata effectively ignores this line (which we want).
  //ereturn local indepvars = "`indepvars'" //XXX Instead svm_predict reparses cmdline. This needs vetting.
  
  // append the svm_model structure to e()
  _svm_model2stata `_if' `_in', sv(`sv') `verbose'
end
