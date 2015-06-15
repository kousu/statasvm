// setup
use multiclass_on_indicators

/* basic multiclass classification */

svm category q*
predict P

// look at some of the results
list category P in 20/35
  // true categories
tab category
  // predicted categories
tab P

// compute error rate
gen err = category != P
sum err

// ouch! those results are terrible! it predicted everything into one class
drop P

/* now, with tuning */

// In general, you need to do grid-search to find optimal tuning
// parameters. These values just happened to be good enough.
svm category q*, kernel(poly) gamma(0.5) coef0(7)

predict P

// the results are a lot better now
tab P
replace err = category != P
sum err

// however, this is cheating, because we trained on the whole dataset
// and svm can overfit by remembering each observation as an SV:
di "Percentage that are support vectors: `=round(100*e(N_SV)/e(N),.3)'"
// in which case, those "predictions" are just lookups
