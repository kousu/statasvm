* train.do
svm_load using "tests/duke.svmlight"
svm_train *
do tests/helpers/inspect_model.do
