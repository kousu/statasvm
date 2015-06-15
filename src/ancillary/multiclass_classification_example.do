/* basic multiclass classification */

// setup
use attitude_indicators

local split = floor(_N*3/4)
local train = "1/`=`split'-1'"
local test = "`split'/`=_N'"

// In general, you need to do grid-search to find good tuning parameters.
// These values just happened to be good enough.
svm category q* in `train', kernel(poly) gamma(0.5) coef0(7)

predict P in `test'

// compute error rate
replace err = category != P in `test'
sum err in `test'

// however, this is cheating, because we trained on the whole dataset
// and svm can overfit by remembering each observation as an SV:
di "Percentage that are support vectors: `=round(100*e(N_SV)/e(N),.3)'"
// in which case, those "predictions" are just lookups
