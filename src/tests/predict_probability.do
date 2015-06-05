* export.do

sysuse auto
svm foreign price-gear_ratio if !missing(rep78), prob
capture noisily predict P if !missing(rep78), prob
capture noisily predict P2 if !missing(rep78)

list foreign P*

