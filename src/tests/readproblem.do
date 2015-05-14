* unconditionally unload the plugin
* this is only relevant if this do file is reused in the same session
capture program drop svm
 
* load and call it 
program svm, plugin
plugin call svm, "tests/duke.svmlight"
