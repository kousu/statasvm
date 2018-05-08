REM Wrap Stata so that scripts (do-files) `behave like a Unix interpreter:
REM - the only argument is a .do file to run
REM - the output is sent to stdout
REM  - But because of how Stata is hard-coded you won't see output until the entire script is finished
REM - exit codes are bubbled up to the OS (though Stata exit codes are 16 bit at least and C exit codes are only 8)
REM 
REM run like
REM  `stata.bat script.do & echo %errorlevel%`
REM
REM This is a port of stata(.sh), which you should find in the same directory, and shares a dependency on stata_wrap.do `with `that other version.

echo off

REM Make sure Stata is findable
set PATH=C:\Program Files (x86)\Stata15;C:\Program Files (x86)\Stata14;C:\Program Files\Stata14;C:\Program Files (x86)\Stata13;C:\Program Files\Stata13;C:\Program Files (x86)\Stata12;C:\Program Files\Stata12;%PATH%
REM set STATA=stata-64
set STATA=StataSE-64
where "%STATA%" 2>NUL
if ERRORLEVEL 1 echo Stata not found & exit /b 1

set SCRIPT=%1%

REM http://weblogs.asp.net/whaggard/get-directory-path-of-an-executing-batch-file
set WRAPPER=%~dp0\stata_wrap.do

REM Windows doesn't have mktemp, so we cop out and hope this works
set CRUFT=_statawrapped
mkdir %CRUFT% 2>NUL
set LOG=%CRUFT%\wrapped.log
set RC=%CRUFT%\rc.txt


"%STATA%" -q -e do "%WRAPPER%" "%SCRIPT%" "%LOG%" "%RC%"



type %LOG%

REM http://stackoverflow.com/questions/3068929/how-to-read-file-contents-into-a-variable-in-a-batch-file
set /p RC=<%RC%

REM http://stackoverflow.com/questions/97875/rm-rf-equivalent-for-windows
rmdir /s /q %CRUFT%

REM /b means "only the .bat"; without it exit takes down the entire terminal!
exit /b %RC%
