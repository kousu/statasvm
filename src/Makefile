
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

#TODO: is there any way to get make to catch instead of ignore empty $(STATA)s? one way: generate a filename that definitely doesn't exist (super flakey); two way: write an explicit if that catches this cases 

OS:=$(shell uname)

ifeq ($(OS),)
  # if uname fails, try to guess if we're on Windows
  ifdef SystemRoot
    OS:=Windows_NT
    #this is what mingw's uname gives; be consistent with it to make things simple
  else
    $(warning "Unable to determine OS.")
  endif
endif

ifeq ($(OS),Linux)
  STATA=/usr/local/stata/stata
  SHARED_FLAGS=-shared
  CFLAGS+=-fPIC   # Note: the stata docs (http://www.stata.com/plugins/) do not mention -fPIC, but they probably haven't used a recent GCC: GCC demands it
  SPI_SYSTEM=OPUNIX	#the Stata Programming Interface (i.e. stplugin.h) name for what OS we're on: because Stata isn't cross-platform enough to just use the standard OS defines.
else ifeq ($(OS),Darwin)
  STATA=/Applications/Stata/Stata.app/Contents/MacOS/Stata
  SHARED_FLAGS=-bundle
  SPI_SYSTEM=APPLEMAC
else ifeq ($(OS),Windows_NT)
  #TODO
  # - set flags
  # - *detect whether we have MinGW or VS*
else
  # TODO: this is only an error for testing, so it shouldn't trigger a problem unless we're doing that.
  $(error "Unsupported OS '$(OS)'")
endif


ifeq ($(OS),Windows_NT)
  CAT=read
else
  CAT=cat
endif

CFLAGS+="-DSYSTEM=$(SPI_SYSTEM)" #required by stplugin.h; if you get weird errors about STDLL, this is what you're missing


.PHONY: all
all: plugin

.PHONY: plugin
plugin: svm.plugin

# strange, make comes with .LIBPATTERNS yet doesn't come with rules for actually making .so files
%.so:
	$(CC) -shared $(CFLAGS) $^ -o $@
%.dylib:
	$(CC) -bundle $(CFLAGS) $^ -o $@ #or should this be -dynamiclib? it gives a different filetype, but still works
%.dll:
	# MinGW: gcc -shared -mno-cygwin $^ -o $@
	# Visual Studio: cl /DLL somethingsomething #the proper command line is listed in the Visual Studio C/C++ configuration pane if you go to the verrrry last page in a DLL project
	# Borland: ....
	# Intel: ???

OBJECTS = svm.o stata/stplugin.o


ifeq ($(OS),Linux)
PLUGIN_OBJECT=svm.so
else ifeq ($(OS),Darwin)
PLUGIN_OBJECT=svm.dylib
else ifeq ($(OS),Windows_NT)
PLUGIN_OBJECT=svm.dll
endif

$(PLUGIN_OBJECT): $(OBJECTS)

# Stata uses consistent naming across platforms for library files, even if the platforms don't
svm.plugin: $(PLUGIN_OBJECT)

svm.plugin:
	cp $< $@

ifeq ($(wildcard $(STATA)),)
  # TODO: make this more robust, e.g. by trying different paths.
  # make doesn't let you reassign variables, even if you try to do a swaperoo, because it's super declarative (they are 'recursive' variables and disallowed)
  $(warning "Unable to locate Stata. You will not be able to run tests.")
else
#notice: $< means 'the first prerequisite' and is basically a super-special case meant for exactly this sort of usage
.PHONY: test
test: svmtest.do plugin $(STATA)
	$(STATA) -e $<
	$(CAT) svmtest.log
endif

.PHONY: clean
# Or, instead of 'rm', 'git clean' can be used. It's much more thorough. However, it also demands you use git with this system, and might be overzealous; an interactive one would be better.
clean:
	$(RM) *.plugin *.o *.so *.dll *.log
	cd stata; $(RM) *.plugin *.o *.so *.dll *.log
