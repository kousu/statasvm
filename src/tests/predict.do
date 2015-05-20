* export.do
svm_load using "tests/duke.svmlight"
svm_train * in 1-30
svm_predict P in 31-
list

