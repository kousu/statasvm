* train.do
sysuse auto
svmachines foreign price-gear_ratio if !missing(rep78), sv(SV)
list SV
do tests/helpers/inspect_model.do

