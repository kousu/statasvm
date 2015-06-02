#!/bin/sh
# demonstrate the same as classfail.py, using the libsvm command line tools

FIT="_fit.model"
D=${1:-"classification_bug.svmlight"}
P="P"

echo "classfail.sh" &&
echo &&

svm-train -b 1 "$D" "$FIT" >/dev/null &&

echo "Incorrect values" &&
svm-predict -b 0 "$D" "$FIT" "$P" && sort "$P" | uniq -c &&
echo &&

echo "Correct values" &&
svm-predict -b 1 "$D" "$FIT" "$P" && 
  head -n 1 "$P" &&
  tail -n +2 "$P" | cut -f 1 -d " " | sort | uniq -c


rm -f $FIT $P 2>/dev/null
