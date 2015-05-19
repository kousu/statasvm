* export.do
svm_load using "tests/duke.svmlight"
svm_train *
svm_export using "tests/duke.model"
type "tests/duke.model", lines(10)
