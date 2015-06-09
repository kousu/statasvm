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
{help svm##svm:svm} {depvar} {indepvars} {ifin} [{it:{help svm##weight:weight}}] [{cmd:,} {it:options}]

{p 8 16 2}
{help svm##svm:svm} {indepvars} {ifin} [{it:{help svm##weight:weight}}], type(one_class) [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opth t:ype(svm##type:type)}}Type of model to fit: {opt c_svc}, {opt nu_svc}, {opt one_class}, {opt epsilon_svr}, or {opt nu_svr}. Default: {cmd:type(c_svc)}{p_end}
{synopt :{opth k:ernel(svm##kernel:kernel)}}SVM kernel function to use: {opt linear}, {opt poly}, {opt rbf}, {opt sigmoid}, or {opt precomputed}. Default: {cmd:kernel(rbf)}{p_end}

{synopt :{opth deg:ree(svm##degree:degree)}}For {opt poly} kernels, the degree of the polynomial to use. Default: cubic ({cmd:degree(3)}){p_end}

{* XXX the division between 'tuning' and 'model' parameters is hazy; e.g. you could in theory cross-validate to choose degree (and people do this with neural networks), or even to choose the kernel . hmmmmm}{...}

{syntab:Tuning}
{synopt :{opth c:(svm##c:c)}}For {opt c_svc}, {opt epsilon_svr} and {opt nu_svr} SVMs, this is a regularization parameter which weights the slack variables. Should be > 0. Default: {cmd:c(1)}{p_end}
{synopt :{opth p:(svm##p:p)}}For {opt epsilon_svr} SVMs, the margin of error allowed for to count something as a support vector. Default: {cmd:p(0.1)}{p_end}
{synopt :{opth nu:(svm##nu:nu)}}For {opt nu_svc}, {opt one_class}, and {opt nu_svr} SVMs, tunes the number of supports vectors. Should be in (0, 1]. Default: {cmd:nu(0.5)}{p_end}

{synopt :{opth gamma:(svm##gamma:gamma)}}For {opt poly}, {opt rbf} and {opt sigmoid} kernels, a scaling factor for the linear part of the kernel. Default: {cmd:gamma(1/[# {indepvars}])}{p_end}
{synopt :{opth coef0:(svm##coef0:coef0)}}For {opt poly} and {opt sigmoid} kernels, a bias ("intercept") term for the linear part of the kernel. Default: {cmd:coef0(0)}{p_end}

{synopt :{opt shrink:ing}}Whether or not to use shrinkage heuristics to attempt to improve the fit. Default: disabled{p_end}


{syntab:Features}
{synopt :{opt norm:alize}}Whether to center and scale the data. NOT IMPLEMENTED. Default: disabled{p_end}
{synopt :{opt prob:ability}}Whether or not to precompute the cross-validation runs needed for "predict, prob". Only applicable to classification problems. Default: disabled{p_end}
{synopt :{opth sv:(svm##sv:newvarname)}}If given, a variable to generate and with booleans marking each row as a support vector or not. Default: disabled{p_end}


{syntab:Performance}
{synopt :{opth eps:ilon(svm##epsilon:epsilon)}}The stopping tolerance used to decide when convergence has happened. Default: {cmd:epsilon(0.001)}{p_end}
{synopt :{opth cache:_size(svm##cache_size:cache)}}The size of the RAM cache used during fitting, in megabytes. Default: 100MB ({cmd:cache_size(100)}){p_end}

{synoptline}
{pstd}All variables must be numeric (including outcome classes, which are typically stored in Stata as integers with value labels attached); use {help encode} if you have classes stored in string variables.{p_end}
INCLUDE help fvvarlist



{p 8 16 2}
{help svm##predict:predict} {newvar} {ifin}, [{cmdab:prob:ability}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{cmdab:prob:ability}}If specified, estimate class probabilities for each observation. This only makes sense for classification problems.{p_end}



{p 8 16 2}
{help svm##export:svm_export} using {filename}

{p 8 16 2}
{help svm##export:svm_import} using {filename}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{cmd: using}}The filename to export or import a fitted libsvm model from, conventionally ending in '.model'.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:svm} fits a support vector machine (SVM) model of {depvar} on {indepvars}.
SVM is not one, but several variant models, all based upon splitting hyperplanes and culling unimportant observations.
The name's second part comes from how each observation in a dataset can be thought of as a vector in d-dimensional space, where d is the number of {indepvars},
and first part from the culling. "Support vectors" are those observations which the algorithm detects are critical to the fit; all others are ignored after fitting is done,
which makes SVM very memory efficient.

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

{marker svm}{...}
{title:svm}

{pstd}
{cmd:svm} does model training, otherwise known as fitting or estimation (depending on your statistical background).

{phang}
{marker type}{...}
{opt type} specifies what subtype of SVM to run.{p_end}
{pmore}{opt c_svc} and {opt nu_svc} perform classification.{p_end}
{pmore2}{depvar} should be a discrete variable.{p_end}
{pmore2}If you try to use floating point values with classification you will find that they are truncated to only the integer parts.{p_end}
{pmore2}Further, if you accidentally use a floating point {depvar}, it is easy to end up with as many classes as observations, which is not informative.{p_end}

{pmore2}libsvm automatically handles multiclass classification using the {browse "http://en.wikipedia.org/wiki/Multiclass_classification":one-against-one} method.{p_end}

{pmore}{opt one_class} separates outliers from the bulk of the data.{p_end}
{pmore2}{opt one_class} does not take a {depvar} because it is a form of unsupervised learning: all the information it uses is in the predictors themselves.{p_end}
{pmore3}You may use the same {varlist} as with the others: by including your depvar as an indepvar you just give {opt one_class} more information to work with.{p_end}
{pmore2}Its predictions give 1 for "data" and -1 for "outlier".{p_end}

{pmore}{opt epsilon_svr} and {opt nu_svr} perform regression.{p_end}
{pmore2}While you can use this with discrete {depvar}s, it is more common to use it with continuous ones.{p_end}
{pmore2}See {help svm##svr_tutorial:the SVR tutorial} for more details.{p_end}

{pmore}To learn about the {opt c}/{opt nu} distinction, see {help svm##nusvm:Chen and Lin's ν-SVM tutorial}.{p_end}

{phang}
{marker kernel}{...}
{opt kernel} gives a kernel function to use.
The basic SVM algorithm finds a linear boundary (a hyperplane). For classification, this is a boundary between two classes; for regression it is a line near which correct predictions are expected to cluster--much like in {help regess:OLS}.
But the {browse "https://en.wikipedia.org/wiki/Kernel_Method":kernel trick} makes SVM more flexible: it can make a space look non-linear by mapping it into a higher dimensional space.
See {browse "https://www.youtube.com/watch?v=3liCbRZPrZA"} for a visualization of this process.
The part that makes it a trick is that the fit can be done efficiently without first mapping your observations into the higher dimensional space,
as the estimation only cares about their kernel value <u,x>, a value used in scoring the coefficients u,
and for certain kernels this value can be computed straight from the original data without doing the mapping at all.{p_end}

{pmore}Choices of kernels are:{p_end}
{pmore2}{opt linear} means the linear kernel you are probably familiar with from {help regress:OLS}: u'*v{p_end}
{pmore2}{opt poly} is (gamma*u'*v + coef0)^degree{p_end}
{pmore2}{opt rbf} stands for Radial Basis Functions, and treats the coefficients as a mean to smoothly approach in a ball, with the form exp(-gamma*|u-v|^2); this kernel tends to be good at [...].{p_end}
{pmore2}{opt sigmoid} is a kernel which bends the linear kernel to fit in -1 to 1, similar to {help logistic} regression: tanh(gamma*u'*v + coef0){p_end}
{pmore2}{opt precomputed} assumes that {depvar} is actually a list of precomputed kernel values. With effort, you can use this to use custom kernels with your data [TODO].{p_end}

{phang}
{marker degree}{...}
{opt degree} selects the degree of the polynomial used by the {opt poly} kernel.
Setting this too high will result in overfitting. Setting it too low may result in non-convergence.
[TODO: tips about choosing this]

{phang}
{marker c}{...}
{opt c} weights (regularizes) the slack variables used in {opt c_svc}, {opt epsilon_svr} and {opt nu_svr}. This will pre-multiply any sample-specific {opt weight}s.

{phang}
{marker p}{...}
{opt p} is the margin of error allowed by {opt epsilon_svr}---the name was already taken by {opt epsilon}. Larger makes your fit more flexible, and can lead to underfitting. Smaller can lead to overfitting.

{phang}
{marker nu}{...}
{opt nu} is used in the nu variants. The nu variants are a reparamaterization of regular SVM which lets you directly tune, using {opt nu}, the tradeoff between error and computation. {opt nu} is an upper bound on the fraction of training errors and a lower bound of the fraction of support vectors, so that smaller means ... and larger means ..... See {help svm##nusvm:the ν-SVM tutorial} for details.
{* ..wait... this doesn't make any sense. nu == 0.1 means there are at most 10% (training) errors and at least 10% are support vectors.}{...}
{*      nu = 0.9 means there are at most 90% errors and at least 90% SVs.   you should always choose 0, then, to get perfect prediction and zero memory usage}{...}

{phang}
{marker gamma}{...}
{opt gamma} is used in the non-linear kernels as a scaling factor for the linear part, as seen above.
[TODO: tips about choosing this]

{phang}
{marker coef0}{...}
Similarly, {opt coef0} is used in the non-linear kernels as a pseudo-intercept term.
Except it is not used in the {opt rbf} kernel as {opt rbf} is essentially a distance function, and biasing would be pointless.[???]
[TODO: tips about choosing this]

{phang}
{marker shrinking}{...}
{opt shrinking} invokes libsvm's built-in shrinking heuristics [TODO: what does this mean? shrinkage estimation?]

{phang}
SVM tends to be very sensitive to scaling issues, so {opt normalize} instructs the estimation to first center and scale the data so that every variable starts with equal influence.
This normalizes all data to [0,1] using min-max normalization, as suggested in the {help svm##libsvmguide:libsvm guide}.
Normalization creates temporary variables, so you may prefer to preprocess the data yourself---destructively and in-place---to save time on re-estimations and memory for variables,
especially if you are bumping up against your Stata system limits. You may find {cmd:ssc install norm} helpful.

{phang}
{marker probability}{...}
{opt probability} enables the use of "predict, prob" as described below. This takes additional CPU and space, slowing down both training and prediction.

{phang}
{marker sv}{...}
{opt sv} records in the given variable a boolean indicating whether each observation was a support vector or not.

{phang}
{marker epsilon}{...}
{opt epsilon} is the stopping tolerance used by the numerical optimizer. You could widen this if you are finding convergence is slow,
 but be aware that this usually non-convergence is a deeper problem in the interaction of data, kernel, and tuning parameters.

{phang}
{marker cache_size}{...}
{opt cache_size} controls a time-memory tradeoff during estimation.
Value is how many megabytes (MB) of RAM to set aside for caching data points as the optimizer is iterated.
Generally, more is faster, at least until you run out of RAM or cause your machine to start swapping.

{...}
{...}

{marker predict}{...}
{title:predict}

{pstd}After training you can ask svm to {cmd:predict} what the category (classification) or outcome value (regression)
      should be for each given observation. Results are placed into {newvar}.{p_end}
{pstd}{newvar} must not exist, so if you want to repredict your choices are {cmd:drop {newvar}} or to pick a new name, e.g. {cmd:predict {newvar}2}.{p_end}

{phang}For classification ({opt c_svc}, {opt nu_svc}) problems, {opt probability} requests, for each observation, the probability of it being each class.
{newvar} is used as a stem for names of new columns for the results.
This option is not valid for other SVM types.{p_end}

{pstd}
Prediction automatically uses the same {indepvars} as during training, so be careful about renaming or dropping columns between commands.
{...}
{...}

{marker export}{...}
{title:import/export}

{pstd}
libsvm has an ad-hoc format it uses to save trained models.
The command line programs {cmd:svm-train} and {cmd:svm-predict} which come with libsvm communicate via it.
We support this format for interoperability.

{pstd}
{cmd:svm_export} will write a fitted model to disk.
Though it is your choice, the libsvm convention is to use the '.model' file extension.

{pstd}
{cmd:svm_import} will load a model from disk, replacing any previous in-memory fit.
When you import, [TODO: some properties] will be missing because the import was done without reference to any dataset.

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
        
{title:Examples:  viewing support vectors}

--- crosstab sv against category and compare to nSV

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
{bf:Memory Limits}: The cheaper versions of Stata allow only allow less variables and smaller matrices to be used.
As machine learning problems typically are on very large datasets,
it is easy to inadvertently instruct this package to construct more columns or larger matrices than you can afford.
In this case, you will receive an error and find yourself with a partially allocated set of probability columns or a partial set of {cmd:e()} matrices^.

{pmore}
You can proceed by retrying the command with various combinations of "no{matrix}" options applied to reduce the output size. If done in the same session you will also need to manually drop the mistake columns with {cmd:drop {newvar}*}.

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
this software useful we would be curious and appreciative to hear about your
adventures in machine learning with Stata.{p_end}
{pmore}Thank you.

{pmore}* Nick Guenther <nguenthe@uwaterloo.ca>{p_end}
{pmore}* Matthias Schonlau <schonlau@uwaterloo.ca>{p_end}


{marker references}{...}
{title:References}

{marker sourcecode}{...}
{phang}
Guenther, Nick and Schonlau, Matthias. 2015.
{it:Stata-SVM}.
.{browse "https://github.com/kousu/statasvm/"}.
{p_end}

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


