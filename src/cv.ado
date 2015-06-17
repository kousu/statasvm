/* cv: cross-validated predictions from any Stata estimation command.
 *
 * Breaks a dataset into a number of subsets ("folds"), and for each
 * runs an estimator on everything but that subset, and predicts results.
 * In this way, the fit is unbiased by the estimation process, because
 * each prediction is made from data which were never involved in fitting.
 * Sometimes this is described as a way to control overfitting.
 *
 * 
 * In general there are two ways to measure the performance of an estimator:
 *  looking at its residuals -- in machine learning jargon, the training error
 *  looking at its cross-validated residuals -- the cross-validation error
 * The cv error is an estimate of the generalization error --- the performance
 * of your model on data it has never seen before --- which is usually what you care about in applications.
 * The ratio of the two tells you if you are over- or under- fitting:
 *  - if training error is higher, you are underfitting---you do not have enough degrees of freedom in your model---because the training is not doing as well on the full dataset as it does on slices (this is rare)
 *  - if training error is lower, you are overfitting---you have too many degrees of freedom, and you're fitting noise instead of signal---, because the training error is underestimating the generalization error.
 *
 * (There is also a third measurement:
 *  looking at it's test-set residuals -- the testing error
 * Cross-validation is usually used in conjunction with grid-search to tune tuning-parameters.
 * This in itself can be thought of as a type of estimation, and hence keeping a spare set of data
 * purely for testing immunizes your performance from overfitting in the grid-search,
 * even though each individual section of grid-search should be immune from overfitting.)
 * 
 *
 * syntax:
 * cv estimator target y x1 x2 x3 ... [if] [in], folds(#) [shuffle] [options to estimator]
 *
 * estimator should be a standard Stata estimation command which can be followed by a call to "predict target if"
 * pass folds(_N) (and no if or in conditions) to do leave-one-out cross-validation (LOOCV)
 * The name is perhaps inaccurate: this code does no validation by itself; all it does is generate unbiased predictions;
 *  however the method is the standard CV method, so until someone complains the name is sticking.
 * to further reduce bias, consider passing shuffle.
 *
 * Example:
 *
 * . sysuse auto
 * . svm foreign headroom gear_ratio weight, type(c_svc) gamma(0.4) c(51)
 * . predict P
 * . gen err = foreign != P
 * . qui sum err
 * . di "Training error rate: `r(mean)'"
 * . drop P err
 * .
 * . cv P svm foreign headroom gear_ratio weight, folds(_N/3) shuffle  type(c_svc) gamma(0.4) c(51)
 * . gen err = foreign != P
 * . qui sum err
 * . di "Cross-validated error rate: `r(mean)'"
 *
 * You can use this with "unsupervised" estimators---ones which take no {help depvar} (y)---too.
 * cv passes whatever options you give it directly to the estimator; all it handles it the folding.
 *
 *
 * See also:
 *  {help gridsearch}
 *
 *
 * TODO:
 *  'if' and 'in' 
 *  stratified folding
 *  maybe this should be called "cross_predict" because we don't actually do the validation...
 */

program define cv, eclass
  
  /* parse arguments */
  gettoken target 0 : 0
  gettoken estimator 0 : 0
  syntax varlist [if] [in], folds(int 5) [shuffle] [strata(string)] [*]
  
  confirm name `estimator'
  confirm new variable `target'
  confirm variable `varlist'
  
  qui count `if' `in'
  if(`folds'<=0 | `folds'>=`r(N)') {
    di as error "Invalid number of folds: `folds'. Must be between 1 and the number of active observations `r(N)'."
    exit 1
  }
  
  if("`strata'" != "") {
    confirm variable `strata'
    di as error "cv: stratification not implemented."
    exit 2
  }
  
  
  /* shuffling */
  if("`shuffle'"!="") {
    tempvar original_order
    tempvar random_order
    gen `original_order' = _n
    gen `random_order' = uniform()
    sort `random_order'
  }
  
  
  /* generate folds */
  // the easiest way to do this in Stata is simply to mark a new column
  // and stamp out id numbers into it
  // the tricky part is dealing with if/in
  // and the trickier (and currently not implemented) part is dealing with
  // stratification (making sure each fold has equal proportions of a categorical variable)
  tempvar fold
  if("`if'"!="" | "`in'"!="") {
    di as error "cv: if/in not yet implemented."
    exit 3
  }
  gen int fold = _n/`folds'
  // TODO: handle if/in
  //       this would be easy if I had an _n which was the index within the selected subset: just use that instead
  // I could write a loop, but that's slow. also i don't know how to mix if/in and loops
  
  // because shuffling can only affect which folds data ends up in,
  // immediately after generating fold labels we can put the data back as they were.
  // (i prefer rather do this early lest something later break and the dataset be mangled)
  // (this can't use snapshot or preserve because restoring those will erase `fold')
  if("`shuffle'"!="") {
    sort `original_order'
  }
  
  
  /* cross-predict */
  // We don't actually predict into target directly, because most estimation commands
  // get annoyed at you trying to overwrite an old variable (even if an unused region).
  // Instead we repeatedly predict into B, copy the fold into target, and destroy B.
  // 
  // We don't actually create `target' until we have done one fold, at which point we *clone* it
  // because we do not know what types/labels the predictor wants to attach to its predictions,
  // (which can lead to strangeness if the predictor is inconsistent with itself)
  tempvar B
  foreach f = numlist 1/`folds' {
    // train on everything that isn't the fold
    `estimator' `varlist' if `fold' != `f', `options'
    // predict into the fold
    predict `B' if `fold' == `f'
    
    // on the first fold, *clone* B
    if(`f' == 1) {
      clone `target' `B' if 0
    }
    
    // save the predictions from the current fold
    replace `target' = `B' if `fold' == `f'
    drop `B'
  }
  
  /* clean up */
  // drop e(), because its contents at this point are only valid for the last fold
  // and that's just confusing
  ereturn clear
end