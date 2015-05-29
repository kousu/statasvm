Edge cases (aka the list of things to test)
===========================================

// incorrectly mixing regression and classification
train [...], type(nu_svr)
predict, prob

// No predictors:
train depvar

// svm_import -> expecting to be able to access sv_coef


Is unicode in the docs going to break Stata13?