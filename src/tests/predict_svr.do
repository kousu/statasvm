* predict_svr.do

quietly do tests/train_svr.do

predict P in 50/70 /* test, on both part of the training and part of the testing data */

predict P2
generate error = abs(price - P2) //notice: subtraction, not comparison, because we're regressing, not classifying
list price P P2 error
summarize error
