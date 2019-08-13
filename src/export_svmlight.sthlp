{smcl}
{* *! version 0.0.1  28may2015}{...}
{cmd:help export_svmlight}{right: ({browse "http://www.stata-journal.com/article.html?article=st0461":SJ16-4: st0461})}
{hline}

{title:Title}

{p2colset 5 24 26 2}{...}
{p2col :{cmd:export_svmlight} {hline 2}}SVM^light data format{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:export_svmlight} {varlist} {cmd:using} {it:filename}

{p 8 16 2}
{cmd:import_svmlight using} {it:filename} [{cmd:, clip}]


{marker description}{...}
{title:Description}

{pstd}
{cmd:svmlight} is an SVM software that creates a simple de facto plain text
standard for medium-sized numeric datasets; this was adopted by {cmd:libsvm}.  The kind {cmd:libsvm} authors even provide a {browse "http://www.csie.ntu.edu.tw/~cjlin/libsvmtools/datasets/":repository} of
datasets in compressed {cmd:svmlight} format (note: this command does not
handle compression; you will need to use an external program for that).

{pstd}
{cmd:export_svmlight} saves the current Stata dataset to disk in
{cmd:svmlight} format. The first variable is used as the outcome variable,
which gets written without an attached column index.

{pstd}
{cmd:import_svmlight} loads the dataset {cmd:svmlight} format into Stata
(clearing the current dataset). The outcome variable will become the first
column.

{pstd}
The {cmd:svmlight} format is designed to hold a single outcome variable and a
sparse set of predictor variables.  Exporting and reimporting a dataset
through {cmd:svmlight} will lose your data labels, description, and all other
metadata.  Missing data in your dataset will be skipped during export, and
missing "features" will become missing data when imported.


{title:Option}

{phang}
{opt clip} tells the importer to silently drop trailing columns if there are
more than {helpb matsize} allows.


{marker examples}{...}
{title:Examples}

{pstd}
Loading a dataset

{phang2}{cmd:. !wget http://www.csie.ntu.edu.tw/~cjlin/libsvmtools/datasets/binary/duke.bz2}{p_end}
{phang2}{cmd:. !bunzip2 duke.bz2 -c > duke.svmlight}{p_end}
{phang2}{cmd:. import_svmlight using "duke.svmlight"}{p_end}
{phang2}{cmd:. list}{p_end}

{pstd}
Saving a dataset

{phang2}{cmd:. webuse highschool}{p_end}
{phang2}{cmd:. export_svmlight * using "highschool.svmlight"}{p_end}
{phang2}{cmd:. type "highschool.svmlight"}{p_end}


{marker authors}{...}
{title:Authors}

{pstd}
Though the license does not obligate you in any way to do so, if you find
this software useful, we would be curious and appreciative to hear about your
adventures in machine learning with Stata.  Thank you.

{pstd}
You can contact us at

{pstd}Nick Guenther{break}
University of Waterloo{break}
Waterloo, Canada{break}
nguenthe@uwaterloo.ca

{pstd}Matthias Schonlau{break}
University of Waterloo{break}
Waterloo, Canada{break}
schonlau@uwaterloo.ca


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 16, number 4: {browse "http://www.stata-journal.com/article.html?article=st0461":st0461}{p_end}

{p 7 14 2}
Help:  {manhelp import D}, {manhelp export D}
