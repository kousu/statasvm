* Inspect fitted model state, as known to Stata
ereturn list /* because of Stata's single-global-return-list design, the only time we can access this data is immediately after a svm_train or svm_import */
matrix dir /*'matrix list' is for a specific; you need 'dir' to see all defined ones, unlike how 'scalar list' and 'list' work*/
capture noisily matrix list SVs   /*this is not defined under svm_import, at least, not as written */
matrix list nSV
matrix list labels
matrix list sv_coef
matrix list rho
capture noisily matrix list probA /*not always defined*/
capture noisily matrix list probB /*ditto*/
