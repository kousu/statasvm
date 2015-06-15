// Setup
use attitude_indicators

local split = floor(_N*3/4)
local train = "1/`=`split'-1'"
local test = "`split'/`=_N'"

svm category q* in `train', kernel(poly) gamma(0.5) coef0(7) prob
predict P in `test'

// the value in column P matches the column P_<attitude> with the highest probability
list category P* in `test'

// Compute error rate.
replace err = category != P in `test'
sum err in `test'

// Beware: predict, prob is a *different algorithm* than predict, and will give disagree about predictions.
// This disagreement can become absurd when combined with poor tuning.
predict P2 in `test'
gen agree = P == P2 in `test'
sum agree in `test'
