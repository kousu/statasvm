{smcl}
{* *! version 0.0.1  28may2015}{...}
{vieweralsosee "[D] export" "mansection D export"}{...}
{vieweralsosee "[D] import" "mansection D import"}{...}
{viewerjumpto "Syntax" "svm##syntax"}{...}
{viewerjumpto "Description" "svm##description"}{...}
{* {viewerjumpto "Options" "svm##options"}}{...}
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
{p2col :{cmd:svm} {hline 2}}SVM^Light data format{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
export_svmlight {varlist} using {filename}

{p 8 16 2}
import_svmlight using {filename}[, clip]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{cmd: using}}The filename of the svmlight dataset.{p_end}



{marker description}{...}
{title:Description}

{pstd}
{help svmlight##svmlight} is a SVM software which created a simple de-facto plaintext standard for medium-sized numeric datasets, which was adopted by {help svmlight##libsvm}.
The kind libsvm authors even provide a {browse "http://www.csie.ntu.edu.tw/~cjlin/libsvmtools/datasets/":repository} of datasets in compressed svmlight format 
(note: this module does not handle compression; you will need to use an external program for that).

{pstd}
{cmd:export_svmlight} saves the current Stata dataset to disk in svmlight format. The first variable is used as the outcome variable, which gets written without an attached column index.

{pstd}
{cmd:import_svmlight} loads the a dataset svmlight format into Stata (clearing the current dataset). The outcome variable will become the first column.
{opt clip} tells the importer to silently drop trailing columns if there are more than {help matsize} allows.


{pstd}
The svmlight format is designed to hold a single outcome variable and a sparse set of predictor variables.
Exporting and reimporting a dataset through svmlight will lose your data labels, description, and all other metadata.
Missing data in your dataset will be skipped during export, and missing "features" will become missing data when imported.

{marker examples}{...}
{title:Examples:  Loading a dataset}

{phang2}{cmd:. !wget http://www.csie.ntu.edu.tw/~cjlin/libsvmtools/datasets/binary/duke.bz2}{p_end}
{phang2}{cmd:. !bunzip2 duke.bz2 -c > duke.svmlight}{p_end}
{phang2}{cmd:. import_svmlight using "duke.svmlight"}{p_end}
{phang2}{cmd:. list}{p_end}

{title:Examples:  Saving a dataset}

{phang2}{cmd:. webuse highschool}{p_end}
{phang2}{cmd:. export_svmlight * using "highschool.svmlight"}{p_end}
{phang2}{cmd:. type "highschool.svmlight"}{p_end}
