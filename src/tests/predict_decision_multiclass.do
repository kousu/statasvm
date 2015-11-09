* predict_decision_multiclass
* like predict_decision, but this exercises the complicated triangular label matrix code by making sure there's more than one pair

sysuse auto
label define origin 2 "Dodge", add
label define origin 3 "Buick", add
replace foreign = 2 in 20/22
replace foreign = 3 in 4/10

svm foreign price-gear_ratio if !missing(rep78)
capture noisily predict P if !missing(rep78), dec

list foreign P*
desc P*
ereturn list
