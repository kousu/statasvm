* train.do
svm_load using "tests/duke.svmlight"
svm *
do tests/helpers/inspect_model.do
