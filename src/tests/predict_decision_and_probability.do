* export.do

sysuse auto
svm foreign price-gear_ratio if !missing(rep78), prob
predict P1 if !missing(rep78), prob
predict P2 if !missing(rep78), dec
capture noisily predict P3 if !missing(rep78), prob dec
if(_rc == 0) {
  di as err "prob and dec should be mutually exclusive options"
  exit 1
}

list foreign P*

