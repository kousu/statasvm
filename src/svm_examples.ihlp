{* This file was generated by scripts/examples2smcl.}{...}
{* It is included by the svmachines.sthlp file to embed the examples/ folder into the documentation.}{...}
{...}
    {title:Binary classification}

{pstd}Setup{p_end}
{phang2}{cmd:. sysuse auto}{p_end}

{pstd}
Machine-learning methods like SVM are very easy to overfit.  To compensate,
you must split data into training and testing sets, fit on the former,
and measure performance on the latter, so that performance measurements are
not artificially inflated by data they have already seen.{p_end}

{pstd}
After splitting, the proportion of classes can become unbalanced.  The
reliable way to handle this is a stratified split, which fixes the
proportions of each class in each partition of each class.  The
quick-and-dirty way is a shuffle,{p_end}
{phang2}{cmd:. set seed 9876}{p_end}
{phang2}{cmd:. generate u = runiform()}{p_end}
{phang2}{cmd:. sort u}{p_end}

{pstd}before the actual train and test split:{p_end}
{phang2}{cmd:. local split = floor(_N/2)}{p_end}
{phang2}{cmd:. local train = "1/`=`split'-1'"}{p_end}
{phang2}{cmd:. local test = "`split'/`=_N'"}{p_end}

{pstd}
Fit the classification model on the training set, with {cmd:verbose} enabled.
Training cannot handle missing data; here we omit it, but usually you should
impute.{p_end}
{phang2}{cmd:. svmachines foreign price-gear_ratio if !missing(rep78) in `train', verbose}{p_end}

{pstd}
Predict on the test set.  Unlike training, {cmd:predict} can handle missing
data it simply predicts missing.{p_end}
{phang2}{cmd:. predict P in `test'}{p_end}

{pstd}
Compute error rate: the percentage of mispredictions is the mean of {cmd:err}.{p_end}
{phang2}{cmd:. generate err = foreign != P in `test'}{p_end}
{phang2}{cmd:. summarize err in `test'}{p_end}

{pstd}{it:({stata svmachines_example svm_binary_classification:click to run})}{p_end}

    {title:Multiclass classification}

{pstd}Setup{p_end}
{phang2}{cmd:. use attitude_indicators}{p_end}

{pstd}Shuffle{p_end}
{phang2}{cmd:. set seed 4532}{p_end}
{phang2}{cmd:. generate u = runiform()}{p_end}
{phang2}{cmd:. sort u}{p_end}

{pstd}Train and test split{p_end}
{phang2}{cmd:. local split = floor(_N*3/4)}{p_end}
{phang2}{cmd:. local train = "1/`=`split'-1'"}{p_end}
{phang2}{cmd:. local test = "`split'/`=_N'"}{p_end}

{pstd}
In general, you need to do a grid search to find good tuning parameters.  These
values of {cmd:kernel()}, {cmd:gamma()}, and {cmd:coef0()} just happened to be good enough.{p_end}
{phang2}{cmd:. svmachines attitude q* in `train', kernel(poly) gamma(0.5) coef0(7)}{p_end}
{phang2}{cmd:. predict P in `test'}{p_end}

{pstd}Compute error rate.{p_end}
{phang2}{cmd:. generate err = attitude != P in `test'}{p_end}
{phang2}{cmd:. summarize err in `test'}{p_end}

{pstd}
An overly high percentage of SVs means overfitting{p_end}
{phang2}{cmd:. display "Percentage that are support vectors: `=round(100*e(N_SV)/e(N),.3)'"}{p_end}

{pstd}{it:({stata svmachines_example svm_multiclass_classification:click to run})}{p_end}

    {title:Class probability}

{pstd}Setup{p_end}
{phang2}{cmd:. use attitude_indicators}{p_end}

{pstd}Shuffle{p_end}
{phang2}{cmd:. set seed 12998}{p_end}
{phang2}{cmd:. generate u = runiform()}{p_end}
{phang2}{cmd:. sort u}{p_end}

{pstd}Train and test split{p_end}
{phang2}{cmd:. local split = floor(_N*3/4)}{p_end}
{phang2}{cmd:. local train = "1/`=`split'-1'"}{p_end}
{phang2}{cmd:. local test = "`split'/`=_N'"}{p_end}

{pstd}Model{p_end}
{phang2}{cmd:. svmachines attitude q* in `train', kernel(poly) gamma(0.5) coef0(7) prob}{p_end}
{phang2}{cmd:. predict P in `test', prob}{p_end}

{pstd}
The value in column {cmd:P} matches the column {cmd:P_}{it:<attitude>} with the
highest probability.{p_end}
{phang2}{cmd:. list attitude P* in `test'}{p_end}

{pstd}Compute error rate.{p_end}
{phang2}{cmd:. generate err = attitude != P in `test'}{p_end}
{phang2}{cmd:. summarize err in `test'}{p_end}

{pstd}
Beware: {cmd:predict, probability} is a different algorithm than
{cmd:predict} and can disagree about predictions.  This disagreement will
become absurd if combined with poor tuning.{p_end}
{phang2}{cmd:. predict P2 in `test'}{p_end}
{phang2}{cmd:. generate agree = P == P2 in `test'}{p_end}
{phang2}{cmd:. summarize agree in `test'}{p_end}

{pstd}{it:({stata svmachines_example svm_class_probability:click to run})}{p_end}

    {title:Regression}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse highschool}{p_end}

{pstd}Shuffle{p_end}
{phang2}{cmd:. set seed 793742}{p_end}
{phang2}{cmd:. generate u = runiform()}{p_end}
{phang2}{cmd:. sort u}{p_end}

{pstd}Train and test split{p_end}
{phang2}{cmd:. local split = floor(_N/2)}{p_end}
{phang2}{cmd:. local train = "1/`=`split'-1'"}{p_end}
{phang2}{cmd:. local test = "`split'/`=_N'"}{p_end}

{pstd}
Regression is invoked with {cmd:type(svr)} or {cmd:type(nu_svr)}.  Notice that
you can expand factors (categorical predictors) into sets of indicator
(Boolean and dummy) columns with standard {cmd:i.} syntax, and you can record
which observations were chosen as support vectors with {cmd:sv()}.{p_end}
{phang2}
{cmd:. svmachines weight height i.race i.sex in `train', type(svr) sv(Is_SV)}{p_end}

{pstd}
Examine which observations were SVs. Ideally, a small number of SVs are enough.{p_end}
{phang2}{cmd:. tab Is_SV in `train'}{p_end}

{phang2}{cmd:. predict P in `test'}{p_end}

{pstd}Compute residuals.{p_end}
{phang2}{cmd:. generate res = (weight - P) in `test'}{p_end}
{phang2}{cmd:. summarize res}{p_end}

{pstd}{it:({stata svmachines_example svm_regression:click to run})}{p_end}

