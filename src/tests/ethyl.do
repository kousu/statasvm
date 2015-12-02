// ethyl acrylate data , Bates and Watts, A1.10

clear 
import excel using "tests/ethyl.xlsx", firstrow
gen viscosity = exp(ln_viscosity)

set seed 100
gen u=uniform()
sort u

/////////////////////////////////////////////////////////////////////

local trainn=30
gen train= 0
replace train=1 if _n<=`trainn'

graph matrix  viscosity pressure  temp
twoway contour viscosity pressure temp

regress viscosity pressure temp if train
predict res,res
predict pred
predict rstan, rstan
bysort train: egen mse_reg=total((viscosity-pred)^2/`trainn')


// linear contour plot
twoway contour pred pressure temp
 

qnorm res
scatter rstan pred
exit 


////////////////////////////////////////////////////////////////////
// standardization does not affect the influences or predictions
/*
qui sum temp
gen temp_sta=(temp-r(mean)) / r(sd)
qui sum pressure
gen pressure_sta=(pressure-r(mean)) / r(sd)
*/
cap drop predb
boost viscosity temp pressure if train, dist(normal) pred(predb) influence shrink(0.1) inter(3)
bysort train: egen mse_boost=total((viscosity-predb)^2/`trainn')

qui svmachines viscosity temp pressure if train, eps(1)  c(1) gamma(.1) type(SVR)
predict preds
bysort train: egen mse_svm=total((viscosity-preds)^2/`trainn')


bysort train: sum mse_svm mse_reg mse_boost
