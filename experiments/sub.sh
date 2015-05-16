#!/bin/sh

# hobo makefile
stata -e sub.do && cat sub.log && rm sub.log
