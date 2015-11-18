# --- Testing ----

# run 'make -k tests' to let tests run even with failure, or 'make tests' to stop when tests stop you

# rules to auto-download datasets from the libsvm sample archive
# XXX this is hardcoded to only get *binary* ones. maybe we should instead include "datasets/binary/" in the target path (which might be more reasonable, anyway)
tests/%.svmlight: tests/%.bz2
	bunzip2 -d $<
	mv tests/$* tests/$*.svmlight

tests/%.bz2:
	wget http://www.csie.ntu.edu.tw/~cjlin/libsvmtools/datasets/binary/$*.bz2 -O $@

# add test-specific files
tests/preload tests/load: tests/duke.svmlight
$(call FixPath,tests/auto.model): tests/export #the make manual claims on Windows all paths use forward slashes and only forward slashes, but apparently this doesn't apply to targets, only prerequisites.
     # maybe what I should do is give up and move all this into a sub Makefile and use recursive make to avoid dealing with path separators.
tests/import: tests/auto.model #for example, this one is created by export.do, and so that has to run first; stating it like this lets make figure that out

# for each .do file in tests/, make a .PHONY test_<testname> target which runs Stata and prints the output
# the meta-target test runs all tests
# TODO: Stata always returns 0 so make doesn't know if a test fails or not, but Stata does print error codes out, so I need to write a wrapper that translates these to OS-level return codes

## find all tests automatically
TESTS:=$(wildcard tests/*.do)
TESTS:=$(patsubst %.do,%,$(TESTS))

# hardcode the list of tests explicitly: the advantage is controlling the order without doing weird things to test naming
#TESTS:=$(shell $(CAT) $(call FixPath,tests/order.lst))
#TESTS:=$(patsubst %,tests/%,$(TESTS))


# force tests to do a rebuild (if necessary) before running
# now that we have multiple things to build this is not so simple
# XXX is there a cleaner way?
$(TESTS): plugin
tests/preimport_svmlight tests/import_svmlight tests/export_svmlight: _svmlight.plugin
tests/auto.model: tests/export
tests/getenv: _getenv.plugin
tests/setenv: _setenv.plugin



## Main Test Harness Logic


.PHONY: tests
tests: $(TESTS)

STATA:=../scripts/stata

tests/%: tests/%.do
	"$(call FixPath,$(STATA))" $(call FixPath,$<)
  
# auto-wrap tests with the code in tests/helpers/
# Stata doesn't pass command line arguments to batch scripts
# *and* it doesn't let us control where stdout goes --- it insists on naming the output <basename>.log
# So to convince Stata to do roughly the right thing, we borrow a page from Microsoft: code generation and temporary files
# Stata *insists* the file extension for `stata -b file` be '.do';
# it exits silently and without error but without doing what I want otherwise.
# Hence, these wrapped files are given identical names but stuffed in a subdir to distinguish them.
#
# The order of dependencies *is the order the commands are concatenated*.
#
# The last couple of lines are key: a) 'capture' so a crash doesn't hang the tests b) save the _rc code to a file c) exit, with the STATA option to make the whole thing come down d) then go up to tests/% and read out the output file and pass it up (i.e. to make) so that error codes actually stop make
# TODO: after the 'capture' write _rc to a result file and then check it
tests/wrapped/%.do: tests/wrapped/ tests/helpers/settings.do tests/%.do
#	# 'set trace' gets reset to its old value when a 'do' ends
#	# since half the point of settings.do is 'set trace on'
#	# we need to instead frankenstein settings.do inline into the final .do file
	echo quietly { > $(call FixPath,$@)
	$(CAT) $(call FixPath,tests/helpers/settings.do) >> $(call FixPath,$@)
	echo } >> $(call FixPath,$@)
#	# now include the actual content
	echo capture noisily do $(call FixPath,tests/$*.do) >> $(call FixPath,$@)
	echo di _rc >> $(call FixPath,$@)
	echo "shell echo "\`=_rc\'" > $*.out" >> $(call FixPath,$@)
	echo exit, clear STATA >> $(call FixPath,$@)
	
# it's a bad idea to have directories as targets, but there's no cross-platform way to say "if directory already exists, don't make it";
tests/wrapped/:
	$(MKDIR) $(call FixPath,$@) 2>$(NULL)

    
#.INTERMEDIATE: $(patsubst test_%,%.log,$(TESTS)) # this is commented out because it breaks under Win32 gmake, causing the files to *not* be deleted at finish.


# --- cleaning ---

clean: clean-tests

.PHONY: clean-tests
clean-tests:
	-$(RM) $(call FixPath,tests/*.model)
	-$(RMDIR) $(call FixPath,tests/wrapped)
