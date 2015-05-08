
OS=$(shell uname)

ifeq ($(OS),Linux)
  STATA=/usr/local/stata
  SHARED_FLAGS=-shared -fPIC   # Note: the stata docs (http://www.stata.com/plugins/) do not mention -fPIC, but they probably haven't used a recent GCC: GCC demands it
  SPI_SYSTEM=OPUNIX	#the Stata Programming Interface (i.e. stplugin.h) name for what OS we're on: because Stata isn't cross-platform enough to just use the standard OS defines.
else ifeq ($(OS),Darwin)
  STATA=/Applications/Stata/Stata.app/Contents/MacOS/Stata
  SHARED_FLAGS=-bundle
  SPI_SYSTEM=APPLEMAC
else
  # TODO: this is only an error for testing, so it shouldn't trigger a problem unless we're doing that.
  $(error "Unsupported OS")
endif

#Default rule
.PHONY: all
all: plugin

.PHONY: plugin
plugin: svm.plugin

# XXX this is not going to hold up once we support VS
ifeq ($(OS),Windows_NT)
else
# assume that non-windows means GCC
svm.plugin: svm.c stata/stplugin.c
	$(CC) $(SHARED_FLAGS) -DSYSTEM=$(SPI_SYSTEM) $^ -o $@
endif

#notice: $< means 'the first prerequisite' and is basically a super-special case meant for exactly this sort of usage
.PHONY: test
test: svmtest.do svm.plugin $(STATA)
	$(STATA) -e $<
	cat svmtest.log

.PHONY: clean
clean:
	$(RM) *.plugin *.o *.log
