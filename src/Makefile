
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
# - $(wildcard <path>) can be used to ensure that the path exists, and this is the more common use of it in this makefile
# - `ifdef VAR` is the same as `ifeq ($(VAR),)` (that is, there's no such thing as undefined values: a variable either has text or it doesn't exist)
# - Windows's cmd uses ';' to separate parameters, not commands, so you can't say `cmd1; cmd2`.
#    Instead, anytime we would use that instead we use `cmd1 && cmd2` which works on both POSIX and Windows
#    or use two recipe lines, where the first one is prefixed with '-' to mean 'ignore failure'
# - remember that = makes a 'recursive' variable, which really means one that gets lazily-evaluated, whereas := makes an eagerly-evaluated variable; for branching to work as expected := is necessary

# TODO:
# [ ] Turn up the warning level (-Wall or /Wall) and make warnings into errors (-Werror or /WX): this forces the code to be high quality, by nagging you at every single build until you get it right
# [ ] document clearly how much this depends on your environment variables


include util.mk

# --- config ---

# extend the list of $(CC), $(YACC), ... with extra standard programs variables
# so that we can tolerate the POSIX incompatible parts of Windows by override.
WHICH=which
NULL=/dev/null
CP=cp
CAT=cat


# --- build declarations  ---

# Compiled but unlinked object files
# These 
CODE := $(call rwildcard,./,*.c)
OBJECTS := $(patsubst %.c,%.o,$(CODE))

# --- platform detection ---

# first check for Windows; Windows defines the OS
ifneq ($(OS),Windows_NT)
  # assume everywhere except for Windows has uname
  # XXX this might break on e.g. Windows 2000... but that's probably alright.
  OS:=$(shell uname)
endif

ifeq ($(wildcard $(OS).mk),)
  $(error "Unsupported OS '$(OS)'")
endif

include $(OS).mk

# --- rules begin here ---

.PHONY: all
all: plugin

.PHONY: plugin
plugin: svm.plugin

svm.$(DLLEXT): $(OBJECTS)

# Stata uses consistent naming across platforms for library files,
# even if the platforms don't, so we can have a shared target
svm.plugin: svm.$(DLLEXT)
	$(CP) $< $@

# --- Testing ----
ifeq ($(wildcard $(call EscapeSpace,$(STATA))),)
  # TODO: make this more robust, e.g. by trying different paths.
  $(warning "Unable to locate Stata. You will not be able to run tests.")
else



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
  
  #  because Stata doesn't have a tty mode, to fake having stdout we cat Stata's <testname>.log (note that this is in the current directory, not the directory the .do file is in!),
  #  which it generates when run in batch mode, and we mark this .INTERMEDIATE so that make knows to delete it immediately
  %.log: tests/%.do
	"$(STATA)" -e $<
  
  #notice: $< means 'the first prerequisite' and is basically a super-special case meant for exactly this sort of usage
  #.PHONY: $(TESTS) #	" Make does not consider implicit rules for PHONY targets" ?? In other words: there is no way to autogenerate .PHONY targets. whyyyyy.
  test_%: %.log plugin
	$(CAT) $<
  
  #.INTERMEDIATE: $(patsubst test_%,%.log,$(TESTS)) # this is commented out because it breaks under Win32 gmake, causing the files to *not* be deleted at finish.
endif


# --- Cleaning ---

# Tip: consider replacing 'rm' with 'git clean -f', if you are using git. It might be dangerously overzealous but if you've used git right,
# it's much more thorough and reliable about getting your state back to scratch, because it by definition puts the state back to what's checked in.

	
.PHONY: clean
# *.log *should* get cleaned up by the testing recipe, but in case it doesn't or you have made some manually we clean it again here
clean:
	-$(RM) $(foreach o,$(OBJECTS),$(wildcard $(o))) *.plugin *.log
