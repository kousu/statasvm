
# Windows-specific build instructions
# There is more than one common compiler for Windows, so this just figures out
# which compiler is in use and calls a further subfile Windows.<compiler>.mk.
# Look there for the meat.

# this is a subroutine to convert Unix(and GNU-make)-style paths to Windows paths, which has to happen before they get passed to the shell
FixPath = $(subst /,\,$1)

# platform config
DLLEXT:=dll

# the common testing code is written POSIXey; these variables glue POSIX shell into the DOS shell, more or less.
ifndef LN #XXX assuming that this missing means all are missing
WHICH:=where
NULL:=NUL
MV:=rename /Y 2o>NUL
CAT:=type 2>NUL
RM:=del /F /Q 2>NUL
RMDIR:=rmdir /S /Q 2>NUL
CP:=copy /Y 2>NUL
MKDIR:=mkdir
LN:=$(CP)  #Windows doesn't have reliable hard links (NTFS does, but you know), so instead of linking just duplicate.
endif

# 'del', 'type' and so on are are DOS builtins and, unlike POSIX, they are *only builtins* (there is no /bin/[ on Windows),
# so we must run them via cmd, either by prefixing them with `cmd /c` or, more simply, enforcing which shell make uses.
# forcing the shell also gets around the problem that bash, which comes with Cygwin/Cmder, gets confused on spaces in program paths
#  (i.e. in Stata's path), a problem made worse by backslash escaping getting confused for path separators

# "However, on MS-DOS and MS-Windows the value of SHELL in the environment is used, since on those systems most users do not set this variable, and therefore it is most likely set specifically to be used by make. On MS-DOS, if the setting of SHELL is not suitable for make, you can set the variable MAKESHELL to the shell that make should use; if set it will be used as the shell instead of the value of SHELL."
# - <http://www.gnu.org/software/make/manual/make.html#Choosing-the-Shell>
SHELL := cmd







# include the in-repo Windows build deps
#XXX chicken-or-egg problem: we need to run Windows.$(COMPILER) to figure out if we're cross-compiling
# but under MinGW we need to have INCLUDE and LIB defined *before* Windows.MinGW.mk,
# this is because it is a nod to letting the user set these globally e.g. if they have libsvm installed from source
# ...tho I guess if I am hard-including these anyway I can't just do this step twice: once for MinGW and once for MSVC...
ARCH:=x86_64
INCLUDE:=$(INCLUDE);windows
export INCLUDE
LIB:=$(LIB);windows\$(ARCH)
export LIB

# edit PATH so that the tests can find the .dlls
PATH:=$(PATH);$(LIB)
export PATH



# XXX the Windows shared library naming convention is <name>.lib, whereas Unix uses lib<name>.{so,a}
# see http://www.mingw.org/wiki/Specify_the_libraries_for_the_linker_to_use
# libsvm does not respect this convention
# so we hack around the problem	
# I have a patch submitted which will make the correct fix, if they ever get around to reviewing it: https://github.com/cjlin1/libsvm/pull/33.patch
_svm.dll: FIXED_LIBS = $(patsubst svm,libsvm,$(LIBS))

# look for a default C compiler (usually 'cc')
# if this is found, it's probably MinGW; and if it is MinGW, this is the proper way to find it.
ifeq ($(shell where $(CC) 2>NUL),)
  ifneq (($shell where gcc 2>NUL),) #MinGW doesn't install a symlink cc -> gcc :(
    CC=gcc
  endif
endif

ifeq ($(shell where $(CC) 2>NUL),)
  # but if it's not found,
  # look for MSVC and then MinGW if that fails
  # this if a nested-if-else tree because what I'd do in another language (a hashtable of function pointers, or at least a list of options plus a loop) is, charitably speaking, tricky in make
  ifdef VCINSTALLDIR
    $(info Assuming Visual Studio)
    include Windows.VC.mk
  else
      # if the toolchain is still not found, bail
      # it is too hard to do multiline error strings in make (http://stackoverflow.com/questions/649246/is-it-possible-to-create-a-multi-line-string-variable-in-a-makefile), so I'm misusing $(warning) instead: 
      $(warning --------------------------------------------------------------------)
      $(warning Unable to find a C compiler for your Windows machine)
      $(warning - If you have MinGW, you should ensure it is on your %PATH%)
      $(warning - If you have Visual Studio installed, add it to your %PATH%:)
      $(warning i. Relaunch this command prompt from the system-appropriate VS Tools Command Prompt shortcut in your Start Menu,)
      $(warning ii. or invoke vcvarsall.bat manually (see https://msdn.microsoft.com/en-us/library/x4d2c09s.aspx))
      $(warning --------------------------------------------------------------------)
	  
	  CC:="<no_compiler>"
  endif
else
  $(info Assuming MinGW)
  include Windows.MinGW.mk
endif



# Borland: ....
# TODO

# Intel: ???
# TODO

# MinGW: gcc -shared -mno-cygwin $^ -o $@
# TODO

# --- testing ---

# Locate Stata
# in two acts:
# 1) amend the PATH
# 2) State the name of the Stata executable
ifeq ($(STATA),) # an hard 
  # subtlety: make is always forward-slashes for directories and backslashes for escapes, even on Windows.
  STATAPATH := $(call FixPath,$(wildcard c:/Program*/Stata*/)) #XXX in the rare case there are two Statapaths (e.g. 32 bit and 64 bit Stata) this breaks badly because Windows has spaces in "Program Files", and wildcard uses spaces as delimiter
  # amend the PATH
  PATH:=$(PATH);$(strip $(STATAPATH))
  export PATH
  
  STATA := Stata
  ifeq ($(ARCH),x86_64)
    STATA := $(STATA)-64
  endif
endif


# --- cleaning ---

.PHONY: clean-windows
clean-windows: 
	-$(RM) *.dll *.lib *.exp *.obj

clean: clean-windows