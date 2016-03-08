* train.do
sysuse auto
replace foreign = 3 if _n < 10
replace foreign = 4 if _n > 10 & _n < 20
svmachines price-gear_ratio if !missing(rep78), type(one_class)
do tests/helpers/inspect_model.do

