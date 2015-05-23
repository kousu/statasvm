#!bin/sh

shift;
SOURCE=$0; shift
TARGET=$0 $1

# a proxy which shows you the data going over it
# it does this by making two nc's: one that listens publically (the "source") and one that sends its output to target, and the loop is completed with a fifo that sends output from 
# *and* the
# (we use tee /dev/stderr to tap the data, stderr because stdout is for the actual data, tho it would be nice if stdout for tee, but | is hardcoded to use stdout; maybe there's a way to reassign fds to get it to behave like I want, but that's just nice to have)
# you could do this with some socat line, but then you'd have to understand socat instead of just unix pipes
mkfifo loop; (sudo nc -k -v -l $SOURCE < loop | tee /dev/stderr | nc $TARGET | tee /dev/stderr > loop ); rm loop

#... I don't know why the second nc stays listening for new connections, but it does.
