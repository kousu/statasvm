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

DIST:=$(wildcard *.ado *.sthlp bin/*/*)
DIST:=$(patsubst %,dist/svm/%,$(DIST))

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
dist: bin-warning
endif


dist: dist/svm.pkg $(DIST)
dist: dist/stata.toc

# tricky:
# the mixed lazy and eager evaluation modes of make are tripping me up
# DIST is lazy, which means it is evaluated *anew* everytime it is asked for
# but dependencies are always evaluated eagerly
# so saying "the .pkg file depends on having all these other files in place"
# *doesn't work* under "make clean; make dist" because after make clean bin/*/* is missing, so dist/%.pkg ends up only depending on the .ado files
# but it *does* under "make clean; make; make dist"
# Something is creaking badly here.

# XXX clean this up
# factor out the 'make stata repos' and 'make stata packages' parts
dist/stata.toc: ../scripts/maketoc
	@mkdir -p $(dir $@)
	../scripts/maketoc $(dir $@) "$(DESCRIPTION)"

dist/stata.toc: DESCRIPTION:=nguenthe's Stata repo


dist/%.pkg: $(DIST) ../scripts/makepluginpkg
	@mkdir -p $(dir $@)
	../scripts/makepluginpkg "$@" "$(DESCRIPTION)" "$(AUTHOR)"

# copy listed files into the distribution directory
dist/svm/%: %
	@mkdir -p $(dir $@)
	$(CP) $< $@
	

# --- cleaning ---
clean: clean-dist

.PHONY: clean-dist
clean-dist:
	-$(RMDIR) dist
