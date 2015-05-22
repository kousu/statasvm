#!/bin/sh

echo Putting the package repo online
echo Contents:
ls -l --color=auto
echo use ". net from http://localhost:8000" to test it out
HERE=$(dirname $0)
cd $HERE/../src/dist &&
python -m SimpleHTTPServer || python -m http.server || webfsd -d . 

