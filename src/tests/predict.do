* export.do
svm_load using "tests/duke.svmlight"
svm * in 1/25  /*train on some of the data*/
predict P in 23/40 /*test on part of the same but also not*/
list y x2-x6 P /*demonstrate that only the specified predictions are filled in*/

* fill in the rest and observe the error rate
* Stata convention (which predict enforces) is that we have to predict into a *new* variable
* (if we want to reuse the old one we have to drop it first; if we want to merge the results we need to make a second variable and then use ..other commands.. to do the merge)
predict P2
list y P P2
generate error = abs(y != P2)
summarize error
