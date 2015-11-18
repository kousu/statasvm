local mQQ : env QQ
di "First: mQQ=`mQQ'"

// the \$ quotes the $, because otherwise Stata, apparently, tries to interpret it
!echo And the shell says: \$QQ

program _svm_setenv, plugin
plugin call _svm_setenv, QQ "hello me hearties"

local mQQ : env QQ
di "After: mQQ=`mQQ'"
!echo And the shell says: \$QQ

