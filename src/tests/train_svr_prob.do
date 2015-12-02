* predict_svr.do

sysuse auto
capture svmachines price mpg-gear_ratio if !missing(rep78), type(nu_svr) kernel(sigmoid) probability
if(_rc == 0) {
  di as error "svmachines should disallow regression with probability turned on"
  exit 1
}
