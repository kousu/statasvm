* export.do
svm_load using "tests/duke.svmlight"
svm * in 1/25  /*train on some of the data*/
predict P in 23/40 /*test on part of the same but also not*/
list y x2-x6 P /*demonstrate that only the specified predictions are filled in*/

* fill in the rest and observe the error rate
drop P
predict P
list y P
generate error = abs(y != P)
summarize error
