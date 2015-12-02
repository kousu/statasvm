{title:Examples: binary classification}

{pstd}Setup{p_end}
{phang2}{cmd:. sysuse auto}{p_end}

{pstd}Machine learning methods like SVM are very easy to overfit.{p_end}
{pstd}To compensate, it is important to split data into training and testing sets, fit on{p_end}
{pstd}the former and measure performance on the latter, so that performance measurements{p_end}
{pstd}are not artificially inflated by data they've already seen.{p_end}

{pstd}But after splitting the proportion of classes can become unbalanced.{p_end}
{pstd}The reliable way to handle this is a stratified split, a split that{p_end}
{pstd}fixes the proportions of each class in each partition of each class.{p_end}
{pstd}The quick and dirty way is a shuffle:{p_end}
{phang2}{cmd:. set seed 9876}{p_end}
{phang2}{cmd:. gen u = uniform()}{p_end}
{phang2}{cmd:. sort u}{p_end}

{pstd}before the actual train/test split:{p_end}
{phang2}{cmd:. local split = floor(_N/2)}{p_end}
{phang2}{cmd:. local train = "1/`=`split'-1'"}{p_end}
{phang2}{cmd:. local test = "`split'/`=_N'"}{p_end}

{pstd}Fit the classification model on the training set, with 'verbose' enabled.{p_end}
{pstd}Training cannot handle missing data; here we elide it, but usually you should impute.{p_end}
{phang2}{cmd:. svmachines foreign price-gear_ratio if !missing(rep78) in `train', v}{p_end}

{pstd}Predict on the test set.{p_end}
{pstd}Unlike training, predict can handle missing data: it simply predicts missing.{p_end}
{phang2}{cmd:. predict P in `test'}{p_end}

{pstd}Compute error rate: the percentage of mispredictions is the mean of err.{p_end}
{phang2}{cmd:. gen err = foreign != P in `test'}{p_end}
{phang2}{cmd:. sum err in `test'}{p_end}

{pstd}{it:({stata svmachines_example binary_classification:click to run})}{p_end}

{title:Examples: multiclass classification}

{pstd}Setup{p_end}
{phang2}{cmd:. use attitude_indicators}{p_end}

{pstd}Shuffle{p_end}
{phang2}{cmd:. set seed 4532}{p_end}
{phang2}{cmd:. gen u = uniform()}{p_end}
{phang2}{cmd:. sort u}{p_end}

{pstd}Train/test split{p_end}
{phang2}{cmd:. local split = floor(_N*3/4)}{p_end}
{phang2}{cmd:. local train = "1/`=`split'-1'"}{p_end}
{phang2}{cmd:. local test = "`split'/`=_N'"}{p_end}

{pstd}In general, you need to do grid-search to find good tuning parameters.{p_end}
{pstd}These values of kernel, gamma, and coef0 just happened to be good enough.{p_end}
{phang2}{cmd:. svmachines attitude q* in `train', kernel(poly) gamma(0.5) coef0(7)}{p_end}

{phang2}{cmd:. predict P in `test'}{p_end}

{pstd}Compute error rate.{p_end}
{phang2}{cmd:. gen err = attitude != P in `test'}{p_end}
{phang2}{cmd:. sum err in `test'}{p_end}

{pstd}An overly high percentage of SVs means overfitting{p_end}
{phang2}{cmd:. di "Percentage that are support vectors: `=round(100*e(N_SV)/e(N),.3)'"}{p_end}

{pstd}{it:({stata svmachines_example multiclass_classification:click to run})}{p_end}

{title:Examples: class probability}

{pstd}Setup{p_end}
{phang2}{cmd:. use attitude_indicators}{p_end}

{pstd}Shuffle{p_end}
{phang2}{cmd:. set seed 12998}{p_end}
{phang2}{cmd:. gen u = uniform()}{p_end}
{phang2}{cmd:. sort u}{p_end}

{pstd}Train/test split{p_end}
{phang2}{cmd:. local split = floor(_N*3/4)}{p_end}
{phang2}{cmd:. local train = "1/`=`split'-1'"}{p_end}
{phang2}{cmd:. local test = "`split'/`=_N'"}{p_end}

{pstd}Model{p_end}
{phang2}{cmd:. svmachines attitude q* in `train', kernel(poly) gamma(0.5) coef0(7) prob}{p_end}
{phang2}{cmd:. predict P in `test', prob}{p_end}

{pstd}the value in column P matches the column P_<attitude> with the highest probability{p_end}
{phang2}{cmd:. list attitude P* in `test'}{p_end}

{pstd}Compute error rate.{p_end}
{phang2}{cmd:. gen err = attitude != P in `test'}{p_end}
{phang2}{cmd:. sum err in `test'}{p_end}

{pstd}Beware:{p_end}
{pstd}predict, prob is a *different algorithm* than predict, and can disagree about predictions.{p_end}
{pstd}This disagreement will become absurd if combined with poor tuning.{p_end}
{phang2}{cmd:. predict P2 in `test'}{p_end}
{phang2}{cmd:. gen agree = P == P2 in `test'}{p_end}
{phang2}{cmd:. sum agree in `test'}{p_end}

{pstd}{it:({stata svmachines_example class_probability:click to run})}{p_end}

{title:Examples: regression}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse highschool}{p_end}

{pstd}Shuffle{p_end}
{phang2}{cmd:. set seed 793742}{p_end}
{phang2}{cmd:. gen u = uniform()}{p_end}
{phang2}{cmd:. sort u}{p_end}

{pstd}Train/test split{p_end}
{phang2}{cmd:. local split = floor(_N/2)}{p_end}
{phang2}{cmd:. local train = "1/`=`split'-1'"}{p_end}
{phang2}{cmd:. local test = "`split'/`=_N'"}{p_end}

{pstd}Regression is invoked with type(svr) or type(nu_svr).{p_end}
{pstd}Notice that you can expand factors (categorical predictors) into sets of{p_end}
{pstd}indicator (boolean/dummy) columns with standard i. syntax, and you can{p_end}
{pstd}record which observations were chosen as support vectors with sv().{p_end}
{phang2}{cmd:. svmachines weight height i.race i.sex in `train', type(svr) sv(Is_SV)}{p_end}

{pstd}Examine which observations were SVs. Ideally, a small number of SVs are enough.{p_end}
{phang2}{cmd:. tab Is_SV in `train'}{p_end}

{phang2}{cmd:. predict P in `test'}{p_end}

{pstd}Compute residuals.{p_end}
{phang2}{cmd:. gen res = (weight - P) in `test'}{p_end}
{phang2}{cmd:. sum res}{p_end}

{pstd}{it:({stata svmachines_example regression:click to run})}{p_end}

{title:Examples: oneclass}

{pstd}Setup{p_end}
{phang2}{cmd:. pause on}{p_end}
{phang2}{cmd:. sysuse nlsw88, clear}{p_end}

{pstd}This dataset has labour data: employment conditions crossed with demographic information.{p_end}
{pstd}(for clarity, we cut out distracting observations: the small amount of respondents which answered "other" and the few rows with missing data that svm cannot tolerate){p_end}
{pstd}(in a real analysis you should handle your missing data more thoughtfully){p_end}
{phang2}{cmd:. drop if race == 3}{p_end}
{phang2}{cmd:. drop if missing(wage)}{p_end}
{phang2}{cmd:. drop if missing(hours)}{p_end}

{pstd}If we separate by race, we can see that the support of the bivariate (wage, hours worked) differs.{p_end}
{pstd}A first guess: the shape is the same for white and black respondents, but white respondents have a wider range.{p_end}
{phang2}{cmd:. twoway (scatter wage hours), by(race)}{p_end}
{phang2}{cmd:. pause "Type q to continue."}{p_end}

{pstd}We will now ask one-class SVM to detect the shape of that less varied region,{p_end}
{pstd}to give us a sense of the black labour market in 1988.{p_end}
{phang2}{cmd:. svmachines wage hours if race == 2, type(one_class) sv(SV_wage_hours)}{p_end}

{pstd}There is a well balanced mix of support to non-support vectors. This is a good sign.{p_end}
{phang2}{cmd:. tab SV_wage_hours}{p_end}

{pstd}Now, plot whether each point "empirically" is in the distribution or not{p_end}
{pstd}to demonstrate the detected distribution{p_end}
{pstd}(you could also construct an evenly spaced grid of test points to get better resolution){p_end}
{phang2}{cmd:. predict S}{p_end}
{phang2}{cmd:. twoway (scatter wage hours if !S) ///}{p_end}
{phang2}{cmd:.        (scatter wage hours if S), ///}{p_end}
{phang2}{cmd:.        title("SVM Estimated Labour Distribution") ///}{p_end}
{phang2}{cmd:.        legend(label(1 "Outliers") label(2 "Within Support"))}{p_end}
{phang2}{cmd:. pause "Type q to continue."}{p_end}

{pstd}The result looks degenerate: the entire predicted distribution is along the line hours=40.{p_end}
{pstd}By jittering, we can see why this happened: in the black respondents,{p_end}
{pstd}the bulk have a strict 40 hours work week and low pay.{p_end}
{pstd}one_class detects and reflects the huge weight at the center,{p_end}
{pstd}culling the spread as irrelevant.{p_end}
{phang2}{cmd:. twoway (scatter wage hours if !S, jitter(5)) ///}{p_end}
{phang2}{cmd:.        (scatter wage hours if S, jitter(5)), ///}{p_end}
{phang2}{cmd:.        title("SVM Estimated Labour Distribution, fuzzed") ///}{p_end}
{phang2}{cmd:.        legend(label(1 "Outliers") label(2 "Within Support"))}{p_end}
{phang2}{cmd:. pause "Type q to continue."}{p_end}

{pstd}We can summarize how one_class handled both sets test and training sets{p_end}
{phang2}{cmd:. tab S race, col}{p_end}
{pstd}Notice that the percentage of matches in the training set is higher than in the test set,{p_end}
{pstd}because the training extracted the distribution of the test set. Seeing this difference{p_end}
{pstd}supports our intution that the distribution for white respondents differs from black.{p_end}

{pstd}{it:({stata svmachines_example oneclass:click to run})}{p_end}

