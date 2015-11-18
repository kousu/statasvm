* predict_oneclass_scores.do

sysuse auto
replace foreign = 3 if _n < 10
replace foreign = 4 if _n > 10 & _n < 20
svm price-gear_ratio if !missing(rep78), sv(SV) type(one_class)
predict P if !missing(rep78), scores
list P*
