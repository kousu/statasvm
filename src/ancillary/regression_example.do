// setup
webuse highschool

/* basic multiclass classification */

local split = floor(_N/2)
local train = "1/`=`split'-1'"
local test = "`split'/`=_N'"  

// train on about half the data
svm weight height i.race i.sex in `train', type(epsilon_svr) sv(Is_SV)

// examine which observations were chosen as support vectors
// note that we cannot cross-tab this with the outcome like before
// as the outcome is continuous
tab Is_SV in `train'

// predict on the other half
predict P in `test'

// look at some of the results
list weight height race sex P in 3453/3496
  // true categories
sum weight in `test'
  // predicted categories
sum P in `test'


// compute error rate
// since this is regression, we use substraction 
gen err = abs(weight - P) in `test'
sum err

drop P Is_SV err

