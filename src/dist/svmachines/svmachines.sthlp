{smcl}
{* *! version 0.3.0  07Nov2018}{...}
{vieweralsosee "[R] regress" "mansection R regress"}{...}
{viewerjumpto "Syntax" "svmachines##syntax"}{...}
{viewerjumpto "Description" "svmachines##description"}{...}
{viewerjumpto "Installation" "svmachines##installation"}{...}
{viewerjumpto "Options" "svmachines##options"}{...}
{viewerjumpto "Stored results" "svmachines##results"}{...}
{viewerjumpto "Remarks" "svmachines##remarks"}{...}
{viewerjumpto "Examples" "svmachines##examples"}{...}
{viewerjumpto "Copyright" "svmachines##copyright"}{...}
{viewerjumpto "Authors" "svmachines##authors"}{...}
{viewerjumpto "References" "svmachines##references"}{...}
{...}{* NB: these hide the newlines }
{...}
{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:svmachines} {hline 2}}Support Vector Machines{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{help svmachines##svmachines:svmachines} {depvar} {indepvars} {ifin} [{cmd:,} {it:options}]

{p 8 16 2}
{help svmachines##svm:svmachines} {indepvars} {ifin}, type({help svmachines##one_class:one_class}) [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opth t:ype(svmachines##type:type)}}Type of model to fit: {opt svc}, {opt nu_svc}, {opt svr}, or {opt nu_svr}, or {opt one_class}. Default: {cmd:type(svc)}{p_end}
{synopt :{opth k:ernel(svmachines##kernel:kernel)}}SVM kernel function to use: {opt linear}, {opt poly}, {opt rbf}, {opt sigmoid}, or {opt precomputed}. Default: {cmd:kernel(rbf)}{p_end}

{* XXX the division between 'tuning' and 'model' parameters is hazy; e.g. you could in theory cross-validate to choose degree (and people do this with neural networks), or even to choose the kernel . hmmmmm}{...}
{syntab:Tuning}
{synopt :{opth c:(svmachines##c:#)}}For {opt svc}, {opt svr} and {opt nu_svr} SVMs, the weight on the margin of error. Should be > 0. Default: {cmd:c(1)}{p_end}
{synopt :{opth eps:ilon(svmachines##epsilon:#)}}For {opt svr} SVMs, the margin of error allowed within which observations will be support vectors. Default: {cmd:eps(0.1)}{p_end}
{synopt :{opth nu:(svmachines##nu:#)}}For {opt nu_svc}, {opt one_class}, and {opt nu_svr} SVMs, tunes the proportion of expected support vectors. Should be in (0, 1]. Default: {cmd:nu(0.5)}{p_end}

{synopt :{opth g:amma(svmachines##gamma:#)}}For {opt poly}, {opt rbf} and {opt sigmoid} kernels, a scaling factor for the linear part of the kernel. Default: {cmd:gamma(1/[# {indepvars}])}{p_end}
{synopt :{opth coef0:(svmachines##coef0:#)}}For {opt poly} and {opt sigmoid} kernels, a bias ("intercept") term for the linear part of the kernel. Default: {cmd:coef0(0)}{p_end}
{synopt :{opth deg:ree(svmachines##degree:#)}}For {opt poly} kernels, the degree of the polynomial to use. Default: cubic ({cmd:degree(3)}){p_end}

{synopt :{opt shrink:ing}}Whether to use {help svmachines##shrinking:shrinkage} heuristics to improve the fit. Default: disabled{p_end}


{syntab:Features}
{synopt :{opt prob:ability}}Whether to {help svmachines##probability:precompute} for "predict, prob" during estimation. Only applicable to classification problems. Default: disabled{p_end}
{synopt :{opth sv:(svmachines##sv:newvarname)}}If given, an indicator variable to generate to mark each row as a support vector or not. Default: disabled{p_end}
{synopt :{opt seed(int)}}Set the seed value. Default: {cmd:seed(1)} {p_end}
{* {synopt :{opt norm:alize}}Whether to {help svmachines##normalize:center and scale} the data. NOT IMPLEMENTED. Default: disabled{p_end} }

{syntab:Performance}
{synopt :{opth tol:erance(svmachines##tolerance:#)}}The stopping tolerance used to decide convergence. Default: {cmd:epsilon(0.001)}{p_end}
{synopt :{opt v:erbose}}Turns on {help svmachines##verbose:verbose mode}. Default: disabled{p_end}
{synopt :{opth cache:_size(svmachines##cache_size:#)}}The amount of RAM used to cache kernel values during fitting, in megabytes. Default: 100MB ({cmd:cache_size(100)}){p_end}

{synoptline}
{pstd}All variables must be numeric, including categorical variables.
If you have categories stored in strings use {help encode} before {cmd:svmachines}.
{p_end}
INCLUDE help fvvarlist



{p 8 16 2}
{help svmachines##predict:predict} {newvar} {ifin} [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt prob:ability}}If specified, estimate class probabilities for each observation. The fit must have been previously made with {opt probability}.{p_end}
{synopt :{opt scores}}If specified, output the scores, sometimes called decision values, that measure each observation's distance to its hyperplane. Incompatible with {opt probability}.{p_end}
{synopt :{opt v:erbose}}Turns on {help svmachines##verbose:verbose mode}. Default: disabled{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:svmachines} fits a support vector machine (SVM) model.
SVM is not one, but several, variant models each based upon the principles of
splitting hyperplanes and the culling of unimportant observations.

{pstd}
The basic SVM idea is to find a linear boundary---a hyperplane---in high-dimensional space:
for classification, this is a boundary between two classes;
for regression it is a line {help svmachines##epsilon:near} which points should be--much like in {help regess:OLS},
while simultaneously minimizing the number of observations required to distinguish
this hyperplane.
The unimportant observations are ignored after fitting is done, which makes SVM very memory efficient.

{pstd}
Each observation can be thought of as a vector,
so the {it:support vectors} are those observations which the algorithm deems critical to the fit.

{pstd}
This package is a thin wrapper for the widely deployed {help svmachines##libsvm:libsvm}.
The thinness of this wrapper is an intentional feature:
it means work done under Stata-SVM should be replicable with other libsvm wrappers such as
{browse "http://weka.wikispaces.com/LibSVM":Weka} or
{browse "http://scikit-learn.org/stable/modules/svm.html":sklearn}.
As a side-effect, some of the options are unfortunately terse.

{pstd}
See the {help svmachines##svmtutorial:libsvm SVM tutorial} for a gentle introduction to the method.
If you find this manual confusing, refer to the authoritative
the libsvm {browse "http://www.csie.ntu.edu.tw/~cjlin/libsvm/faq.html":FAQ},
{browse "https://github.com/cjlin1/libsvm/blob/master/README":README},
and {help svmachines##libsvm:implementation paper}.
Then please write us with your suggestions for clarification.

{pstd}
Please also feel free to {help svmachines##authors:send us} any other feature requests.

{marker installation}{...}
{title:Installation}

{pstd}
Since this is just a wrapper, {bf:libsvm must be installed} to use this package.
On Windows, libsvm.dll is bundled with the package,
and you can find it in your {help adopath} (try {cmd:findfile libsvm.dll} to verify this).
On OS X, libsvm is available in both {browse "https://brew.sh":brew} and {browse "https://www.macports.org":macports}.
On Linux, search for libsvm in your distribution's package manager.
You can also compile and install libsvm from source, 
if you cannot find it in your package manager or if you want the latest libsvm.
If you are having plugin load errors, please {help svmachines##authors:contact the authors},
as we want to make the experience as smooth as possible for our users across as many platforms as possible.


{marker options}{...}
{title:Options}

{marker svmachines}{...}
{dlgtab:svmachines}{* this is a misuse of dlgtab because I have no corresponding dialog, but it drastically helps readability }

{pstd}
{cmd:svmachines} fits an SVM model, fitting {depvar} to {indepvars} except under {opt type(one_class)} which only uses {indepvars}.

{pstd}
libsvm has several algorithms with a single entry point. Since this is a thin wrapper, so do we,
which means {it:not all combinations of options are valid}.
Usually libsvm will give an error if you specify an invalid combination,
but sometimes it just ignores parameters {it:without telling you}.
Further, amongst valid combinations, not all options and datasets give good results.
Our goal is to have sane defaults,
so that the only choice you usually need to make is what {help svmachines##type:type} and {help svmachines##kernel:kernel} to use,
but there is no way to give universal default parameters.

{pstd}
Rather than guessing at the {help svmachines##tuning_params:tuning parameters},
you should almost always use cross-validated grid-search to find them.
Which parameters you need to tune depend on which model you pick; for example,
for ({opt type(svc)}, opt{kernel(rbf)}) you only need to find ({opt c()}, {opt gamma()}).
You can grid-search on a subset of your full data, so long as it is a
representative sample, to quickly find approximations for the optimal parameters.
The {help svmachines##libsvmguide:libsvm guide} explains this in-depth.

{* MODEL PARAMS: }
{phang}
{marker type}{...}
{opt t:ype(type)} specifies which SVM model to run.{p_end}
{pmore}{opt svc} and {opt nu_svc} perform classification.{p_end}
{pmore2}{depvar} should be a variable containing categories.
Multiclass classification is automatically handled if necessary using
the {browse "http://en.wikipedia.org/wiki/Multiclass_classification":class-against-class} method.

{pmore2}
If you try to use floating point values with classification you
will find that they are truncated mercilessly to their integer parts,
so you may need to recode your categories before giving them to {cmd: svmachines}.
If you end up with almost as many classes as observations,
you have probably used a continuous {depvar} and
should use regression instead.{p_end}

{pmore}{opt svr} and {opt nu_svr} perform regression.{p_end}
{pmore2}{depvar} should be a variable containing continuous values.{p_end}
{pmore2}Rather than try to find a hyperplane which separates data as far as possible,
this tries to find a hyperplane to which most data is as near as possible.
See {help svmachines##svr_tutorial:the SVR tutorial} for more details.{p_end}

{marker one_class}{...}
{pmore}{opt one_class} separates outliers from the bulk of the data.{p_end}
{pmore2}{opt one_class} is a form of unsupervised learning.
It estimates the support of a distribution by distinguishing "class" from "outlier",
based only on the features given to it. Therefore, it does not take a {depvar}.
Its predictions give 1 for "class" and -1 for "outlier".{p_end}
{pmore3}{bf:Tip:} You may use the same {varlist} as with the other types.
 {opt one_class} just then interprets your {depvar} as one of its {indepvars},
 giving it more information to work with.{p_end}

{pmore}To learn about the {help svmachines##nu:nu} variants, see {help svmachines##nusvm:Chen and Lin's ν-SVM tutorial}.{p_end}

{pmore}{it:type} is case insensitive.{p_end}


{phang}
{marker kernel}{...}
{opt k:ernel(kernel)} gives a kernel function to use.

{pmore}
Much like {help glm:GLMs}, the {browse "https://en.wikipedia.org/wiki/Kernel_Method":kernel trick}
extends the linear SVM algorithm to be capable of fitting nonlinear data.
Kernels bend a non-linear space into a linear one by applying a high-dimensional mapping.
Under high enough dimensions, any set of data looks close to linear.
See {browse "https://www.youtube.com/watch?v=3liCbRZPrZA"} for a visualization of this process.
{p_end}
{pmore}
The "trick"---and the reason why the set of kernels is hardcoded---is that
for certain kernels the fit can be done efficiently without
actually constructing the high-dimensional points, as the estimation only cares
scoring coefficients u using the output of the kernel, not the output of the values the kernel
is, in theory, operating upon.{p_end}

{pmore}Kernels available in this implementation are:{p_end}
{pmore2}{opt linear}: the dot-product you are probably familiar with from {help regress:OLS}: u'*v{p_end}
{pmore2}{opt poly}: (gamma*u'*v + coef0)^degree. This extends the linear kernel with wiggliness.{p_end}
{pmore2}{opt rbf}: stands for Radial Basis Functions, and treats the coefficients
      as a mean to smoothly approach in a ball, with the form exp(-gamma*|u-v|^2);
	  this kernel tends to be a good generalist option for non-linear data.{p_end}
{pmore2}{opt sigmoid}: a kernel which bends the linear kernel to fit in -1 to 1
   with tanh(gamma*u'*v + coef0), similar to the {help logistic} non-linearity.{p_end}
{pmore2}{opt precomputed}: assumes that {depvar} is actually a list of precomputed kernel values.
 With effort, you can use this to use custom kernels with your data.{p_end}
{*  TODO: give a complete working example of using a custom kernel }{...}

{pmore}{it:kernel} is case insensitive.{p_end}


{* TUNING PARAMS: }
{phang}
{marker tuning_params}{...}
{marker c}{...}
{opt c(#)} weights (regularizes) the error term used in {opt svc}, {opt svr} and {opt nu_svr}.
Larger allows less error, but too large will lead to underfitting.

{phang}
{marker epsilon}{...}
{opt eps:ilon(#)} is the margin of error allowed by {opt svr}.
Larger makes your fit more able to incorporate more observations, but can lead to underfitting.
Smaller can lead to overfitting.

{phang}
{marker nu}{...}
{opt nu(#)} is used in the nu variants.
The nu variants are a reparamaterization of regular SVM which lets you directly tune,
using {opt nu}, the size of the svm margin, letting you control over- vs under-fitting.
{opt nu} is simultaneously a bound on the fraction of training errors and the
fraction of support vectors. Smaller {opt nu} means a smaller margin of error allowed -- so, a tigheter fit -- but more SVs required, and larger {opt nu} means a larger margin of error allowed and less SVs required.
See {help svmachines##nusvm:the ν-SVM tutorial} for details.
{* ..wait... this doesn't make any sense. nu == 0.1 means there are at most 10% (training) errors and at least 10% are support vectors.}{...}
{*      nu = 0.9 means there are at most 90% errors and at least 90% SVs.   you should always choose 0, then, to get perfect prediction and zero memory usage}{...}


{phang}
{marker gamma}{...}
{opt g:amma(#)} is used in the non-linear {opt poly}, {opt rbf} and {opt sigmoid}
kernels as a scaling factor for the linear part. Larger weights the data more.

{phang}
{marker coef0}{...}
{opt coef0(#)} similarly is used in the non-linear {opt poly} and {opt sigmoid}
kernels as a pseudo-intercept term.

{phang}
{marker degree}{...}
{opt deg:ree(#)} selects the degree of the polynomial used by the {opt poly} kernel.
This literally controls the degree of freedom in the {opt poly} fit:
setting this too low results in underfitting and sometimes even non-convergence (notice that at {opt degree(1)}, this is just the {opt linear} kernel);
setting this too high will result in overfitting.


{phang}
{marker shrinking}{...}
{opt shrink:ing} invokes the shrinkage heuristics,
which can sometimes improve the fit by trading bias for variance.

{* FEATURE PARAMS: }{...}
{* {marker normalize} }{...}
{* {phang} }{...}
{* {opt normalize} instructs the estimation to first center and scale the data }{...}
{* as SVM tends to be very sensitive to scaling issues. }{...}
{* This normalizes all data to [0,1] using min-max normalization, as suggested in the {help svmachines##libsvmguide:libsvm guide}. }{...}
{* Normalization creates temporary variables, so you may prefer to preprocess the data yourself---destructively and in-place---to save time on re-estimations and memory for variables, }{...}
{* especially if you are bumping up against your Stata system limits. You may find {cmd:ssc install center} helpful }{...}

{phang}
{marker probability}{...}
{opt prob:ability} enables the use of "{help svmachines##predict_prob:predict, prob}".
That does {browse "https://en.wikipedia.org/wiki/Platt_scaling":Platt scaling},
so for each class-against-class this precomputes a logistic regression 
which is tuned with 5-fold cross-validation.
Internally, libsvm shuffles the data before cross-validation using the OS random number generator,
which is unrelated to {help set seed:Stata's RNG}. The seed value for the OS random number generator is set using option {cmd:seed}. 
Enabling {cmd:prob} demands a great deal of additional CPU and RAM.

{phang}
{marker sv}{...}
{opt sv(newvarname)} records in the given variable a boolean indicating whether each observation was determined to be a support vector.

{phang}
{opt seed(#)} sets the seed value for the OS random number generator. It is not related to the Stata seed.
The seed only affects the results when the {cmd:prob} option is specified. Specifying this seed and the Stata seed enables reproducible results.

{* PERFORMANCE PARAMS: }
{phang}
{marker tolerance}{...}
{opt tol:erance(#)} is the stopping tolerance used by the numerical optimizer. You could widen this if you are finding convergence is slow,
 but be aware that this usually non-convergence is a deeper problem.
 You could also tighten this if you have a powerful enough machine and want to get slightly more accurate estimates.
 
{phang}
{marker verbose}{...}
{opt v:erbose} enables output from the low level libsvm code for the duration of the operation.

{phang}
{marker cache_size}{...}
{opt cache:_size(#)} controls a time-memory tradeoff during estimation.
Value is how many megabytes (MB) of RAM to set aside for caching kernel values
Generally, more is faster, at least until you run out of RAM or cause your machine to start swapping.
On modern machines, a reasonable choice is {opt cache_size(1024)}.

{...}
{...}

{marker predict}{...}
{dlgtab:predict}

{pstd}After training you can ask svm to {cmd:predict} what the category (classification) or outcome value (regression)
      should be for each given observation. Results are placed into {newvar}.{p_end}
{pstd}{newvar} must not exist, so if you want to repredict your choices are {cmd:drop {newvar}} or to pick a new name, e.g. {cmd:predict {newvar}2}.{p_end}

{marker predict_prob}{...}
{phang}For classification ({opt svc}, {opt nu_svc}) problems, {opt probability} requests, for each observation, the probability of it being each class.
{newvar} is used as a stem for the new columns.
Both probabilities are computed with Platt Scaling.  When enabled, so are predictions, and this algorithm is not guaranteed to give the same results
as otherwise. The results should be sensible either way, so if you are getting inconsistent results between the two algorithms,
investigate the {help svmachines##tuning_params:tuning} parameters.
This option is not valid for other SVM types.{p_end}

{phang}
{marker scores}{...}
{opt scores} outputs the values that {cmd:svmachines} uses to decide on which
side of the hyperplane a particular observation falls.  {newvar} is used as a
stem for the new columns.  For {cmd:type(one_class)} and regressions, there is
only one score.  For classifications, there is one score for every pair of
classes (this is expensive: k classes means k(k-1)/2 new columns!), because
{cmd:libsvm} aggregates the basic binary-only {cmd:svmachines} algorithm into
a multiclass algorithm with the one-against-one technique.  This option is
incompatible with {opt probability} because, once trained, the Platt scaling
algorithm does not directly compute scores. 

{phang2}
Bug: The score has the wrong sign unless y-values are coded as -1 and 1. For example, 
if y is coded as 0 and 1, or 10 and 20, the sign of the score should be reversed.

{phang}
{opt verbose}; see {helpb svmachines##verbose:svmachines, verbose}.

{pstd}
Prediction implicitly uses the same {indepvars} as during estimation, so be
careful about renaming or dropping variables.

{...}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:svmachines} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{* Note: svm_model components left unexposed: }{...}
{*      - probA, probB, the coefficients used for predict, prob; these are not, by themselves, interesting }{...}
{*      - label, the "labels" of the classes (which are the integers libsvm casts out of the initial dataset; exported with strLabels to be used for labelling rho and sv_coef, but otherwise not directly interesting and  }{...}
{*      - nSV, the number of SVs per class; this is only interesting for classifications, and it duplicates what you can get out of "tab `e(depvar)' SV" }{...}
{*      - free_sv, internal libsvm flag which is a hack to stretch svm_model to handle creation from both svm_train() and svm_import() }{...}
{*      }{...}
{*      - SV[] and sv_indices[] are exposed indirectly with the sv() option }{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_class)}}number of classes, in a classification problem. {opt 2} in a regression problem.{p_end}
{synopt:{cmd:e(N_SV)}}number of support vectors.
If {opt e(N_SV)}/{opt e(N)} is close to 100% your fit is inefficient; perhaps you need to adjust your {help svmachines##kernel:kernel}.
{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}"{cmd:svmachines}"{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(model)}}"{cmd:svmachines}"{p_end}
{synopt:{cmd:e(svm_type)}}SVM type string, as above{p_end}
{synopt:{cmd:e(svm_kernel)}}kernel string, as above{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}
{synopt:{cmd:e(levels)}}list of the classes detected, in the order they were detected. Only defined for {opt type(svc)} and {opt type(nu_svc)}.{p_end}
{* {synopt:{cmd:e(estat_cmd)}}program used to implement {cmd:estat}{p_end} }{...}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}({help svmachines##remarks:may be missing}){p_end}
{synopt:{cmd:e(sv_coef)}}The coefficients of the support vectors for each fitted hyperplane in the {bf:dual} quadratic programming problem.{p_end}
{* TODO: is there a clearer explanation of sv_coef? Is it worth including? }{...}
{synopt:{cmd:e(rho)}}The intercept term for each fitted hyperplane. It is lower-triangular and {cmd:e(N_class)}^2 large, with each entry [i,j] representing the hyperplane between class i and class j.{p_end}


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Memory Limits}: The cheaper versions of Stata allow only allow fewer variables and smaller matrices to be used.
As machine learning problems typically are on very large datasets,
it is easy to inadvertently instruct this package to construct more columns or larger matrices than you can afford.
If you overflow {help maxvar}, you will receive an error, the operation will fail, and the dataset will be left untouched.
If you overflow {help matsize}, the matrix that overflowed will be missing, but operation will otherwise succeed.

{pmore}
If Stata's memory limits are an impossible hurdle,
your best option is to give up on Stata and switching to libsvm's companion {cmd:svm-train} program.
This will have been installed with the libsvm package if you used a package manager, or
you can get it {browse "http://www.csie.ntu.edu.tw/~cjlin/cgi-bin/libsvm.cgi?+http://www.csie.ntu.edu.tw/~cjlin/libsvm+zip":from its authors};
You can use {help svmlight:export_svmlight} to extract your dataset for use with {cmd:svm-train}.

{marker examples}{...}
{title:Examples}

INCLUDE help svm_examples

{marker copyright}{...}
{title:Copyright}

{pstd}
The wrapper is licensed:

{pmore}
The MIT License (MIT)

{pmore}
Except where otherwise noted in the code, Copyright (c) 2015
Nick Guenther <nguenthe@uwaterloo.ca>, Matthias Schonlau <schonlau@uwaterloo.ca>

{pmore}
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

{pmore}
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

{pmore}
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


{pstd}
libsvm is licensed:

{pmore}
Copyright (c) 2000-2014 Chih-Chung Chang and Chih-Jen Lin
All rights reserved.

{pmore}
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

{pmore}
1. Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

{pmore}
2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

{pmore}
3. Neither name of copyright holders nor the names of its contributors
may be used to endorse or promote products derived from this software
without specific prior written permission.

{pmore}
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


{marker authors}{...}
{title:Authors}

{pstd}
Though the license does not obligate you in any way to do so, if you find
this software useful we would be curious and appreciative to hear about your
adventures in machine learning with Stata.{p_end}
{pmore}Thank you.

{pstd}You can contact us at{p_end}
{pmore}* Nick Guenther <nguenthe@uwaterloo.ca>{p_end}
{pmore}* Matthias Schonlau <schonlau@uwaterloo.ca>{p_end}


{marker references}{...}
{title:References}

{marker svmtutorial}{...}
{phang}
Bennett, Kristin P., and Colin Campbell. 2000.
{it:Support Vector Machines: Hype or Hallelujah?}
SIGKDD Explor. Newsl. 2.2: 1–13.
{browse "http://www.svms.org/tutorials/BennettCampbell2000.pdf"}.
{p_end}

{marker libsvm}{...}
{phang}
Chang, Chih-Chung and Lin, Chih-Jen. 2011.
{it:LIBSVM: a library for support vector machines.}
ACM Transactions on Intelligent Systems and Technology, 2:27:1--27:27.
{browse "http://www.csie.ntu.edu.tw/~cjlin/papers/libsvm.pdf"}.
Software available at {browse "http://www.csie.ntu.edu.tw/~cjlin/libsvm"}
{p_end}

{marker libsvmguide}{...}
{phang}
Hsu, Chih-Wei, Chang, Chih-Chung, and Lin, Chih-Jen. April 15, 2010.
{it:A Practical Guide to Support Vector Classification}.
{browse "http://www.csie.ntu.edu.tw/~cjlin/papers/guide/guide.pdf"}.
{p_end}

{marker svr_tutorial}{...}
{phang}
Smola, Alex J., and Schölkopf, Bernhard. 2004.
{it:A tutorial on support vector regression}.
Statistics and Computing 14.3: 199–222.
{* This one is behind a paywall, so the best we can do is a give a DOI link }{...}
{browse "http://dx.doi.org/10.1023/b:stco.0000035301.49549.88"}.
{p_end}

{marker nusvm}{...}
{phang}
Chen, Pai-Hsuen, Lin Chih-Jen, and Schölkopf, Bernhard. 2005.
{it:A Tutorial on ν-Support Vector Machines}.
Applied Stochastic Models in Business and Industry 21.2: 111–136.
{browse "http://www.csie.ntu.edu.tw/~cjlin/papers/nusvmtutorial.pdf"}.
{p_end}


