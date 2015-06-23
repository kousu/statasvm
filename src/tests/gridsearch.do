// grid search for good SVM parameters
// by Matthias Schonlau
// enhanced to use cv.ado by Nick Guenther
// 
// this is not a function because
// - it is technically difficult:
//   - looping over ranges of arbitrary parameters is muddy (the sklearn GridSearch object has to take a dictionary of parameter->[set of values to try], which just looks bad, but is probably as good as you're going to get
//   - doing that in *Stata* is extra muddy
//   - 
// - you always need to inspect the results before going on because there may be multiple equally good regions to search down into

set more off
clockseed



use tests/joe_dutch_merged

///////////////////////////////////////////////////////////
// randomize order
gen u=uniform()
sort u
///////////////////////////////////////////////////////////
// scaling autonormalize
sum _textnum_tokens
gen ntoken_stan= (_textnum_tokens -r(mean)) / r(sd)
///////////////////////////////////////////////////////////

// on top of the train/test splits within cv, hold out some data which never get trained on ever
gen train = _n<=(_N*.70)
local train = "train==1"
local test = "train==0"

// nevermind!
replace train = 1

// these columns are not a part of the dataset
// however Stata only lets us have one dataset
// so we just use this convention: never look in these columns when you mean to look in the others
// entries in them are filled in one 
gen accuracy=.
gen C=.
gen gamma=.

// XXX there's a memory leak in _svm.plugin which means that running 5+-fold CV on this dataset crashes before it can finish
local folds = 2

local i = 0
foreach C of numlist 0.01 1 100 10000 100000 {
	foreach G of numlist .0001 .001 .01 .1 1 10 {
	local i = "`++i'"
	di as txt "svm category {indepvars} if `train' , c(`C') gamma(`G') cache(1024)"
	// generate accuracy measurements using 5-fold cross-validation
	cv pred   svm category  ntoken_stan  q*  if `train' , folds(`folds') shuffle est(c(`C') gamma(`G') cache(1024))
	gen acc = pred == category
	qui sum acc
	local accuracy = `r(mean)'
	
	// save results to our side-table (which is joined to the main table, but don't tell anyone that)
	qui replace C = `C' in `i'
	qui replace gamma = `G' in `i'
	qui replace accuracy = `accuracy' in `i'
	
	drop pred acc
	
	list C gamma accuracy in `i'
	di ""
	}
}

list C gamma accuracy in 1/`i'


twoway contour accuracy gamma C, yscale(log) xscale(log) ///
     ylabel(.0001 .001 .01 .1 1 10) xlabel(0.01 1 100 10000 100000 )  /// 
	   ccuts(0(0.1)1) zlabel(#10, format(%9.2f))
graph export  svm_contour_cv_`folds'.pdf , replace

// XXX temporary
exit, clear
