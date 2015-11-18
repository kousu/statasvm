		rem Wrap Stata so that scripts (do-files) return error codes up to the OS like other languages
rem run like
rem  `stata.bat script.do & echo %errorlevel%`
rem
rem This is a port of stata.sh, which should be sibling to it.

echo off

rem TODO: read the Stata install location from the registry ?
set PATH=C:\Program Files (x86)\Stata14;C:\Program Files\Stata14;C:\Program Files (x86)\Stata13;C:\Program Files\Stata13;C:\Program Files (x86)\Stata12;C:\Program Files\Stata12;%PATH%

rem Make sure Stata is findable
rem TODO: handle falling back to stata-32 as well
set STATA=stata-64
where "%STATA%" 2>NUL
if ERRORLEVEL 1 echo Stata not found & exit /b 1

set SCRIPT=%1%


set WRAPPER=%~dp0\stata_wrap.do

rem Windows doesn't have mktemp, so we cop out and hop this works
set CRUFT=_statawrapped
mkdir %CRUFT%
set LOG=%CRUFT%\wrapped.log
set RC=%CRUFT%\rc.txt

"%STATA%" -q -e do "%WRAPPER%" "%SCRIPT%" "%LOG%" "%RC%"

type %LOG%
set /p RC=<%RC%
rem rmdir /s /q %CRUFT%
exit /b %RC%
