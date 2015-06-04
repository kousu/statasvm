* predict_svr.do

sysuse auto
capture svm price mpg-gear_ratio if !missing(rep78), type(nu_svr) kernel(sigmoid) probability
if(_rc == 0) {
  di as error "svm should disallow regression with probability turned on"
  exit 1
}
