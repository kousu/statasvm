local mQQ : env QQ
di "First: mQQ=`mQQ'"

// the \$ quotes the $, because otherwise Stata, apparently, tries to interpret it
!echo And the shell says: \$QQ

program _setenv, plugin
plugin call _setenv, QQ "hello me hearties"

local mQQ : env QQ
di "After: mQQ=`mQQ'"
!echo And the shell says: \$QQ

