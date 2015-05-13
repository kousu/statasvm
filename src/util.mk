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
