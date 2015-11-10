* predict_svr_scores.do

quietly do tests/train_svr.do

predict P in 50/70 if !missing(rep78) /* test, on both part of the training and part of the testing data */

predict P2 if !missing(rep78), scores
list price P*

