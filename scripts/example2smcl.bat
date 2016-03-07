REM Wrap the awk+POSIX example2smcl script for Windows.
REM By naming this .bat, Windows will find and run it if told to run scripts\example2smcl, ignoring the actual scripts\example2smcl file.
REM This requires gawk to be installed. You can get it from Cygwin or from GnuWin32: http://gnuwin32.sourceforge.net/packages/gawk.htm
REM (on POSIX we tacitly assume awk is always installed)

REM echo off

rem Note: %0 is like $0, %* is like $@ <http://www.robvanderwoude.com/parameters.php>

rem Grab the directory of this file, because we assume example2smcl(.awk) is in the same place.
rem http://stackoverflow.com/questions/778135/how-do-i-get-the-equivalent-of-dirname-in-a-batch-file
for %%F in ("%0") do set HERE=%%~dpF

gawk -f %HERE%\example2smcl %*