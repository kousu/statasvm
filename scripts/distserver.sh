#!/bin/sh

HERE=$(dirname $0)
cd $HERE/../src/dist &&
echo Putting the package repo online &&
echo Contents: &&
ls -l &&
echo use ". net from http://localhost:8000" to test it out &&
# try several common basic HTTP servers which are probably on-system
# (this 
(python -m SimpleHTTPServer || python -m http.server || webfsd -d . ) 2>/dev/null 

