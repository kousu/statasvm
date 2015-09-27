// there's an off-by-one-ish bug in the new exporting SVs code, 
// this code triggers it
sysuse auto
drop make
order gear_ratio
svm * if !missing(rep78), sv(Is_SV) type(SVR)
// if the bug is there, you will see -->  _model2stata phase 3: warning: overflowed sv_indices before all rows filled. i=74, s=49, l=49
list Is_SV
tab gear_ratio Is_SV 
