

DESC="stuff"
AUTHOR="nguenthe"

# See Stata's "[R] net" documentation, subsection "Creating your own site":
# http://www.stata.com/manuals14/rnet.pdf

# this [part of the] Makefile is POSIX-only, but that should be okay because our webserver will also be POSIX-only

TITLE=svm

all: $(TITLE).pkg

$(TITLE).pkg:
	echo v 3 > $@
	# this line prints the title, which Stata's docs say should be the first 'd'(escription) line
	echo d $(TITLE) >> $@
	echo d $(DESC) >> $@
	echo d $(AUTHOR) >> $@
	echo >> $@
	
	# -type f == files only (because listing directories in a .pkg is silly)
	# we run find twice, because files under bin/ are special: they are platform-specific binaries.
	find . -type f \( -name "bin" -prune -o -print \)  | grep -v Makefile | grep -v $@ | awk '{ print "f " $$1 }' >> $@
	find bin -type f | awk '{ split($$1,A,"/"); print "g " A[2] " " $$1 }' >> $@


