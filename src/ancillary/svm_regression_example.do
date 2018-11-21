// Setup
webuse highschool

// Shuffle
set seed 793742
gen u = uniform()
sort u

// Train/test split
local split = floor(_N/2)
local train = "1/`=`split'-1'"
local test = "`split'/`=_N'"

// Regression is invoked with type(svr) or type(nu_svr).
// Notice that you can expand factors (categorical predictors) into sets of
// indicator (boolean/dummy) columns with standard i. syntax, and you can
// record which observations were chosen as support vectors with sv().
svmachines weight height i.race i.sex in `train', type(svr) sv(Is_SV)

// Examine which observations were SVs. Ideally, a small number of SVs are enough.
tab Is_SV in `train'

predict P in `test'

// Compute residuals.
gen res = (weight - P) in `test'
sum res
