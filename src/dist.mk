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



# this splitting + recursive make weirdness is because $(wildcard) needs to get evaluated *after*
# the build has happened, but all $(wildcard)s are eval'd at Makefile-scan time, not Makefile-exec time
dist: all
	$(MAKE) _dist

DIST:=$(wildcard *.ado *.sthlp bin/*/* ancillary/*)
DIST:=$(patsubst %,dist/svm/%,$(DIST))
#$(info DIST=$(DIST)) #DEBUG
_dist: $(DIST)

# copy listed files into the distribution directory
dist/svm/%: %
#	# make does not have any way to specify "subdirectories depend on parent directories",
#	# so recursive make is the only way to go. || echo is a cross-platform NOP, like || true,
#	# which is to silence the error that comes if the directory already exists which is, again,
#	# because it's easier than figuring out a cross-platform "if [ -d ... ]"
	@-$(MKDIR) $(call FixPath,$(dir $@)) 2>$(NULL) || echo >$(NULL)
	$(CP) $(call FixPath,$<) $(call FixPath,$@)


pkg: dist dist/svm.pkg dist/stata.toc

ifneq ($(OS),Windows_NT)
 # These scripts don't work under Windows, so simply don't define them on Windows
.PHONY: dist/stata.toc
dist/stata.toc: ../scripts/maketoc dist
	"$<" $(dir $@) "$(DESCRIPTION)"
dist/stata.toc: DESCRIPTION:=nguenthe's Stata repo

.PHONY: dist/svm.pkg
dist/svm.pkg: ../scripts/makepluginpkg dist
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
	-ssh csclub.uwaterloo.ca -- rm -r www/stata
	scp -r dist/ csclub.uwaterloo.ca:www/stata
	ssh csclub.uwaterloo.ca -- 'find www/stata -type d -exec chmod 755 {} \;'
	ssh csclub.uwaterloo.ca -- 'find www/stata -type f -exec chmod 644 {} \;'


# --- cleaning ---
dist-clean: clean

.PHONY: dist-clean
dist-clean:
	-$(RMDIR) dist
