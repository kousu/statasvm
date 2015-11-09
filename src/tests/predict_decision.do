* export.do

sysuse auto
svm foreign price-gear_ratio if !missing(rep78)
capture noisily predict P if !missing(rep78), dec

list foreign P*

