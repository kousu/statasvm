
# This is a cross-platform makefile
#

# tips gleaned from 
# - http://stackoverflow.com/questions/4058840/makefile-that-distincts-between-windows-and-unix-like-systems
# - http://stackoverflow.com/questions/7876876/tell-if-make-is-running-on-windows-or-linux
# - http://make.mad-scientist.net/papers/rules-of-makefiles/
# - http://make.mad-scientist.net/papers/how-not-to-use-vpath/
# http://stackoverflow.com/questions/8937500/how-to-generate-list-of-make-targets-automatically-by-globbing-subdirectories
#   which demonstrates that to "generate" targets, you instead use wildcard + patsubst to generate *dependencies*, and then use pattern rules (% signs) that match the format of the dependencies.
# - and  by digging through `make -p`, which shows all defined rules, including the huge spate of implicit rules, on different platforms
# - http://stackoverflow.com/questions/1077676/how-to-conditional-set-up-a-makefile-variable-by-testing-if-a-file-exists
# though they aren't all totally relevant to what we're doing her
# and of course, the canonical reference
# - http://www.stata.com/plugins/#sect5

# idioms:
# - for each OS (as defined by the strings the OSes use to name themselves: i.e. whatever `uname -s` gives or %OS% for Windows), there should be a <OS>.mk file for platform-specific values and build rules.
#    - posix.mk is provided for the POSIX OSes (i.e. most of them) to include, saving duplication.
# - $(wildcard <path>) can be used to ensure that the path exists, and this is the more common use of it in this makefile
# - `ifdef VAR` is the same as `ifeq ($(VAR),)` (that is, there's no such thing as undefined values: a variable either has text or it doesn't exist)
# - Windows's cmd uses ';' to separate parameters, not commands, so you can't say `cmd1; cmd2`.
#    Instead, anytime we would use that instead we use `cmd1 && cmd2` which works on both POSIX and Windows
#    or use two recipe lines, where the first one is prefixed with '-' to mean 'ignore failure'
# - remember that = makes a 'recursive' variable, which really means one that gets lazily-evaluated, whereas := makes an eagerly-evaluated variable; for branching to work as expected := is necessary
# - %.ext2:
#      <recipe> $^
#   defines a templated way to build .ext files without specifying which ones to build. It is meant to be used with a recipeless 'target.ext2: fileA.ext1 fileB.ext1'
# - to rename a file (which you might want to do if there's a pattern rule for one file extension but you want its outcome to be another) you must use $(LN) or $(CP),
#   because $(MV) will cause make to see that a dependency is missing and then behave inconsistently, either always rebuilding or do different subsections of the sequence each run or not doing anything.

#NB: this template rule doesn't have any dependencies specified, but is uses them ($^).
#    this means you need to give them, by saying, e.g. `mylib.dll: mymain.obj myutil.obj`

# TODO:
# [ ] document clearly how much this depends on your environment variables
# [ ] the plugin should be a subproject with a submakefile, ideally makeable on its own but separate from the ado files
#    that will let this build system be adapted to multi-plugin packages

#this has to come before we include anything, because it has to be the first rule
all: plugin


MAKEFLAGS+=--no-print-directory

PKG:=svm

# --- includes ---

# these have to come *before* the rules in this file,
# so that "make dist/svm/bin/WIN64A/libsvm.dll" will be handled by the rule in dist.mk
# and not by the rule for %.$(DLLEXT)
# I don't really understand
# see https://www.gnu.org/software/make/manual/html_node/Pattern-Match.html and try to figure it out:
# " make will choose the rule with the shortest stem "

include test.mk

include dist.mk


include util.mk

# --- build declarations  ---

AUTHOR:=Nick Guenther <nguenthe@uwaterloo.ca> and Matthias Schonlau <schonlau@uwaterloo.ca>
DESCRIPTION:=Support Vector Machines for both Classification and Regression

# --- platform detection ---

