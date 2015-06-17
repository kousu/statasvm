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
 * cv target estimator y x1 x2 x3 ... [if] [in], folds(#) [shuffle] [options to estimator]
 *
 * estimator should be a standard Stata estimation command which can be followed by a call to "predict target if"
 * folds is the number of folds to make. More is more accurate but slower.
 *   As a special case, pass folds(1) to simply train and predict at once.
 *   To do leave-one-out cross-validation (LOOCV), pass the number of observations (e.g. folds(`=_N'), though if you use if/in you'll need to modify that). 
 *
 * to further reduce bias, consider passing shuffle, but make sure you {help set seed:seed} the RNG well
 *  (e.g. see {help clockseed} or {help truernd}).
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
 * . cv P svm foreign headroom gear_ratio weight, folds(`=floor(_N/3)') type(c_svc) gamma(0.4) c(51)
 * . gen err = foreign != P
 * . qui sum err
 * . di "Cross-validated error rate: `r(mean)'"
 *
 * Example of if/in:
 * . cv P svm gear_ratio foreign headroom weight if gear_ratio > 3 in 22/63, folds(4) shuffle type(epsilon_svr) eps(0.5)
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
 *  [x] 'if' and 'in' 
 *  [ ] stratified folding
 *  [ ] is 'shuffle' a huge slowdown??
 *  [ ] maybe this should be called "cross_predict" because we don't actually do the validation...
 */

program define cv, eclass
  
  /* parse arguments */
  gettoken target 0 : 0
  gettoken estimator 0 : 0
  syntax varlist [if] [in], [folds(string)] [shuffle] [*]
  
  confirm name `estimator'
  confirm new variable `target'
  confirm variable `varlist'
  
  //Stata if funky: because I use [*] above, if I declare folds(int 5) and you pass a real (e.g. folds(18.5)), rather than giving the usual "option folds() incorrectly specified" error, Stata *ignores* that folds, gives the default value, and pushes the wrong folds into the `options' macro, which is really the worst of all worlds
  // instead, I take a string (i.e. anything) to ensure the folds option always,
  // and then parse manually
  if("`folds'"=="") {
    local folds = 5
  }
  confirm integer number `folds'
  
  //di as txt "folds= `folds' options=`options'" //DEBUG
  
  qui count `if' `in'
  if(`folds'<1 | `folds'>=`r(N)') {
    di as error "Invalid number of folds: `folds'. Must be between 2 and the number of active observations `r(N)'."
    exit 1
  }
  
  if(`folds'==1) {
    // special case: 1-fold is the same as just traing
    `estimator' `varlist' `if' `in', `options'
    predict `target'
    exit
  }
  
  if("`strata'" != "") {
    confirm variable `strata'
    di as error "cv: stratification not implemented."
    exit 2
  }
  
  
  /* generate folds */
  // the easiest way to do this in Stata is simply to mark a new column
  // and stamp out id numbers into it
  // the tricky part is dealing with if/in
  // and the trickier (and currently not implemented) part is dealing with
  // stratification (making sure each fold has equal proportions of a categorical variable)
  tempvar fold
    
  // compute the size of each group *as a float*
  // derivation:
  // we have r(N) items in total -- you can also think of this as the last item, which should get mapped to group `folds' 
  // we want `folds' groups
  // if we divide each _n by `folds' then the largest ID generated is r(N)/`folds' == # of items per group
  // so we can't do that
  // if instead we divide each _n by r(N)/`folds', then the largest is r(N)/(r(N)/`folds') = `folds'
  // Also, maybe clearer, this python script empirically proves the formula:
  /*
  for G in range(1,302):
      for N in range(G,1302):
          folds = {k: len(list(g)) for k,g in groupby(int((i-1)//(N/G)+1) for i in range(1,N+1)) }
          print("N =", N, "G =", G, "keys:", set(folds.keys()));
          assert set(folds.keys()) == set(range(1,G+1))
  */
  qui count `if' `in'
  local g =  `r(N)'/`folds'
    // generate a pseudo-_n which is the observation *within the if/in subset*
    // if you do not give if/in this is should be equal to _n
  qui gen int `fold' = 1 `if' `in'
  
  /* shuffling */
  // this is tricky: shuffling has to happen *after* partially generating fold IDs,
  // because the shuffle invalidates the `in', but it must happen *before* the IDs
  // are actually assigned because otherwise there's no point
  if("`shuffle'"!="") {
    tempvar original_order
    tempvar random_order
    qui gen `original_order' = _n
    qui gen `random_order' = uniform()
    sort `random_order'
  }
  
  qui replace `fold' = sum(`fold') if !missing(`fold') //egen has 'fill()' which is more complicated than this, and so does not allow if/in. None of its other options seem to be what I want.
  
  // map the pseudo-_n into a fold id number
  // nopromote causes integer instead of floating point division, which is needed for id numbers
  //Stata counts from 1, which is why the -1 and +1s are there
  // (because the proper computation should happen counting from 0, but nooo)
  qui replace `fold' = (`fold'-1)/`g'+1 if !missing(`fold'), nopromote

  // because shuffling can only affect which folds data ends up in,
  // immediately after generating fold labels we can put the data back as they were.
  // (i prefer rather do this early lest something later break and the dataset be mangled)
  // (this can't use snapshot or preserve because restoring those will erase `fold')
  if("`shuffle'"!="") {
    sort `original_order'
  }
  
  // make sure the trickery above worked, more or less
  qui sum `fold'
  assert `r(min)'==1
  assert `r(max)'==`folds'
  qui levelsof `fold'
  assert `: word count `r(levels)''==`folds'
  
  
  /* cross-predict */
  // We don't actually predict into target directly, because most estimation commands
  // get annoyed at you trying to overwrite an old variable (even if an unused region).
  // Instead we repeatedly predict into B, copy the fold into target, and destroy B.
  // 
  // We don't actually create `target' until we have done one fold, at which point we *clone* it
  // because we do not know what types/labels the predictor wants to attach to its predictions,
  // (which can lead to strangeness if the predictor is inconsistent with itself)
  tempvar B
  forvalues f = 1/`folds' {
    // train on everything that isn't the fold
    qui count if `fold' != `f'
    di "[fold `f'/`folds': training on `r(N)' observations]"
    capture `estimator' `varlist' if `fold' != `f', `options'
    if(_rc!=0) {
      di as error "`estimator' failed"
      exit _rc
    }
    
    // predict on the fold
    qui count if `fold' == `f'
    di "[fold `f'/`folds': predicting on `r(N)' observations]"
    predict `B' if `fold' == `f'
    
    // on the first fold, *clone* B to our real output
    if(`f' == 1) {
      qui clone `target' `B' if 0
    }
    
    // save the predictions from the current fold
    qui replace `target' = `B' if `fold' == `f'
    drop `B'
  }
  
  /* clean up */
  // drop e(), because its contents at this point are only valid for the last fold
  // and that's just confusing
  ereturn clear
end
