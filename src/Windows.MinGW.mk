# MinGW makefile

$(warning If you get linker errors, check that you are using the right (32 vs 64 bit) architecture)

include posix.mk

LDFLAGS+=-shared  #the only reason this isn't in posix.mk is because it's wrong on OS X (XXX is it?)

CFLAGS+=-D_USRDLL -D_WINDLL
CFLAGS+=-O2
CFLAGS+=-Wall -Werror
CFLAGS+=-std=c99

#TODO: detect this by asking MinGW
ARCH:=x86_64

# patch the Visual Studio env vars INCLUDE and LIB over to MinGW
# this is necessary because we depend on an external library, libsvm,
# which cannot be counted on to be in a sensible package manager (because Windows doesn't have one)
# so COMPILE.md directs people to do the custom-install method
#
# by the way,
# MinGW makes .dll's and their associated .lib files look like .so's---
# -lsvm will search "svm.dll", "svm.lib" and "libsvm.so"---so we can leave the -l flags alone
# http://www.mingw.org/wiki/specify_the_libraries_for_the_linker_to_use
#
ifdef INCLUDE
  CPATH:=$(CPATH);$(INCLUDE)
  export CPATH
endif

ifdef LIB
  LIBRARY_PATH:=$(LIBRARY_PATH);$(LIB)
  export LIBRARY_PATH
endif

# include the in-repo Windows build deps
# XXX this is duplicated over in Windows.VC.mk
# there's a chicken-or-egg problem if we try to set this in Windows_NT.mk: to set the library path we need to run these sub-makefiles first to find out $(ARCH)
export CPATH:=windows;$(CPATH)
export LIBRARY_PATH:=windows\$(ARCH);$(LIBRARY_PATH)
export PATH:=$(PATH);$(LIBRARY_PATH) # like setting LD_LIBRARY_PATH on Unix: make sure tests can find the DLLs
