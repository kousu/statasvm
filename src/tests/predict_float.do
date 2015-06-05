* train.do
sysuse auto

drop make
order gear_ratio // gear_ratio is a floating point value, but it only lives between 2 and 4 in this dataset, so libsvm casts it to classes 2 and 3

svm * if !missing(rep78), sv(SV)
do tests/helpers/inspect_model.do

predict Q
list `e(depvar)' Q SV
