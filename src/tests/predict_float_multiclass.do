* train.do
sysuse auto

drop make
order headroom // headroom is a floating point variable but comes in .5-increment levels

svmachines * if !missing(rep78), sv(SV)
list SV
do tests/helpers/inspect_model.do

predict Q
list `e(depvar)' Q
