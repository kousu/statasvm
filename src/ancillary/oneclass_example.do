// Setup
pause on
sysuse nlsw88, clear

// This dataset has labour data: employment conditions crossed with demographic information.
// (for clarity, we cut out distracting observations: the small amount of respondents which answered "other" and the few rows with missing data that svm cannot tolerate)
// (in a real analysis you should handle your missing data more thoughtfully)
drop if race == 3
drop if missing(wage)
drop if missing(hours)

// If we separate by race, we can see that the support of the bivariate (wage, hours worked) differs.
// A first guess: the shape is the same for white and black respondents, but white respondents have a wider range.
twoway (scatter wage hours), by(race)
pause "Type q to continue."

// We will now ask one-class SVM to detect the shape of that less varied region,
// to give us a sense of the black labour market in 1988.
svmachines wage hours if race == 2, type(one_class) sv(SV_wage_hours)

// There is a well balanced mix of support to non-support vectors. This is a good sign.
tab SV_wage_hours

// Now, plot whether each point "empirically" is in the distribution or not
// to demonstrate the detected distribution
// (you could also construct an evenly spaced grid of test points to get better resolution)
predict S
twoway (scatter wage hours if !S) ///
       (scatter wage hours if S), ///
       title("SVM Estimated Labour Distribution") ///
       legend(label(1 "Outliers") label(2 "Within Support"))
pause "Type q to continue."

// The result looks degenerate: the entire predicted distribution is along the line hours=40.
// By jittering, we can see why this happened: in the black respondents,
// the bulk have a strict 40 hours work week and low pay.
// one_class detects and reflects the huge weight at the center,
// culling the spread as irrelevant.
twoway (scatter wage hours if !S, jitter(5)) ///
       (scatter wage hours if S, jitter(5)), ///
       title("SVM Estimated Labour Distribution, fuzzed") ///
       legend(label(1 "Outliers") label(2 "Within Support"))
pause "Type q to continue."

// We can summarize how one_class handled both sets test and training sets
tab S race, col
// Notice that the percentage of matches in the training set is higher than in the test set,
// because the training extracted the distribution of the test set. Seeing this difference
// supports our intution that the distribution for white respondents differs from black.
