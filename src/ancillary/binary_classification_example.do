// Setup
sysuse auto

// Machine learning methods like SVM are a black-box and it is very easy to overfit them.
// To compensate, it is important to split data into training and testing sets, fit on
// the former and measure performance on the latter, so that performance measurements
// are not artificially inflated by data they've already seen.
local split = floor(_N/2)
local train = "1/`=`split'-1'"
local test = "`split'/`=_N'"

// but after splitting the proportion of classes can become unbalanced.
// The reliable way to handle this is a stratified split, a split that
// fixes the proportions of each class in each partition of each class.
// The quick and dirty way is a shuffle:
set seed 9876
gen u = uniform()
sort u

// Fit the classification model on the training set, with 'verbose' enabled.
// Training cannot handle missing data; here we elide it, but usually you should impute.
svm foreign price-gear_ratio if !missing(rep78) in `train', v

// Predict on the test set.
// Unlike training, predict can handle missing data: it simply predicts missing.
predict P in `test'

// Compute error rate: the percentage of mispredictions is the mean of err.
gen err = foreign != P in `test'
sum err in `test'
