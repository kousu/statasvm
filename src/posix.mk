# common POSIX parts. Makefile.{Linux,OpenBSD,FreeBSD,NetBSD,Darwin} all inherit from this
# the values in here correspond to the

DLLEXT:=so

CFLAGS+=-Wall -Werror
CFLAGS+=-fPIC   # Note: the stata docs (http://www.stata.com/plugins/) do not mention -fPIC, but they probably haven't used a recent GCC: GCC demands it

# strange, make comes with .LIBPATTERNS yet doesn't come with rules for actually making .so files
%.so:
	$(CC) $(CFLAGS) $(LDFLAGS) $(foreach L,$(LIBS),-l$L) $^ -o $@


#svm.plugin: $(OS)/$(ARCH)/svm.plugin

# --- testing ---

STATA := $(shell which stata)
ifndef STATA
  # quick hack: be just a little bit case insensitive
  STATA := $(shell which Stata)
endif

# --- cleaning ---

.PHONY: clean-posix
clean-posix:
	-$(RM) *.so


clean: clean-posix
