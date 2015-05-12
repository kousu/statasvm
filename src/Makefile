
# This is a cross-platform makefile
#

# tips gleaned from 
# - http://stackoverflow.com/questions/4058840/makefile-that-distincts-between-windows-and-unix-like-systems
# - http://stackoverflow.com/questions/7876876/tell-if-make-is-running-on-windows-or-linux
# - http://make.mad-scientist.net/papers/rules-of-makefiles/
# - http://make.mad-scientist.net/papers/how-not-to-use-vpath/
# - and  by digging through `make -p`, which shows all defined rules, including the huge spate of implicit rules, on different platforms
# - http://stackoverflow.com/questions/1077676/how-to-conditional-set-up-a-makefile-variable-by-testing-if-a-file-exists
# though they aren't all totally relevant to what we're doing her
# and of course, the canonical reference
# - http://www.stata.com/plugins/#sect5

# TODO:
# [ ] Turn up the warning level (-Wall or /Wall) and make warnings into errors (-Werror or /WX): this forces the code to be high quality, by nagging you at every single build until you get it right
# [ ] 

# Cross-platform nits:
# be careful: Windows's cmd uses ';' to separate parameters, not commands, so you can's say `cmd1; cmd2` . For most cases, we can get away with `cmd1 && cmd2` which works on both POSIX and Windows.

#TODO: is there any way to get make to catch instead of ignore empty $(STATA)s? one way: generate a filename that definitely doesn't exist (super flakey); two way: write an explicit if that catches this cases 



# first check for Windows; Windows defines the OS
ifneq ($(OS),Windows_NT)
  # assume everywhere except for Windows has uname
  # XXX this might break on e.g. Windows 2000... but that's probably alright.
  OS:=$(shell uname)
endif
ifeq ($(OS),) #and then if OS is still undefined after uname, bail
  $(error "Unable to determine OS.")
endif

ifeq ($(OS),Windows_NT)
  # 'del', 'type' and so on are are DOS builtins and, unlike POSIX, they are *only builtins* (there is no /bin/[ on Windows),
  # so we must run them via cmd, either by prefixing them with `cmd /c` or, more simply, enforcing which shell make uses.
  # forcing the shell also gets around the problem that bash, which comes with Cygwin/Cmder, gets confused on spaces in program paths
  #  (i.e. in Stata's path), a problem made worse by backslash escaping getting confused for path separators

  # "However, on MS-DOS and MS-Windows the value of SHELL in the environment is used, since on those systems most users do not set this variable, and therefore it is most likely set specifically to be used by make. On MS-DOS, if the setting of SHELL is not suitable for make, you can set the variable MAKESHELL to the shell that make should use; if set it will be used as the shell instead of the value of SHELL."
  # -http://www.gnu.org/software/make/manual/make.html#Choosing-the-Shell:
  SHELL := cmd
endif

# extend the list of $(CC), $(YACC), ... with extra standard programs variables
# so that we can tolerate the POSIX incompatible parts of Windows by override.
WHICH=which
NULL=/dev/null
CP=cp
CAT=cat


# this is a subroutine; it has the same name as the string 'which' used above,
# which is confusing, but it is not the same thing.
# use it like 
which=$(shell $(WHICH) $(1) 2>$(NULL))

ifeq ($(OS),Linux)
  STATA:=$(call which,stata)
  SHARED_FLAGS=-shared
  CFLAGS+=-fPIC   # Note: the stata docs (http://www.stata.com/plugins/) do not mention -fPIC, but they probably haven't used a recent GCC: GCC demands it
  SPI_SYSTEM=OPUNIX	#the Stata Programming Interface (i.e. stplugin.h) name for what OS we're on: because Stata isn't cross-platform enough to just use the standard OS defines.
else ifeq ($(OS),Darwin)
  # it should be safe to hardcode the path to Stata on OS X, because it has an installer which doesn't give you much choice
  # though admittedly there *is* going to be the rare user that gets bit by this
  STATA:=/Applications/Stata/Stata.app/Contents/MacOS/Stata
  SHARED_FLAGS=-bundle
  SPI_SYSTEM=APPLEMAC
