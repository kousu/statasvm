* train.do
svm_load using "tests/duke.svmlight", clip
svm *
do tests/helpers/inspect_model.do
