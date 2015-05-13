

include posix.mk

DLLEXT:=dylib

CFLAGS+=-DAPPLEMAC	#the Stata Programming Interface (i.e. stplugin.h) name for what OS we're on (actually, the OS X plugin seems to work fine if compiled with OPUNIX, but I don't want to trust to that)
LDFLAGS+=-bundle


%.dylib:
	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@ #or should this be -dynamiclib? it gives a different filetype, but still works


# --- testing ---

ifndef STATA #i.e. if the user doesn't have stata in their path
  # it should be safe to hardcode the path to Stata on OS X, because it has an installer which doesn't give you much choice
  # though admittedly there *is* going to be the rare user that gets bit by this
  STATA := $(wildcard /Applications/Stata/Stata.app/Contents/MacOS/Stata)
endif

# --- cleaning ---

.PHONY: clean-darwin
clean-darwin:  clean-posix
	-$(RM) *.dylib

clean: clean-darwin
