* predict_probability_strangelabels
* Ensure that the complicated labelling code buried in predict, prob behaves itself even when labels are shifted
* The final list should show that the probability columns are labelled with strings which mostly match what the actual values were.

sysuse auto
replace foreign = foreign+7
label define space_station 7 "DS9" 8 "Ferengi" // foreign was 0/1, now it's 7/8
label values foreign space_station
svmachines foreign price-gear_ratio if !missing(rep78), prob
capture noisily predict P, prob
capture noisily predict P2

list foreign P*