# Our platform as far as we care is two pieces: the $(OS) and the processor $(ARCH)
# These are the standard forms used most places: {Windows_NT,Darwin,Linux,....}, and {i386, x86_64}
#
# Stata knows this information too, and at runtime offers it as c(os) and c(bit),
# but its strings are different: {Windows,MacOSX,Unix} and {32,64}
# Additionally, at *package time* it has an entirely different scheme,
# documented in [R]->net->Creating your own site->Additional package directives:
# {Windows,32} -> {WIN}
# {Windows,64} -> {WIN64A}  #notice the 'A'!
# {MacOSX64,32} -> {MACINTEL}
# {MacOSX64,64} -> {MACINTEL64}
# {Unix,32} -> {LINUX} #because there's apparently no other Unices
# {Unix,64} -> {LINUX64}


# Windows defines the OS variable, everywhere else has uname, so check for Windows first
ifneq ($(OS),Windows_NT)
  OS:=$(shell uname -s)
  ARCH:=$(shell uname -m)
endif


ifeq ($(wildcard $(OS).mk),)
  $(error "Unsupported OS '$(OS)'")
endif




# debugging tool: show the DLL dependencies as recorded in the DLL's metadata
# the platform-specific subfiles should have defined a working platform-specific recipe to actually carry this out; we just define the target here.
# BEWARE: this must be *before* the recipes are defined (in contrast to the implicit rules and(?) in contrast to pattern rules)
#         or else you get "warning: overriding commands for target `printdeps'"
.PHONY: printdeps
printdeps: $(PLUGIN).plugin


include $(OS).mk


# now that the platform-specific stuff has loaded,
# compute Stata's package-time platform string
ifeq ($(OS),Windows_NT)
  PLATFORM:=WIN
else ifeq ($(OS),Darwin)
  PLATFORM:=MACINTEL
else
  PLATFORM:=LINUX
endif

ifeq ($(ARCH),x86_64)
  PLATFORM:=$(PLATFORM)64
endif

ifeq ($(PLATFORM),WIN64) #handle the nuisance special case
    PLATFORM:=$(PLATFORM)A
endif


ifeq ($(OS),Windows_NT)
# rules for automatically including bundled DLLs in the build
# this clearly needs to be in Windows_NT.mk, but we don't have PLATFORM computed in there.. ugh

bin/$(PLATFORM)/libsvm.dll: windows/$(ARCH)/libsvm.dll
	@$(MKDIR) $(call FixPath,$(dir $@)) 2>$(NULL) || echo >$(NULL)
	$(LN) $(call FixPath,$<) $(call FixPath,$@)

# specific dist dependencies
# 1) _svm.plugin depends on libsvm
bin/$(PLATFORM)/_svm.plugin: bin/$(PLATFORM)/libsvm.dll
endif


ifeq ($(wildcard bin/$(PLATFORM)),)
# if bin/ does not not exist for the current platform
# we need to do a fresh build
# which I do with recursive make
# TODO: GNU make's system of automatically rebuilding makefiles as needed is a way to workaround the fact that it runs all $(wildcard)s at the init

rebuild:
	$(MAKE) clean
#	# subtlety: all -> rebuild -> plugin, all -> plugin;
#	# if instead rebuild -> all then we would have an infinite recursive make
	$(MAKE) plugin

# override the definition of all
all: rebuild
	@echo -n

endif

# --- rules ---



# Stata uses consistent naming across platforms for library files, loading anything ending in ".plugin" with the platform's particular version of dlopen()
# even if the platforms don't, so we can have a shared target
# TODO: do platform-specific builds under build/$(OS)/$(ARCH)/ (and then link or copy the final result to ./svm.plugin)
#       we will ultimately distribute all of $(OS)/$(ARCH)/svm.plugin to everyone, since that's about the best we can do given Stata's simplistic package management system.

