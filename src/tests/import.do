* import.do
do tests/helpers/settings.do
svm_import using "tests/duke.model"
do tests/helpers/inspect_model.do
