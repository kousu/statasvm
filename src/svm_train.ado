program _svm, plugin /*load the C extension if not already loaded*/

program define svm_train, eclass
  version 13
  
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
           
           type(string)
           kernel(string)
           
           degree(int 3)
         
           gamma(real 0) coef0(real 0) nu(real 0.5)
           p(real 0.1) c(real 1)
           
           // weights() --> char* weight_label[], double weight[nr_weight] // how should this work?
           // apparently syntax has a special 'weights' argument which is maybe meant just for this purpose
           // but how to pass it on?
           eps(real 0.001)
             
           SHRINKing noPROBability
         
           cache_size(int 100)
         ];
  #delimit cr
  
  /* fill in defaults for the string values */
  if("`type'"=="") {
    local type = "C_SVC"
  }
  if("`kernel'"=="") {
    local kernel = "RBF"
  }
  
  /* make the string variables case insensitive (by forcing them to CAPS and letting the .c deal with them that way) */
  local type = upper("`type'")
  local kernel = upper("`kernel'")
  
  /* translate the boolean flags into integers */
  // the protocol here is silly, because syntax special-cases "no" prefixes:
  // *if* the user gives the no form of the option, a macro is defined with "noprobability" in lower case in it
  // in all *other* cases, the macro is undefined (so if you eval it you get "")
  // conversely, with regular option flags, if the user gives it you get a macro with "shrinking" in it, and otherwise the macro is undefined
  
  if("`shrinking"=="shrinking") {
    local shrinking = 1
  }
  else {
    local shrinking = 0
  }
  
  if("`probability"=="noprobability") {
    local probability = 0
  }
  else {
    local probability = 1
  }
  
  /* call down into C */
  #delimit ;
  plugin call _svm `varlist' `if' `in', "train"
      "`type'" "`kernel'"
      "`degree'"
      "`gamma'" "`coef0'" "`nu'"
      "`p'" "`c'"
      "`eps'"
      "`shrinking'" "`probability'"
      "`cache_size'"
      ;
  #delimit cr
  
  /* fixup the e() dictionary */
  ereturn clear
  
  // set standard Stata regression properties
  ereturn local cmd = "svm_train"
  ereturn local cmdline = "`e(cmd)' `0'"
  ereturn local predict = "svm_predict" //this is a function pointer, or as close as Stata has to that: causes "predict" to run "svm_predict"
  ereturn local estat = "svm_estat"     //ditto. NOT IMPLEMENTED
  
  ereturn local title = "Support Vector Machine"
  ereturn local model = "svm"
  ereturn local svm_type = "`type'"
  ereturn local svm_kernel = "`kernel'"
  
  gettoken depvar indepvars : varlist
  ereturn local depvar = "`depvar'"
  //ereturn local indepvars = "`indepvars'" //XXX Instead svm_predict reparses cmdline. This needs vetting.
  
  // export the svm_model structure
  _svm_model2stata
end
