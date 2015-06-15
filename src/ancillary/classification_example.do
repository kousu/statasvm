// setup
sysuse auto

/* basic binary classification */

// train on about half the data, with 'verbose'
drop make // this is a string variable, which svm cannot handle
order foreign // put this first, which means it will be the dependent variable
svm * if !missing(rep78), v

// various technical details, constructed by the estimation
ereturn list
matrix list e(sv_coef)
matrix list e(rho)

// predict
// notice: you need not skip missing data here for
//         during predict (but only during prediction) missing data produces missing
//         this is like glm and regress [CITATION NEEDED]
predict P

// look at some of the results
list foreign P in 1/10
tab foreign
tab P

// compute error rate
// the mean of the "in correct" variable is equal to the percentage of errors
gen err = foreign != P if !missing(P)
sum err
