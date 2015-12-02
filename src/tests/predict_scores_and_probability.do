* predict_scores_and_probability.do

sysuse auto
svmachines foreign price-gear_ratio if !missing(rep78), prob
predict P1, prob
predict P2, scores
capture noisily predict P3, prob scores
if(_rc == 0) {
  di as err "prob and scores should be mutually exclusive options"
  exit 1
}

list foreign P*

