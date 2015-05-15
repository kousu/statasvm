
* The variables created will be 'y' and 'x%d' for %d=[1 through max(feature_id)].
* Feature IDs are always positive integers, in svmlight format, according to its source code.

program define svm_load
  syntax using/
  
  capture program _svm, plugin
  plugin call _svm, "read" "pre" "`using'"
  
  scalar list /*DEBUG*/
  
  clear
  quiet generate y = .
  
  * HACK: StataIC (which I am developing on) has a hard upper limit of 2k variables
  * We spend 1 on the 'y', and so we are limited to 2047 'x's
  if(`=M' > 2048-1) {
    scalar M = 2047
  }
  
  * this weird newlist syntax is the official suggestion for making a set of new variables in "help foreach"
  foreach j of newlist x1-x`=M'  {
    quiet generate `j' = .
  }
  
  quiet set obs `=N'
  
  * "*" means "all variables"
  capture plugin call _svm *, "read" "`using'"
end


* load the given svmlight-format file into memory
* the outcome variable (the first one on each line) is loaded in y, the rest are loaded into x<label>, where <label> is the label listed in the file before each value
* note! this *will* clear your current dataset
* NB: it is not clear to me if it is easier or hard to do this in pure-Stata than to try to jerry-rig C into the mix (the main trouble with C is that extensions cannot create new variables, and we need to create new variables as we discover them)
* it is *definitely* *SLOWER* to do this in pure Stata. svm-train loads the same test dataset in a fraction of a second where this takes 90s (on an SSD and i7).
program define svm_load_purestata
  
  * this makes macro `using' contain a filename
  syntax using/
  
  * .svmlight is meant to be a sparse format where variables go missing all the time
  * so we do the possibly-quadratic-runtime thing: add one row at a time to the dataset
  * using the deep magic of "set obs `=_N+1`; replace var = value in l". I think 'in l' means 'in last' but 'in last' doesn't work.
  * tip originally from Nick Cox: http://statalist.1588530.n2.nabble.com/Adding-rows-to-datasheet-td4784525.html
  * I suspect this inefficency is intrinsic.
  *  (libsvm's svm-train.c handles this problem by doing two passes over the data: once to count what it has to load, and twice to actually allocate memory and load it; we should profile for which method is faster in Stata)
  tempname fd
  file open `fd' using "`using'", read text
  
  * get rid of the old data
  clear
  
  * we know svmlight files always have exactly one y vector
  generate double y = .
  
  file read `fd' line
  while r(eof)==0 {
  	*display "read `line'" /*DEBUG*/
  	
  	quiet set obs `=_N+1'
  	
  	gettoken Y T : line
  	quiet replace y = `Y' in l
  	*di "T=`T'" /*DEBUG*/
  	
  	* this does [(name, value = X.split(":")) for X in line.split()]
  	* and it puts the results into the table.
  	local j = 1
  	while("`T'" != "") {
      *if(`j' > 10) continue, break /*DEBUG*/
  	  gettoken X T : T
  	  gettoken name X : X, parse(":")
  	  gettoken X value : X, parse(":")
  	  *di "@ `=_N' `name' = `value'" /*DEBUG*/
  	  
  	  capture quiet generate double x`name' = . /*UNCONDITIONALLY make a new variable*/
    	capture quiet replace x`name' = `value' in l
  	  if(`=_rc' != 0) continue, break /*something went wrong, probably that we couldn't make a new variable (due to memory or built-in Stata constraints). Just try the next observation*/
  	  
			local j = `j' + 1
  	}
  	*list /*DEBUG: see the state after after new observation*/
  	
  	file read `fd' line
  }
  file close `fd'
end
