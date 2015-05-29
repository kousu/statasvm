* export_svmlight.do
sysuse auto
capture rm "tests/auto.svmlight"
// notice: auto contains a string variable and its class variable is last
// we explicitly rearrange them during the export stating the order of variables (Stata handles the indirection, hiding it from the plugin)
export_svmlight foreign price-gear_ratio using "tests/auto.svmlight"
type "tests/auto.svmlight", lines(10)
