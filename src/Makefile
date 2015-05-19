
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

#NB: this template rule doesn't have any dependencies specified, but is uses them ($^).
#    this means you need to give them, by saying, e.g. `mylib.dll: mymain.obj myutil.obj`

# TODO:
# [ ] document clearly how much this depends on your environment variables

# --- includes ---

include util.mk

# --- config ---

# extend the list of $(CC), $(YACC), ... with extra standard programs variables
# so that we can tolerate the POSIX incompatible parts of Windows by override.
WHICH=which
NULL=/dev/null
CP=cp
CAT=cat
MKDIR=mkdir -p




# --- build declarations  ---

NAME:=_svm

# Compiled but unlinked object files
# These assume POSIX (XXX maybe we should `include posix.mk` unconditionally, and then override it, since most of the builds are basically posix)
CODE := $(call rwildcard,./,*.c)
OBJECTS := $(patsubst %.c,%.o,$(CODE))

LIBS += svm


# --- platform detection ---


.PHONY: all #this has to come before we include <OS>.mk, because it has to be the first rule
all: plugin

# Windows defines the OS variable, everywhere else has uname, so check for Windows first
ifneq ($(OS),Windows_NT)
  OS:=$(shell uname -s)
  ARCH:=$(shell uname -m)
endif

ifeq ($(wildcard $(OS).mk),)
  $(error "Unsupported OS '$(OS)'")
else
  include $(OS).mk
endif

# --- rules ---


.PHONY: plugin
plugin: $(NAME).plugin

$(NAME).$(DLLEXT): $(OBJECTS)

# Stata uses consistent naming across platforms for library files,
# even if the platforms don't, so we can have a shared target
# TODO: do platform-specific builds under build/$(OS)/$(ARCH)/ (and then link or copy the final result to ./svm.plugin)
#       we will ultimately distribute all of $(OS)/$(ARCH)/svm.plugin to everyone, since that's about the best we can do given Stata's simplistic package management system.
$(NAME).plugin: $(NAME).$(DLLEXT)
	$(CP) $(call FixPath,$<	) $(call FixPath,$@)

# (this would do the 'and then link' step)
#$(NAME).plugin: $(OS)/$(ARCH)/$(NAME).plugin
#	$(CP) $(call FixPath,$<) $(call FixPath,$@)




# debugging tool: show the DLL dependencies as recorded in the DLL's metadata
# the platform-specific subfiles should have defined a working platform-specific recipe to actually carry this out; we just define the target here.
# BEWARE: this must be *before* the recipes are defined (in contrast to the implicit rules and(?) in contrast to pattern rules)
#         or else you get "warning: overriding commands for target `printdeps'"
.PHONY: printdeps
printdeps: $(NAME).plugin


# --- Testing ----
ifeq ($(wildcard $(call EscapeSpace,$(STATA))),)
  # TODO: make this more robust, e.g. by trying different paths.
  $(warning "Unable to locate Stata. You will not be able to run tests.")
else


# rules to auto-download datasets from the libsvm sample archive
# XXX this is hardcoded to only get *binary* ones. maybe we should instead include "datasets/binary/" in the target path (which might be more reasonable, anyway)
tests/%.svmlight: tests/%.bz2
	bunzip2 -d $<
	mv tests/$* tests/$*.svmlight

tests/%.bz2:
	wget http://www.csie.ntu.edu.tw/~cjlin/libsvmtools/datasets/binary/$*.bz2 -O $@

# add test-specific files
test_load test_train test_export test_preload: tests/duke.svmlight
tests/duke.model: test_export #XXX this isn't working right: because test_export is .PHONY, make thinks that tests/duke.model is also .PHONY. This doesn't make a difference in 'make test' but you really want to be able to run test_import in isolation to see that it really is reading the file and not the result of svm_train()
test_import: tests/duke.model #for example, this one is created by test_export, and so that has to run first; stating it like this lets make figure that out

# for each .do file in tests/, make a .PHONY test_<testname> target which runs Stata and prints the output
# the meta-target test runs all tests
# TODO: catch errors using Stata's "capture" command and actually fail the build

  TESTS:=$(patsubst tests/%.do,test_%,$(wildcard tests/*.do))
  
  .PHONY: test
  test: $(TESTS)
  
  # stata -b is 'batch mode', i.e. it's the closest Stata has to running "Rscript" or "ruby" or "python"
  # -e is identical to -b, except it suppresses the completion notification message
  # If this seems absurd, remember that Stata is targeted at GUI-heavy Windows users,
  # and that the most scripting they are likely to do is to run a big computation overnight.
  
  # auto-wrap tests with the code in tests/helpers/
  # Stata doesn't pass command line arguments to batch scripts
  # *and* it doesn't let us control where stdout goes --- it insists on naming the output <basename>.log
  # So to convince Stata to do roughly the right thing, we borrow a page from Microsoft: code generation and temporary files
  # Stata *insists* the file extension for `stata -b file` be '.do';
  # it exits silently and without error but without doing what I want otherwise.
  # Hence, these wrapped files are given identical names but stuffed in a subdir to distinguish them.
  #
  # The order of dependencies *is the order the commands are concatenated*.
  tests/wrapped/%.do: tests/helpers/settings.do tests/%.do tests/helpers/inspect_model.do
	$(CAT) $^ > $@
  
  #  because Stata doesn't have a tty mode, to fake having stdout we cat Stata's <testname>.log (note that this is in the current directory, not the directory the .do file is in!),
  #  which it generates when run in batch mode, and we mark this .INTERMEDIATE so that make knows to delete it immediately
  %.log: tests/wrapped/%.do
	"$(STATA)" -e $<
  
  #notice: $< means 'the first prerequisite' and is basically a super-special case meant for exactly this sort of usage
  #.PHONY: $(TESTS) #	" Make does not consider implicit rules for PHONY targets" ?? In other words: there is no way to autogenerate .PHONY targets. whyyyyy.
  test_%: %.log plugin
	$(CAT) $<
  
  #.INTERMEDIATE: $(patsubst test_%,%.log,$(TESTS)) # this is commented out because it breaks under Win32 gmake, causing the files to *not* be deleted at finish.
  
  # temporary target to help bug hunt a memory corruption
  # which shows up as inconsistently corrupted svm_save_model() output
  # (this test won't work on Windows, but that I don't need it to work there)
  .PHONY: manyexport
  manyexport:
	while true; do $(MAKE) test_export; $(MV) tests/duke.model tests/duke.model`date +%H%M%S`; done

endif


# --- Cleaning ---

# Tip: consider replacing 'rm' with 'git clean -f', if you are using git. It might be dangerously overzealous but if you've used git right,
# it's much more thorough and reliable about getting your state back to scratch, because it by definition puts the state back to what's checked in.

	
.PHONY: clean
# *.log *should* get cleaned up by the testing recipe, but in case it doesn't or you have made some manually we clean it again here
clean:
	-$(RM) $(foreach o,$(OBJECTS),$(wildcard $(o))) *.plugin *.log *.model
	-$(RM) tests/*.model tests/wrapped/*.do
	#-$(RM) -r build/

