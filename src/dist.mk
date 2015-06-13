# --- Distribution ---
# This section 
# Two main targets:
#   release - zips up the source
#   dist    - collects and creates the files necessary for an online Stata repo
#     unfortunately, because it is impossible to do all the building on one machine,
#     this only collects whatever it finds. You will need to manually merge the various builds.

$(call FixPath,../statasvm.%):
#at this writing, git doesn't let you say ".." as a path: it thinks it's "out of the repository", so instead we cd and hardcode the filename
	cd .. && git archive --format=$* -o statasvm.$* HEAD

ifndef RELEASE_FORMAT
  RELEASE_FORMAT:=zip
endif
.PHONY: release
release: ../statasvm.$(RELEASE_FORMAT)


ifeq ($(wildcard bin/),) #if bin/ does not not exist
# trick make
.PHONY: bin-warning
bin-warning:
	@echo --------------------------------------------------------------
	@echo No bin/ folder found. Please \'make\' first.
	@echo
	@echo You cannot \'make dist\' directly, because to do a proper
	@echo distribution you need to \'make\' on all the different build
	@echo  machines and manually sync their results. 
#	and in particular there's no way to arrange svm.pkg to pick up bin/
#	files which don't exist at the start of make, because make expands depends eagerly
	@echo --------------------------------------------------------------
	@false

#dist: bin-warning
bin_target_yesplz_now:
	$(MAKE) plugin

dist: bin_target_yesplz_now

endif

DIST:=$(wildcard *.ado *.sthlp bin/*/* ancillary/*)
DIST:=$(patsubst %,dist/svm/%,$(DIST))
#$(info DIST=$(DIST))

dist: $(DIST)

# copy listed files into the distribution directory
dist/svm/%: %
#	# make does not have any way to specify "subdirectories depend on parent directories",
#	# so recursive make is the only way to go
	@echo "Rule 1"
	@-$(MKDIR) $(call FixPath,$(dir $@)) 2>$(NULL) || echo >$(NULL)
	$(CP) $(call FixPath,$<) $(call FixPath,$@)

# one of the built in rules is
# %: %.o
#	$(CC) $(LDFLAGS) "$<" -o "$@"
# and the rules below are falling back on it, for some reason:
# make dist/svm/ thinks it needs to make dist/svm/.o because it stems %=dist/svm/
#  but if so, why doesn't "make dist/svm" do this??



# tricky:
# the mixed lazy and eager evaluation modes of make are tripping me up
# DIST is lazy, which means it is evaluated *anew* everytime it is asked for
# but dependencies are always evaluated eagerly
# so saying "the .pkg file depends on having all these other files in place"
# *doesn't work* under "make clean; make dist" because after make clean bin/*/* is missing, so dist/%.pkg ends up only depending on the .ado files
# but it *does* under "make clean; make; make dist"
# Something is creaking badly here.


.PHONY: pkg
pkg: dist dist/svm.pkg dist/stata.toc

ifneq ($(OS),Windows_NT)
# These scripts don't work under Windows, so simply don't define them on Windows
dist/stata.toc: ../scripts/maketoc dist
	"$<" $(dir $@) "$(DESCRIPTION)"
dist/stata.toc: DESCRIPTION:=nguenthe's Stata repo


dist/%.pkg: ../scripts/makepluginpkg dist 
	"$<" "$@" "$(DESCRIPTION)" "$(AUTHOR)"
endif
	
	
# quick hack: deploy to my personal account
# this puts up a Stata repo so that
# .net from http://csclub.uwaterloo.ca/~$USER/stata/
# works
# This can probably be massaged into something more reasonable
# Of course, proper deployment means publishing in the Stata journal and a posting to the SSC
# which is not something that can be automated.
.PHONY: deploy
deploy: dist
	ssh csclub.uwaterloo.ca -- rm -r www/stata
	scp -r dist/ csclub.uwaterloo.ca:www/stata
	ssh csclub.uwaterloo.ca -- 'find www/stata -type d -exec chmod 755 {} \;'
	ssh csclub.uwaterloo.ca -- 'find www/stata -type f -exec chmod 644 {} \;'


# --- cleaning ---
dist-clean: clean

.PHONY: dist-clean
dist-clean:
	-$(RMDIR) dist
