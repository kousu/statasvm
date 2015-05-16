#!/usr/bin/env python3
# clip a svmlight file to the lowest-numbered 2047 features because Stata upsells itself
# (this is meant to be compatible with what svm_load.ado does)

import sys

if __name__ == '__main__':
	
	outfile = "-" # TODO: support '-o' for giving output somewhere besides stdout
	MAX = 2046
	if outfile == "-":
		sys.stdout = sys.stdout
	else:
		sys.stdout = open(outfile, "w")
	
	for fname in sys.argv[1:]:
		if fname == "-":
			file = sys.stdin
		else:
			file = open(fname)
		for line in file:
			y, line = line.split(maxsplit=1)
			line = [y] + [token for token in line.split() if int(token.split(":")[0]) <= MAX]
			line = str.join(" ", line)
			print(line)
			
