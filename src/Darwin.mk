

include posix.mk

# hack: we are trying to build .c -> .o -> .so -> .dylib on Darwin, but .so doesn't gets told to depend on the .o files (instead the dylib does) so building the .so fails.
# This patches over that with toothpaste and popsicle sticks:
#  it copies the identical lines from the main makefile, but before DLLEXT is overwritten
# This desperately needs to be better
# - is there a way to get upstream targets feed their dependencies into their dependencies?
# - the main goal of this was to attach extra commands (otool) to the build
#   is there a way to augment? maybe by adding extra targets? or..something?????
# - is this a time for recurisve make?
_svmachines.$(DLLEXT): $(patsubst %.c,%.$(OBJEXT),_svmachines.c sttrampoline.c stutil.c stplugin.c)
_svmachines.$(DLLEXT): libsvm_patches.$(OBJEXT)
_svmachines.$(DLLEXT): LIBS += svm
_svmlight.$(DLLEXT): $(patsubst %.c,%.$(OBJEXT),_svmlight.c sttrampoline.c stutil.c stplugin.c)
_svm_getenv.$(DLLEXT): $(patsubst %.c,%.$(OBJEXT),_svm_getenv.c stutil.c stplugin.c)
_svm_setenv.$(DLLEXT): $(patsubst %.c,%.$(OBJEXT),_svm_setenv.c stutil.c stplugin.c)
_svm_dlopenable.$(DLLEXT): $(patsubst %.c,%.$(OBJEXT), _svm_dlopenable.c stutil.c stplugin.c)


DLLEXT:=dylib

CFLAGS+=-DSYSTEM=APPLEMAC	#the Stata Programming Interface (i.e. stplugin.h) name for what OS we're on (actually, the OS X plugin seems to work fine if compiled with OPUNIX, but I don't want to trust to that)
CFLAGS+=-std=c99 #arrrrgh, this should be the default

LDFLAGS+=-bundle


# the complicated install_name_tool line takes everything in LIBS and rewrites them with as a filename; this means that LD_LIBRARY_PATH and DYLD_LIBRARY_PATH will be searched at runtime for this library. This goes against the OS X conventions, but the OS X conventions don't understand package management.
# this *doesn't* use @rpath, but it could, and it might if I reneg on this opinion and switch to bundling.
# TODO: if we decide to bundle libsvm.dylib, we'll also need to add the current directory to where the .dylib will look for depends, like Windows. On Linux, people often write wrappers that manipulate LD_LIBRARY_PATH before launch, but OS X lets us bundle this information *into the executable*: use `-Wl,-rpath,.` (or maybe `-Wl,-rpath,@executable_path`). See `man ld`


%.dylib: %.so
	$(CP) $< $@
	$(foreach L,$(LIBS),ABS=$$(otool -L $@ | tail -n +2 | grep $L | cut -f 1 -d " ") && install_name_tool -change $$ABS $$(basename $$ABS) $@ &&) true

# --- testing ---


printdeps:
	otool -L $^

# --- cleaning ---

.PHONY: clean-darwin
clean-darwin:  clean-posix
	-$(RM) *.dylib

clean: clean-darwin
