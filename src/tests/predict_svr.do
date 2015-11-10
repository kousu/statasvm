* predict_svr.do

quietly do tests/train_svr.do

predict P in 50/70 if !missing(rep78)

predict P2 if !missing(rep78)
generate error = abs(price - P2) //notice: subtraction, not comparison, because we're regressing, not classifying
list price P P2 error
summarize error
