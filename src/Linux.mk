
include posix.mk

CFLAGS+=-DSYSTEM=OPUNIX	#the Stata Programming Interface (i.e. stplugin.h) name for what OS we're on: because Stata isn't cross-platform enough to just use the standard OS defines.
LDFLAGS=-shared

# --- cleaning ---

clean-linux:
	# nothing linux-specific to clean

.PHONY: clean-linux
clean-linux: clean-posix

