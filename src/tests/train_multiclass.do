* train.do
sysuse auto
replace foreign = 3 if _n < 10
replace foreign = 4 if _n > 10 & _n < 20
svm foreign price-gear_ratio if !missing(rep78), sv(SV)
list SV
do tests/helpers/inspect_model.do

