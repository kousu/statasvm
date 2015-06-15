
webuse highschool

// train on about half the data
svm sex /*i.sex*/ height weight /*i.state*/ in 1/2000, verbose

// predict on the other half
predict P in 2001/`=_N'

// look at some of the results
list sex /*sex*/ height weight /*state*/ P in 3453/3496
  // true categories
tab sex in 2001/`=_N'
  // predicted categories
tab P in 2001/`=_N'


// compute error rate
// the mean of the "in correct" variable is equal to the percentage of errors
// sublety: make sure to only generate this on the set you actually predicted on
//          because of how Stata handles missing data:
//          Stata considers <category> != . to be 1, not ., which inflates the error
gen err = sex != P in  2001/`=_N'
sum err

