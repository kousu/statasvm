* train_svr.do
sysuse auto
svmachines price mpg-gear_ratio if !missing(rep78), type(nu_svr) kernel(sigmoid)
do tests/helpers/inspect_model.do

