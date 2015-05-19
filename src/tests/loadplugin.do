* loadplugin.do
* unconditionally unload the plugin
* this is only relevant if this do file is reused in the same session
capture program drop _svm

* load it! 
program _svm, plugin