else ifeq ($(OS),Windows_NT)
  WHICH:=where
  NULL:=NUL #this is a magic pseudo-device, like CON or PRN, known to Windows

  CAT=type 2>NUL
  RM=del /F /Q 2>NUL
  CP=copy /Y 2>NUL
  
  # subtlety: make is always forward-slashes for directories and backslashes for escapes, even on Windows.
  STATA:=$(wildcard c:/Program\ Files*/Stata*/Stata*.exe)

  # stplugin.h *defaults* to Windows if not given, and this is exactly what happens under the official instructions which tell you to use Visual Studio in its default configuration
  SPI_SYSTEM=
  
  # look for Make's default C compiler (usually 'cc')
  # if this is found, it's probably MinGW; and if it is MinGW, this is the proper way to find it.
  CC:=$(call which $(CC))
  ifeq ($(CC),)
    # but if it's not found,
    # look for MSVC in the path
    # TODO: we can tell VS is installed by looking for VS120COMNTOOLS, VS110COMNTOOLS, VS100COMNTOOLS, VS90COMNTOOLS, ... We can exploit this to maybe auto-run vcvarsall.bat, or at least to give a better error message.
    CC:=$(call which,cl)
  else
    # assume MinGW without checking
    CFLAGS+=-mno-cygwin
  endif
  
  ifeq ($(CC),)
    # if it's still not found, bail
    
    # it is too hard to do multiline error strings in make (http://stackoverflow.com/questions/649246/is-it-possible-to-create-a-multi-line-string-variable-in-a-makefile), so I'm misusing $(warning) instead: 
    $(warning Unable to find a C compiler for your Windows machine)
    $(warning - If you have MinGW, you should ensure it is on your %PATH%)
    $(warning - If you have Visual Studio installed, add it to your %PATH%:)
    $(warning i. Relaunch this command prompt from the system-appropriate VS Tools Command Prompt shortcut in your Start Menu,)
    $(warning ii. or invoke vcvarsall.bat manually (see https://msdn.microsoft.com/en-us/library/x4d2c09s.aspx))
  endif
  

  #TODO
  # - set flags
  # - *detect whether we have MinGW or VS*
else
  # TODO: this is only an error for testing, so it shouldn't trigger a problem unless we're doing that.
  $(error "Unsupported OS '$(OS)'")
endif



# make really makes spaces difficult, and Windows loves spaces
# A particularly obvious bug of this design is that $(wildcard) is *not* idempotent when spaces are involved: the second time around, in a moment painfully reminiscent of bash, the spaces get interpreted as argument delimiteters.
# but unlike bash, as far as I know you can't use quotes to keep the arguments together: make just sticks the quotes into your string.
# So we degenerate to *re-escaping*, just this trick:
# http://blog.jgc.org/2007/06/escaping-comma-and-space-in-gnu-make.html
empty:=
space:= $(empty) $(empty)
STATA:=$(subst $(space),\$(space),$(STATA))

# --- generic build variables here ---

CFLAGS+="-DSYSTEM=$(SPI_SYSTEM)" #required by stplugin.h; if you get weird errors about STDLL, this is what you're missing

OBJECTS := svm.o stata/stplugin.o



# --- rules begin here ---

.PHONY: all
all: plugin

.PHONY: plugin
plugin: svm.plugin

# strange, make comes with .LIBPATTERNS yet doesn't come with rules for actually making .so files
%.so:
	$(CC) -shared $(CFLAGS) $^ -o $@
%.dylib:
	$(CC) -bundle $(CFLAGS) $^ -o $@ #or should this be -dynamiclib? it gives a different filetype, but still works


	# Borland: ....
	# Intel: ???
	# MinGW: gcc -shared -mno-cygwin $^ -o $@
	# Visual Studio: cl /DLL somethingsomething #the proper command line is listed in the Visual Studio C/C++ configuration pane if you go to the verrrry last page in a DLL project
	# from http://stackoverflow.com/questions/1130479/how-to-build-a-dll-from-the-command-line-in-windows-using-msvccl 
%.dll:
	cl /nologo /D_USRDLL /D_WINDLL $^ /link /LTCG /DLL /OUT:$@

%.obj: %.c
	cl /nologo /W3 /WX /GL /c $< /Fo$@


ifeq ($(OS),Windows_NT)
  OBJECTS := $(patsubst %.o,%.obj,$(OBJECTS))
endif

ifeq ($(OS),Linux)
  PLUGIN_OBJECT=svm.so
else ifeq ($(OS),Darwin)
  PLUGIN_OBJECT=svm.dylib
else ifeq ($(OS),Windows_NT)
  PLUGIN_OBJECT=svm.dll
endif

$(PLUGIN_OBJECT): $(OBJECTS)

# Stata uses consistent naming across platforms for library files,
# even if the platforms don't, so we can have a shared target
svm.plugin: $(PLUGIN_OBJECT)

svm.plugin:
	$(CP) $< $@

ifeq ($(wildcard $(STATA)),)
  # TODO: make this more robust, e.g. by trying different paths.
  # you will need to use := instead of = for this, because = makes 'recursive' variables
  $(warning "Unable to locate Stata. You will not be able to run tests.")
else

#notice: $< means 'the first prerequisite' and is basically a super-special case meant for exactly this sort of usage
.PHONY: test
test: svmtest.do plugin
	$(STATA) -e $<
	$(CAT) svmtest.log
endif



# --- clean begins here ---

ifeq ($(OS),Windows_NT)
  BUILD_CRUFT+=*.dll *.obj *.exp *.lib
else
  BUILD_CRUFT+=*.o
  ifeq ($(OS),Darwin)
    BUILD_CRUFT+=*.dylib
  else
    BUILD_CRUFT+=*.so
  endif
endif

.PHONY: clean
# Or, instead of 'rm', 'git clean' can be used. It's much more thorough. However, it also demands you use git with this system, and might be overzealous; an interactive one would be better.
clean:
	-$(RM) *.plugin $(BUILD_CRUFT) *.log
	-cd stata && $(RM) $(BUILD_CRUFT) #this would be better done with patsubst. or better yet, something fully recursive like 'find'. but Windows doesn't have find and BSD and Linux can't agree on its syntax...