# generic plugin chain: _%.c -> %.o -> %.so -> bin/$(PLATFORM)/_%.plugin -> _%.plugin -> phony "plugin" target
# (except on OS X .so is .dylib and on Windows .o is .obj and .so is .dll) 

plugin: $(patsubst %.c,%.plugin,$(wildcard _*.c))

%.plugin: bin/$(PLATFORM)/%.plugin
	$(LN) $(call FixPath,$<) $(call FixPath,$@)

# prevent the platform-specific plugins getting eaten by make
.SECONDARY: $(patsubst %.c,bin/$(PLATFORM)/%.plugin,$(wildcard _*.c)) #this is ugly because the special targets (like many things in make) can't handle patterns, so we have to generate all the files to mark explicitly
bin/$(PLATFORM)/%.plugin: %.$(DLLEXT)
	@$(MKDIR) $(call FixPath,$(dir $@)) 2>$(NULL) || echo >$(NULL)
	$(LN) $(call FixPath,$<) $(call FixPath,$@)

	
# append the dependencies for which belong to each specific plugin
# You'd think you could make a single pattern rule %.$(DLLEXT): %.$(OBJEXT)
#  but attach more dependencies to specific cases as needed
#   ---> make.html#Match_002dAnything-Rules??
# but GNU make seems to keep pattern rules and explicit rules in separate "name"spaces
# it would also be nice if you could edit the list of depends as if it was a target-specific variable (which, really, it is), so that I could mix branching and substitution in to autogen the depends
# ah, I might be at the outer limits of what GNU make is usable for. le sigh.
# TODO: check this again
#  I think I can do $(patsubst %.c,%.$(DLLEXT),$(wildcard *.c)): %.$(DLLEXT): %.c  which says that for the explicitly named targets on the left, apply the pattern rule on the right, which might make make count this is a /non/ pattern rule.
_svm.$(DLLEXT): $(patsubst %.c,%.$(OBJEXT), _svm.c sttrampoline.c stutil.c stplugin.c)
_svm.$(DLLEXT): libsvm_patches.$(OBJEXT)
_svm.$(DLLEXT): LIBS += svm
_svmlight.$(DLLEXT): $(patsubst %.c,%.$(OBJEXT), _svmlight.c sttrampoline.c stutil.c stplugin.c)
_svm_getenv.$(DLLEXT): $(patsubst %.c,%.$(OBJEXT), _svm_getenv.c stutil.c stplugin.c)
_svm_setenv.$(DLLEXT): $(patsubst %.c,%.$(OBJEXT), _svm_setenv.c stutil.c stplugin.c)
_svm_dlopenable.$(DLLEXT): $(patsubst %.c,%.$(OBJEXT), _svm_dlopenable.c stutil.c stplugin.c)


EXAMPLES:=binary_classification multiclass_classification class_probability regression oneclass
EXAMPLES:=$(patsubst %,ancillary/%_example.do,$(EXAMPLES))
ifneq ($(OS),Windows_NT)
# example2smcl is in awk and so won't run on Windows.
# Instead, a hybrid approach: on POSIX, we rebuild the examples when make detects it's necessary
# but we also check them into the repo so that Windows can be kept in sync without awk.
# (notice that if $(OS) is Windows then this rule simply doesn't exist: make doesn't know about examples when run on Windows)
svm_examples.ihlp: $(EXAMPLES)
	../scripts/example2smcl -v PKG=$(PKG) $^ > $@

all: svm_examples.ihlp
endif

# --- Cleaning ---

# Tip: consider replacing 'rm' with 'git clean -f', if you are using git. It might be dangerously overzealous but if you've used git right,
# it's much more thorough and reliable about getting your state back to scratch, because it by definition puts the state back to what's checked in.

.PHONY: clean
# *.log *should* get cleaned up by the testing recipe, but in case it doesn't or you have made some manually we clean it again here
clean:
	-$(RM) *.o *.plugin *.log *.model
	-$(RMDIR) bin

	
	




