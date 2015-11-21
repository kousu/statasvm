// Setup
pause on
sysuse nlsw88, clear

// This dataset has labour data: employment conditions crossed with demographic information.
// If we separate by race, we can see that the support of the bivariate (wage, hours worked) differs.
// Roughly: the shape is the same for white and black respondents, but white respondents have a wider range.
drop if race == 3  //cut the small amount of respondents which answered "other"
twoway (scatter wage hours), by(race)
pause "Type q to continue."

// We will ask one-class SVM to detect the shape of the smaller region
// Notice that we need to further cull the data because SVM cannot handle missing data.
drop if missing(wage) | missing(hours) // for clarity, we 
svm wage hours if race == 2, type(one_class) sv(SV_wage_hours)

// There is a well balanced mix of support to non-support vectors
// (Remember that missings here are just observations that weren't in the training set)
tab SV_wage_hours

// Now, show whether each point "empirically" is in the distribution or not
predict S
twoway (scatter wage hours), by(S)
pause "Type q to continue."

// The result looks degenerate: all the 
// By jittering, we can see what happened: in the black respondents,
// the bulk have a strict 40 hours work week and low pay.
// one_class detects and reflects the huge weight at the center,
// culling the spread as irrelevant.
twoway (scatter wage hours, jitter(2)), by(S)
pause "Type q to continue."

// We can summarize how one_class handled the test and training sets
bysort race: tab S
// Notice that the percentage of matches in the training set is higher than in the test set,
// because the training extracted the distribution of the test set. Seeing this difference
// supports our intution that the distribution for white respondents differs from black.
