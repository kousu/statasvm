// setup
webuse highschool

/* basic multiclass classification */

local split = floor(_N/2)
local train = "1/`=`split'-1'"
local test = "`split'/`=_N'"  

// train on about half the data
svm weight height i.race i.sex in `train', type(epsilon_svr) sv(Is_SV)

// examine which observations were chosen as support vectors
tab `e(depvar)' Is_SV in `train'

// predict on the other half
predict P in `test'

// look at some of the results
list weight height race sex P in 3453/3496
  // true categories
tab race in `test'
  // predicted categories
tab P in `test'


// compute error rate
// since this is regression, we use substraction 
gen err = abs(weight - P) in `test'
sum err

// ouch! those results are terrible! it predicted everything into one class
drop P Is_SV err

/* now, with tuning */

// In general, you need to do grid-search to find optimal tuning
// parameters these values just happened to be good enough.
svm race height weight in `train', c(50) gamma(0.4) eps(55)

predict P in `test'

// the results are a lot better now
gen err = abs(weight - P) in `test'
sum err
