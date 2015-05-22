# --- subroutines (i.e. make macros, for use with $(call ...)) ----

# make really makes spaces difficult, and Windows loves spaces
# A particularly obvious bug of this design is that $(wildcard) is *not* idempotent when spaces are involved: the second time around, in a moment painfully reminiscent of bash, the spaces get interpreted as argument delimiteters.
# but unlike bash, as far as I know you can't use quotes to keep the arguments together: make just sticks the quotes into your string.
# So we degenerate to *re-escaping*, just this trick:
# http://blog.jgc.org/2007/06/escaping-comma-and-space-in-gnu-make.html
empty:=
space:= $(empty) $(empty)
EscapeSpace=$(subst $(space),\$(space),$(1))

# 
# this gets overridden by the Windows branch
# from <TODO>
FixPath = $1

# Make does not offer a recursive wildcard function, so here's one:
# (from LightStruk @ http://stackoverflow.com/questions/3774568/makefile-issue-smart-way-to-scan-directory-tree-for-c-files)
rwildcard=$(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))


# credits to [GMSL](http://gmsl.sourceforge.net/) for this routine
define chop
$(wordlist 2,$(words $(1)),x $(1))
endef


# Extended include routine which helps building non-recursive makefiles
# you have to write all your file paths with $(PWD)/ prefixed,
# and you need to run it as $(eval $(call cludine,<path/to/submakefile1> <path/to/submakefile2>))
# but these are the only nuisances
#
#
# this works by, as suggested at http://evbergen.home.xs4all.nl/nonrecursive-make.html,
#  keeping the current directory available in a variable (which you cannot do with 'pwd')
# --> if make just had something like __FILE__ this wouldn't be a problem. argh.
# however this approach is simpler: you don't need any boilerplate in the submakefiles.
#
# 
#
# notice: all the evals are necessary to achieve anything within a macro, see
# http://stackoverflow.com/questions/5751099/defining-variables-within-a-makefile-macro-define
# because macros were primarily designed as text hacking abilities
ifndef PWD #set up a default PWD, if the system hasn't already set it
  ifeq ($(OS),Windows_NT)
    PWD:=$(shell cd) #from http://www.lemoda.net/windows/windows2unix/windows2unix.html
  else
    PWD:=$(shell pwd)
  endif
endif
define _cludine
# push
$(eval _PWD:=$(_PWD) $(PWD))
$(eval PWD:=$(dir $(1)))
# call
$(eval include $(1))
# pop
$(eval PWD:=$(lastword $(_PWD)))
$(eval _PWD:=$(call chop,$(_PWD)))
endef
define cludine
$(foreach i,$(1),$(eval $(call _cludine,$(i))))
endef

