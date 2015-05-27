* train.do
sysuse auto
svm foreign price-gear_ratio if !missing(rep78)

