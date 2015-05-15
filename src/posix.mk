# common POSIX parts. Makefile.{Linux,OpenBSD,FreeBSD,NetBSD,Darwin} all inherit from this
# the values in here correspond to the

DLLEXT:=so

CFLAGS+=-Wall -Werror
CFLAGS+=-fPIC   # Note: the stata docs (http://www.stata.com/plugins/) do not mention -fPIC, but they probably haven't used a recent GCC: GCC demands it
CFLAGS+=-std=c99 #arrrrgh

# strange, make comes with .LIBPATTERNS yet doesn't come with rules for actually making .so files
%.so:
	$(CC) $(LDFLAGS) $(foreach L,$(LIBS),-l$L) $^ -o $@


#svm.plugin: $(OS)/$(ARCH)/svm.plugin

# --- testing ---

STATA := $(shell which stata)
ifndef STATA
  # quick hack: be just a little bit case insensitive
  STATA := $(shell which Stata)
endif

ifneq ($(OS),Darwin) #dirty, encapsulation-breaking hack: avoid the warning about redefining printdeps (make wasn't realllly designed with OOPey inheritence in mind)
printdeps:
	readelf -d $^
endif

# --- cleaning ---

.PHONY: clean-posix
clean-posix:
	-$(RM) *.so


clean: clean-posix
