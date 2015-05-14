* unconditionally unload the plugin
* this is only relevant if this do file is reused in the same session
capture program drop _svm
 
* load and call it 
program _svm, plugin
plugin call _svm, "tests/duke.svmlight"
