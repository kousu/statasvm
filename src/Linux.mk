
include posix.mk

# Define the Stata Programming Interface (i.e. stplugin.h) name for what OS we're on:
# because Stata isn't cross-platform enough to just use the standard OS defines.
CFLAGS+=-DSYSTEM=OPUNIX	

# Use position-independent intermediate machine code.
# Note: the stata docs (http://www.stata.com/plugins/) do not mention -fPIC, but they probably haven't used a recent GCC: GCC demands it for -shared libraries
CFLAGS+=-fPIC

LDFLAGS+=-shared  #the only reason this isn't in posix.mk is because it's wrong on OS X (XXX is it?)

# --- testing ---

printdeps:
	readelf -d $^

# --- cleaning ---

clean-linux:
# nothing linux-specific to clean

.PHONY: clean-linux
clean-linux: clean-posix

