// Setup
use attitude_indicators

// Shuffle
set seed 12998
gen u = uniform()
sort u

// Train/test split
local split = floor(_N*3/4)
local train = "1/`=`split'-1'"
local test = "`split'/`=_N'"

// Model
svmachines attitude q* in `train', kernel(poly) gamma(0.5) coef0(7) prob
predict P in `test', prob

// the value in column P matches the column P_<attitude> with the highest probability
list attitude P* in `test'

// Compute error rate.
gen err = attitude != P in `test'
sum err in `test'

// Beware:
//  predict, prob is a *different algorithm* than predict, and can disagree about predictions.
//  This disagreement will become absurd if combined with poor tuning.
predict P2 in `test'
gen agree = P == P2 in `test'
sum agree in `test'
