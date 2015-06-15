/* basic binary classification */

// setup
sysuse auto

// Machine learning methods like SVM are a black-box and it is very easy to overfit them.
// To compensate, it is important to split data into training and testing sets, fit on
// the former and measure performance on the latter, so that performance measurements
// are not artificially inflated by data they've already seen.
local split = floor(_N/2)
local train = "1/`=`split'-1'"
local test = "`split'/`=_N'"

// Fit the classification model, with 'verbose' enabled.
// Training cannot handle missing data, so it needs to be elided.
svm foreign price-gear_ratio if !missing(rep78) in `train', v

// Predict
// Unlike training, predict simply predicts missing if any data is missing.
predict P in `test'

// compute error rate
// the mean of the "in correct" variable is equal to the percentage of errors
gen err = foreign != P in `test'
sum err in `test'
