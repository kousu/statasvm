* export.do
svm_load using "tests/duke.svmlight", clip
svm *
svm_export using "tests/duke.model"
type "tests/duke.model", lines(10)
