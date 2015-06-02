

// uncomment if Stata-SVM is not installed to the system
adopath ++ "../../src"

use classification_bug

// training which does the wrong thing
svm category q*, prob
// tuning parameters pulled out of a hat from https://github.com/scikit-learn/scikit-learn/issues/4800
// which causes
//svm category q*, prob c(10) gamma(0.01)
// this is equally successful
//svm category q*, prob c(100)


predict P1
predict P2, prob

tab category
tab P1
tab P2
