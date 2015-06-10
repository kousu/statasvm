* inspect_model.do
* Inspect fitted model state, as known to Stata
* NOTE: this is autoincluded to all tests via makefile magic; hence,
* it is wrapped to silence errors on tests which don't make a struct svm_model
* AND *each line* is wrapped so that their errors are independent of the others, just as a defensive measure
* BUT as an output optimization, we assume that if nSV is not defined, we can skip trying the rest

* These two should usually be empty, except for preload which of course has to use scalars to communicate
capture noisily scalar list
capture noisily matrix dir   /* unlike 'scalar list', 'matrix list' shows a *single* matrix and 'dir' shows all */

capture matrix list e(rho) /*I can't figure out a better to test if a variable is defined than to try to access it and see if it crashes */
if(_rc==0) {  
  capture noisily ereturn list /* because of Stata's single-global-return-list design, the only time we can access this data is immediately after a svm_train or svm_import */
  capture noisily matrix list e(sv_coef)
  capture noisily matrix list e(rho)
}

