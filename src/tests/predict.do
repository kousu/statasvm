* export.do

sysuse auto
svmachines foreign price-gear_ratio if !missing(rep78) in 41/60  /*train on some of the data; this range is chosen to cover 10 each of each kind of car*/
predict P in 50/70 /* test, on both part of the training and part of the testing data */

* fill in the rest and observe the error rate
* Stata convention (which predict enforces) is that we have to predict into a *new* variable
* (if we want to reuse the old one we have to drop it first; if we want to merge the results we need to make a second variable and then use ..other commands.. to do the merge)
predict P2
list foreign P P2
generate error = abs(foreign != P2)
summarize error

