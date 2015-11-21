Stata-SVM Build Machine
=======================

There is a Mac Mini that we use to do builds and tests on.
With the help of VirtualBox it actually runs Windows, OS X, and Linux, and can build five flavours of Stata-SVM.

statasvm-buildbot on OS X
statavm on Windows 7, virtualized on statasvm-buildbot
statavm-linux64 on Ubuntu 15.10, ditto
statavm-linux32 on Fedora 23 (not Ubuntu, for the sake of "bio"diversity), ditto

All four machines have these [administrator] logins:
 nguenthe:h("statasvm-buildbot")
 schonlau:h("schonlau@statasvm-buildbot")

All four have a working build toolchain and Stata installed (which is, technically, against the Stata license, which only allows three simultaneous installs).
On Windows and OS X there is only GUI Stata. The Linuxes have "stata" which is the console version, and "xstata" which is the GUI version; but being closed source,
the GUI version got nipped by bitrot and crashes on Fedora; it runs on Ubuntu.


Note: all the build machines have write access to the master repository---that is, ssh keys to kousu@github.
This is an expedient for handling cross platform bugs:
 - check into the repo
 - pull to everywhere
 - recompile and retest everywhere
 - if bugs: fix and repeat
Doing this without the master repo is possible but a lot more tedious,
because for each change on platform P each platform Q, we need to do "Q pull P"
which requires spending mental effort on tedium, instead of a fixed "P push M, Q pull M"

VirtualBox arranges that From within each VM, statasvm-buildbot is 10.0.2.2, so you can
share files Linux<->OS X with sftp://10.0.2.2 (over ssh) and Windows<->OS X with smb://10.0.2.2 (over Windows File Sharing).
The Mac Mini is configured to speak both of these protocols. These are the fastest way to merge the bin/ folders to a single location in preparing for doing a software release.



