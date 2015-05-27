* export.do
do "tests/train.do"
svm_export using "tests/auto.model"
type "tests/auto.model", lines(10)
