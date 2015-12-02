* predict_scores.do

sysuse auto
svmachines foreign price-gear_ratio if !missing(rep78)
capture noisily predict P, scores

list foreign P*

