

include posix.mk

DLLEXT:=dylib

CFLAGS+=-DSYSTEM=APPLEMAC	#the Stata Programming Interface (i.e. stplugin.h) name for what OS we're on (actually, the OS X plugin seems to work fine if compiled with OPUNIX, but I don't want to trust to that)
LDFLAGS+=-bundle


# the complicated install_name_tool line takes everything in LIBS and rewrites them with as a filename; this means that LD_LIBRARY_PATH and DYLD_LIBRARY_PATH will be searched at runtime for this library. This goes against the OS X conventions, but the OS X conventions don't understand package management.
# this *doesn't* use @rpath, but it could, and it might if I reneg on this opinion and switch to bundling.
# TODO: if we decide to bundle libsvm.dylib, we'll also need to add the current directory to where the .dylib will look for depends, like Windows. On Linux, people often write wrappers that manipulate LD_LIBRARY_PATH before launch, but OS X lets us bundle this information *into the executable*: use `-Wl,-rpath,.` (or maybe `-Wl,-rpath,@executable_path`). See `man ld`

%.dylib:
	$(CC) $(CFLAGS) $(LDFLAGS) $(foreach L,$(LIBS),-l$L) $^ -o $@ #or should this be -dynamiclib? it gives a different filetype, but still works
	$(foreach L,$(LIBS),ABS=$$(otool -L $@ | tail -n +2 | grep $L | cut -f 1 -d " ") && install_name_tool -change $$ABS $$(basename $$ABS) $@ &&) true



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
