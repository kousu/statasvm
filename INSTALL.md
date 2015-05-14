Installation
============

libsvm
------

### Windows

???

### OS X

There are two package managers for OS X, Homebrew and MacPorts.

Homebrew:
```
$ brew install libsvm
```
After this completes, you can double-check that svm.h and libsvm.dylib are available in the system-wide library directories:
```
$ ls -l /usr/local/include/svm.h /usr/local/lib/libsvm.dylib 
lrwxr-xr-x  1 user  admin  35 13 May 16:47 /usr/local/include/svm.h -> ../Cellar/libsvm/3.20/include/svm.h
lrwxr-xr-x  1 user  admin  38 13 May 16:47 /usr/local/lib/libsvm.dylib -> ../Cellar/libsvm/3.20/lib/libsvm.dylib
```
(if they aren't, try `brew link libsvm`; you might have permissions problems)

MacPorts:
```
$ port install libsvm
```
MacPorts installs everything to /opt/local/, unless you've configured it differently and does *not* symlink things into /usr/local/ like brew does. The best way to handle this is these lines:
```
# set build-time library paths
export C_INCLUDE_PATH=/opt/local/include:$C_INCLUDE_PATH
export CPP_INCLUDE_PATH=/opt/local/include:$CPP_INCLUDE_PATH
export LIBRARY_PATH=/opt/local/lib:$LIBRARY_PATH
# set run-time library path (this is separate from build-time as a side-effect of design-by-committee)
export LD_LIBRARY_PATH=/opt/local/lib:$LD_LIBRARY_PATH
```
If you plan to be a regular user of MacPorts, you should add these to your `~/.profile`.

### Linux

Debian and derivatives:
```
# apt-get install libsvm3
```

Arch: libsvm is [in the AUR](https://aur.archlinux.org/packages/libsvm/)
```
$ yaourt -S libsvm
```

Of course, for any of the Unixes (including OS X) you can install libsvm from source: download libsvm from the authors and follow their instructions.


