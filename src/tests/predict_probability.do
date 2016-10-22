* export.do


sysuse auto
svmachines foreign price-gear_ratio if !missing(rep78), prob
capture noisily predict P, prob
capture noisily predict P2

list foreign P*

