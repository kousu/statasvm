// Setup
use attitude_indicators

local split = floor(_N*3/4)
local train = "1/`=`split'-1'"
local test = "`split'/`=_N'"

// In general, you need to do grid-search to find good tuning parameters.
// These values just happened to be good enough.
svm category q* in `train', kernel(poly) gamma(0.5) coef0(7)

predict P in `test'

// Compute error rate.
replace err = category != P in `test'
sum err in `test'

// An overly high percentage of SVs means overfitting
di "Percentage that are support vectors: `=round(100*e(N_SV)/e(N),.3)'"
