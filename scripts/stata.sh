#!/bin/sh
# Wrap Stata so that scripts (do-files) behave like a Unix interpreter:
# - the only argument is a .do file to run
# - the output is sent to stdout
#  - But because of how Stata is hard-coded you won't see output until the entire script is finished
# - exit codes are bubbled up to the OS (though Stata exit codes are 16 bit at least and C exit codes are only 8)
#
# Run like
# `stata script.do ; echo $?`
#
# This has a Windows port in stata.bat, which you should find there. This would almost work on Windows,
#  but expecting Windows to have bash is a mistake.

# TODO:
# [ ] detect if we're pointed at console Stata or GUI Stata.
#       GUI Stata (which is all you get on OS X and Windows) can only be automated with -e,
#         which requires running the thing and waiting for it to spit out a logfile that
#        needs replaying and maybe parsing, but console Stata gives real-time output.
#        This could be detected by probing with a test program that looks at the c() settings list.
# [ ] On Windows, read the Stata install location from the registry (`reg query ...`)?
# [ ] On Windows, handle falling back to stata-32 or the other names it gains, as well

#STATA=stata
STATA=stata-se
if [ "$(uname)" = "Darwin" ]; then
  PATH=/Applications/Stata/StataSE.app/Contents/MacOS/:$PATH
# PATH=/Applications/Stata/Stata.app/Contents/MacOS/:$PATH  
# Note: Stata installs to /Applications/Stata/Stata.app/Contents/MacOS/Stata on OS X,
  #       but OS X is happily case-insensitive.
fi

if ! which "$STATA" >/dev/null 2>/dev/null; then
  echo "Stata not found."
  exit 1
fi

SCRIPT="$1"; shift

WRAPPER=$(dirname $0)/stata_wrap.do

# allocate a folder for stata_wrap to return data via
if (mktemp --version 2>/dev/null | grep GNU); then
  # GNU and 
  # Under GNU -p "" means use /tmp or other system-defined default
  CRUFT=$(mktemp -d -p "" "statawrap.XXXXXXXX")
else
  # Assume BSD mktemp
  CRUFT=$(mktemp -d -t statawrap)
fi
LOG="$CRUFT"/session.log
RC="$CRUFT"/rc

$STATA -q -e do "$WRAPPER" "$SCRIPT" "$LOG" "$RC"

cat $LOG
RC=$(cat "$RC")
rm -r $CRUFT
exit $RC
