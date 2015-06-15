// setup
webuse highschool

local split = floor(_N/2)
local train = "1/`=`split'-1'"
local test = "`split'/`=_N'"  

// use standard i. notation to indicate factors
// these get replaced with indicator columns before being passed to libsvm
svm race i.sex height weight i.state in `train'

predict P in `test'

// look at some of the results
list race sex height weight state P in 3453/3496
  // true categories
tab race in `test'
  // predicted categories
tab P in `test'

// compute error rate
gen err = race != P in `test'
sum err
