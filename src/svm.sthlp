{smcl}
{* *! version 0.0.1  28may2015}{...}
{vieweralsosee "[R] regress" "mansection R regress"}{...}
{viewerjumpto "Syntax" "svm##syntax"}{...}
{viewerjumpto "Description" "svm##description"}{...}
{viewerjumpto "Options" "svm##options"}{...}
{viewerjumpto "Examples" "svm##examples"}{...}
{viewerjumpto "Stored results" "svm##results"}{...}
{viewerjumpto "Gotchas" "svm##gotchas"}{...}
{viewerjumpto "Copyright" "svm##copyright"}{...}
{viewerjumpto "Exeunt" "svm##exeunt"}{...}
{viewerjumpto "References" "svm##references"}{...}
{...}{* NB: these hide the newlines }
{...}
{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:svm} {hline 2}}Support Vector Machines{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
svm {depvar} [{indepvars}] {ifin} [{it:{help svm##weight:weight}}] [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{cmdab:t:ype}}Type of model to fit: C_SVC, NU_SVC, ONE_CLASS, EPSILON_SVR, or NU_SVR. Default: C_SVC{p_end}
{synopt :{cmdab:k:ernel}}SVM kernel function to use: LINEAR, POLY, RBF, SIGMOID, or PRECOMPUTED. Default: RBF{p_end}

{synopt :{cmdab:gamma:}}For POLY, RBF and SIGMOID kernels, a scaling factor for the linear part. Default: 1/[# variables TODO: what's Stata's hidden macro for this?]{p_end}
{synopt :{cmdab:coef0:}}For POLY and SIGMOID kernels, an intercept term for the linear part. Default: 0{p_end}
{synopt :{cmdab:deg:ree}}For POLY kernels, the degree of the polynomial to use. Default: cubic (3){p_end}

{* XXX the division between 'tuning' and 'model' parameters is hazy; e.g. you could in theory cross-validate to choose degree (and people do this with neural networks), or even to choose the kernel . hmmmmm}{...}

{syntab:Tuning}
{synopt :{cmdab:C:}}For C_SVC, EPSILON_SVR and NU_SVR SVMs, this is a regularization parameter which weights the slack variables [citation needed]. Default: 1{p_end}
{synopt :{cmdab:p:}}For EPSILON_SVR SVMs, this provides the error tolerance boundary [citation needed]. Default: 0.1{p_end}
{synopt :{cmdab:nu:}}For NU_SVC, ONE_CLASS, and NU_SVR SVMs, .... Default: 0.5{p_end}

{synopt :{cmdab:eps:ilon}}The stopping tolerance used to decide when convergence has happened. Default: 0.001{p_end}
{synopt :{cmdab:shrink:ing}}Whether or not to use shrinkage heuristics (regularization??) to improve the fit. Default: disabled{p_end}
{synopt :{cmdab:autonorm:alize}}Whether to center and scale the data. NOT IMPLEMENTED. Default: disabled{p_end}


{syntab:Performance}
{synopt :{cmdab:prob:ability}}Whether or not to compute extra data needed for "predict, prob". Disable with "noprobability". Default: enabled{p_end}
{synopt :{cmdab:cache:_size}}The size of the RAM cache used during fitting, in megabytes. Default: 100MB (100){p_end}
{synopt :{cmdab:SVs:}}Whether or not to return the SVs matrix. NOT IMPLEMENTED. Disable with "noSVs". Default: enabled{p_end}
{synopt :{cmdab:nSVs:}}Whether or not to return the nSVs matrix. NOT IMPLEMENTED. Disable with "nonSVs". Default: enabled{p_end}
{synopt :{cmdab:labels:}}Whether or not to return the labels matrix. NOT IMPLEMENTED. Disable with "nolabels". Default: enabled{p_end}
{synopt :{cmdab:sv_coef:}}Whether or not to return the sv_coef matrix. NOT IMPLEMENTED. Disable with "nosvcoef". Default: enabled{p_end}
{synopt :{cmdab:rho:}}Whether or not to return the rho matrix. NOT IMPLEMENTED. Disable with "norho". Default: enabled{p_end}
{* NB: there's no probA or probB options because those are just cruft in support of "predict, prob"... I think. }{...}

{synoptline}
{pstd}All variables must be numeric (Stata stores categoricals as numerics); use {help encode} to map string variables to classes.{p_end}
INCLUDE help fvvarlist


{p 8 16 2}
predict {targetvar} {ifin}, [{cmdab:prob:ability}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{cmdab:prob:ability}}If specified, estimate class probabilities for each observation. This only makes sense for classification problems.{p_end}


{p 8 16 2}
svm_export using {filename}

{p 8 16 2}
svm_import using {filename}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{cmd: using}}The filename to export or import a fitted libsvm model from, conventionally ending in '.model'.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:svm} fits a support vector machine (SVM) model of {depvar} on {indepvars}.
SVM is not one, but several variant models, all based upon splitting hyperplanes and culling unimportant observations.
The name comes part from how each observation in a dataset can be thought of as a vector in d-dimensional space, where d is the number of {indepvars}
and part from the culling: the "support vectors" are those observations which the algorithm detects are critical to the fit.

{pstd}
Not all combinations of options are valid, and you will get an error if you specify an invalid combination.
And amongst valid combinations, not all options and datasets will give good results.
The most important choice you need to make when fitting is what type and what kernel to use. Our goal is to have sane defaults, so that the other options are very very optional, only brought out for difficult datasets.
See {help svm##svmtutorial} for a gentle introduction and coverage of the specification issues involved in using SVM.

{pstd}
This package is a thin wrapper for the widely deployed {help svm##libsvm:libsvm},
so in addition to the Stata package, libsvm must be installed.
On Windows, libsvm.dll should have been bundled with the package,
and you can find it in your {help adopath} (try {cmd:findfile libsvm.dll} to verify this).
On OS X, libsvm is available in both {browse "https://brew.sh":brew} and {browse "https://www.macports.org":macports}.
On Linux, search for libsvm in your distribution's package manager.
You can also install libsvm from source, which you would need to do if your package manager has an older or no version of libsvm.
If you are having trouble getting the plugin loaded, please contact the authors,
as we do not have access to all combinations of operating systems and we want to make the experience as smooth as possible for our users.
The thinness is a feature, to keep things simple and portable between statistical systems;
if you have feature requests send them to us but know that we will probably not implement them until we get them built into libsvm so that everyone can benefit.

{pstd}
If you are confused by the options, refer to the authoratative source:
the libsvm {browse "http://www.csie.ntu.edu.tw/~cjlin/libsvm/faq.html":FAQ},
{browse "https://github.com/cjlin1/libsvm/blob/master/README":README},
and {help svm##libsvm:implementation paper}.
Please write us with suggestions for clarification.

{marker options}{...}
{title:Options}

{title:svm}

{pstd}
{cmd:svm} does model training, otherwise known as fitting or estimation (depending on your statistical background).

{phang}
{opt type} specifies what subtype of SVM to run.
C_SVC and NU_SVC perform classification, and your {depvar} should be a discrete variable, probably stored as byte or int.
You can tell if you have made this mistake if there is a unique class for each observation.
libsvm automatically handles multiclass classification using the one-against-all [citation needed].
ONE_CLASS ignores {depvar} (????) and estimates the support---where in feature space---the data lies [......].
EPSILON_SVR and NU_SVR perform regression. You can use this with discrete variables, but more commonly you would use it with continuous ones stored as float or double.
To learn about the NU distinction, see {help svm##nusvm:Chen and Lin's ν-SVM tutorial}.

{phang}
{opt kernel} gives a kernel function to use.
The basic SVM algorithm finds a linear boundary (a hyperplane), between two classes [XXX how does this apply to SVR?].
The {browse "https://en.wikipedia.org/wiki/Kernel_Method":kernel trick} attempts to make data linearly-separable by mapping it into a higher dimensional space.
Additionally, it can handle curved boundaries by effectively bending the lower dimensional space. See {browse "https://www.youtube.com/watch?v=3liCbRZPrZA"} for a visualization of this process.
The trick is that the fit can be done efficiently because the fit does not care about the points under the mapping, 
but rather cares about their kernel value <u,x>, a value used in scoring the coefficients u,
and for certain kernels this value can be computed straight from the original data without doing the mapping at all.{p_end}

{pmore}Choices of kernels are:{p_end}
{pmore2}LINEAR means the linear kernel you are probably familiar with from {help regress:OLS}: u'*v{p_end}
{pmore2}POLY is (gamma*u'*v + coef0)^degree{p_end}
{pmore2}RBF stands for Radial Basis Functions, and treats the coefficients as a mean to smoothly approach in a ball, with the form exp(-gamma*|u-v|^2); this kernel tends to be good at [...].{p_end}
{pmore2}SIGMOID is a kernel which bends the linear kernel to fit in -1 to 1, similar to {help logistic} regression: tanh(gamma*u'*v + coef0){p_end}
{pmore2}PRECOMPUTED assumes that {depvar} is actually a list of precomputed kernel values.{p_end}

{phang}
{opt gamma} is used in the non-linear kernels as a scaling factor for the linear part, as seen above.
[TODO: tips about choosing this]

{phang}
Similarly, {opt coef0} is used in the non-linear kernels as a pseudo-intercept term.
Except it is not used in the RBF kernel as RBF is essentially a distance function, and biasing would be pointless.[???]
[TODO: tips about choosing this]

{phang}
{opt degree} selects the degree of the polynomial used by the POLY kernel.
Setting this too high will result in overfitting. Setting it too low may result in non-convergence.
[TODO: tips about choosing this]

{phang}
{opt C} weights (regularizes) the slack variables used in C_SVC, EPSILON_SVR and NU_SVR
[TODO: tips about choosing this]

{phang}
{opt p} is the epsilon used by EPSILON_SVR. Larger makes your fit more flexible, and can lead to underfitting[???]. Smaller can lead to overfitting. (the name epsilon was already taken for an option, so the libsvm authors chose "p").

{phang}
{opt nu} is used in the NU variants. See {help svm##nusvm:the ν-SVM tutorial} for details.
[TODO: ...]

{phang}
{opt epsilon} is the stopping tolerance used by the numerical optimizer. You could widen this if you are finding convergence is slow or not occurring, but be aware that this usually non-convergence is a deeper problem in the data versus the kernel.

{phang}
{opt shrinking} invokes libsvm's built-in shrinking heuristics [TODO: what does this mean?]

{phang}
{opt autonormalize} instructs the fitter to first center and scale the data
so that every column has identical mean and variance
 as suggested in the {help svm##libsvmguide:libsvm guide}.
 In theory, this should help the results---as measured by cross-validation---
 by weighting each column's effect the same and reducing the chance for numerical error
 but this is not always the case, so it is disabled by default.

{pmore}
If enabled, {cmd:predict} will also autonormalize.

{phang}
{opt probability} enables the use of "predict, prob" as described below. This takes additional CPU and space, so if you can disable it if you don't need it by writing "noprobability" instead.

{phang}
{opt cache_size} tweaks an internal libsvm parameter of how much RAM to use during training. Value is given in megabytes (MB).
[TODO: what effect does this have?]

{phang}
{opt SVs}, 
{opt nSVs}, 
{opt labels}, 
{opt sv_coef}, and
{opt rho}
control whether or not these matrices are exported from libsvm to Stata.
Though libsvm is perfectly capable of allocating space for them, and always does,
your {help matsize} may not be large enough for them, so you can disable each individually by prefixing "no", e.g. "nosv_coef". See {help svm##gotchas:gotchas}.
{...}
{...}

{title:predict}

{pstd}
After training you can ask svm to {cmd:predict} what it thinks the classes (classification) or values (regression) of given observations into {targetvar}.
{targetvar} must not exist, so if you want to repredict your choices are {cmd:drop {targetvar}} or to pick a new name, e.g. {cmd:predict {targetvar}2}.{p_end}
{pmore}For classification problems, {opt probability} requests, for each observation, the probability of it being each class.{p_end}
{pmore}For regression problems, {opt probability} requests [....].{p_end}
{pmore}In addition to predictions in {targetvar}, {targetvar} is used as a stem for names of new columns for the results.
This option will fail if you specified {opt noprobability} during estimation.{p_end}

{pstd}
Prediction automatically uses the same {indepvars} as in training, so if you rename or drop columns between commands you will have problems.
{...}
{...}

{title:import/export}

{pstd}
libsvm has an ad-hoc format it uses to save trained models. The command line programs {cmd:svm-train} and {cmd:svm-predict} that come with libsvm communicate via it. We support it for completeness. Those programs use the '.model' file extension by default, and we suggest you follow this convention.

{pstd}
{cmd:svm_export} will write a fitted model to disk.

{pstd}
{cmd:svm_import} will load a model from disk, replacing any previous in-memory fit. When you import, [some properties] will be missing because the import was done without reference to any dataset.

{pstd}
Do not confuse these commands with {cmd:import_svmlight} and {cmd:export_svmlight}.


{marker examples}{...}
{title:Examples:  classification}

        {hline}
{phang2}{cmd:. webuse highschool, clear}{p_end}
{phang2}{cmd:. svm gender}{p_end}
{phang2}{cmd:. ereturn list}{p_end}
{phang2}{cmd:. predict P, prob}{p_end}
        {hline}

{title:Examples:  regression, suppressing sv_coef}

        {hline}
{phang2}{cmd:. sysuse auto, clear}{p_end}
        {hline}

{title:Examples:  classification with tuning}

        {hline}
{phang2}{cmd:. webuse regsmpl, clear}{p_end}
        {hline}
        

{title:Examples:  forecasting}

        {hline}
--- train on one set of data, generate more observations, predict
        {hline}

{title:Example:  weighted regression}

{pstd}
Not currently implemented.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:svm} and {cmd:svm_import} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(nr_class)}}number of classes, in a classification problem. [??? if SVR??]{p_end}
{synopt:{cmd:e(l)}}number of support vectors{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}"{cmd:svm}"{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(model)}}"{cmd:svm}"{p_end}
{synopt:{cmd:e(svm_type)}}SVM type string, as above{p_end}
{synopt:{cmd:e(svm_kernel)}}kernel string, as above{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}
{* {synopt:{cmd:e(estat_cmd)}}program used to implement {cmd:estat}{p_end} }{...}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}(may be missing, depending on options){p_end}
{synopt:{cmd:e(SVs)}}A list of the support vectors chosen. Numbers are indices into observations of the dataset; this will not exist in models loaded from {cmd:svm_import}.{p_end}
{synopt:{cmd:e(labels)}}List of the class "labels" (which are integers, as far as libsvm is concerned). This should be the same set as in the original dataset, but libsvm may permute it. [XXX hide this from Stata; just use it to label the]{p_end}
{synopt:{cmd:e(nSVs)}}The number of support vectors belonging to each class, in a classification problem.{p_end}
{synopt:{cmd:e(sv_coef)}}???{p_end}
{synopt:{cmd:e(rho)}}??? something involving multiclass decision boundaries ???{p_end}


{* XXX this section name should be more formal}{marker gotchas}{...}
{title:Gotchas}

{pstd}
{bf:Memory Limits}: The cheaper versions of stata support allow less memory to be used. As machine learning problems typically are on very large datasets,
it is easy to inadvertently instruct this package to construct more columns or larger matrices than you can afford.
In this case, you will receive an error and find yourself with a partially allocated set of probability columns or a partial set of {cmd:e()} matrices^.

{pmore}
You can proceed by retrying the command with various combinations of "no{matrix}" options applied to reduce the output size. If done in the same session you will also need to manually drop the mistake columns with {cmd:drop {targetvar}*}.

{pmore}
If you are really stuck, you can also proceed by giving up on Stata and switching to libsvm's companion {cmd:svm-train} program,
will have been installed with the libsvm package if you used a package manager, or
which you can get {browse "http://www.csie.ntu.edu.tw/~cjlin/cgi-bin/libsvm.cgi?+http://www.csie.ntu.edu.tw/~cjlin/libsvm+zip":from its authors};
you can use {help svmlight:export svmlight} to extract your dataset for {cmd:svm-train}.

{pmore}^{browse "https://github.com/kousu/statasvm/pulls":patches} to instead trap errors and restore the previous state are very welcome.

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


{marker exeunt}{...}
{title:Exeunt}

{pstd}
Though the license does not obligate you in any way to do so, if you find
this software useful we would be curious and appreciative to hear about your adventures in machine learning through Stata.{p_end}
{pmore}Thank you.

{pmore}* Nick Guenther <nguenthe@uwaterloo.ca>{p_end}
{pmore}* Matthias Schonlau <schonlau@uwaterloo.ca>{p_end}


{marker references}{...}
{title:References}

{marker sourcecode}{...}
{phang}
Guenther, Nick and Schonlau, Matthias. 2015. Stata-SVM.
{browse "https://github.com/kousu/statasvm/"}
{p_end}

{marker svmtutorial}{...}
{phang}
[svmtutorial] TODO
{p_end}

{marker libsvm}{...}
{phang}
Chang, Chih-Chung and Lin, Chih-Jen. 2011.
{it:LIBSVM : a library for support vector machines.}
ACM Transactions on Intelligent Systems and Technology, 2:27:1--27:27.
{browse "http://www.csie.ntu.edu.tw/~cjlin/papers/libsvm.pdf"}.
Software available at {browse "http://www.csie.ntu.edu.tw/~cjlin/libsvm"}
{p_end}

{marker libsvmguide}{...}
{phang}
Chih-Wei Hsu, Chih-Chung Chang, and Chih-Jen Lin.
{it:A Practical Guide to Support Vector Classification.}
April 15, 2010.
{browse "http://www.csie.ntu.edu.tw/~cjlin/papers/guide/guide.pdf"}
{p_end}

{marker nusvm}{...}
{phang}
Pai-Hsuen Chen, Chih-Jen Lin, and Bernhard Schölkopf.
{it:A Tutorial on ν-Support Vector Machines}.
{browse "http://www.csie.ntu.edu.tw/~cjlin/papers/nusvmtutorial.pdf"}
{p_end}


