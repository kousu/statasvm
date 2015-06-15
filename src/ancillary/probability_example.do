// setup
webuse highschool

/* estimating class probabilities */

local split = floor(_N/2)
local train = "1/`=`split'-1'"
local test = "`split'/`=_N'"  

svm race height weight in `train', prob

// beware: predict, prob is a *different algorithm* than predict:
predict P in `test'
predict P2 in `test', prob

gen agree = P == P2
tab agree

// look at some of the results
// the value in P matches the P_<race> with the highest probability
list race height weight P* in 2120/2130

// tuning this to get good results is left as an exercise, because we are heartless
gen err = race != P2
sum err
