Compiling Stata-SVM
===================

This is a guide for building the code for developers of Stata-SVM.
If you just want to use it, see [INSTALL](INSTALL.md).

Build requirements:
* toolchain
* libsvm
* make

Toolchain
---------

To build, you will need to have your platform's toolchain installed.

On Windows, you will need to [get gmake](http://gnuwin32.sourceforge.net/packages/make.htm), and you will also need a compiler (MinGW or Visual Studio) installed.
Unlike the POSIX compilers, if you want to use Visual Studio, you need to amend your %PATH% by [using `vcvarsall.bat`](https://msdn.microsoft.com/en-us/library/x4d2c09s.aspx); for 32 bit builds:
```
C:> "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat"
```
and for 64-bit:
```
C:> "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" amd64
```
Unlike VS, MinGW is by default installed on the %PATH% (TODO: confirm this), and the makefile checks for VS first,
so if you have both installed you can choose which to use simply by amending or not amending your %PATH%.

On OS X, you will need XCode or at least the minimal [Command Line Tools](TODO).

Similarly, on Linux, there will also be a package for this, but it's name changes depending on your distro; for example in Debian `apt-get install build-essentials`, and on Arch `pacman -S base-devel` will get you the tools.

On both OS X and Linux, you can test if you have the compiler installed with
```
$ gcc -v
```

libsvm
------

[libsvm](http://www.csie.ntu.edu.tw/~cjlin/libsvm/) is the C library which does the heavy lifting. Stata-SVM is a thin wrapper which exposes its routines and makes them Stata-esque.

Windows:
To compile against a DLL on Windows, you must have its associated .lib file. Unless the library author provides it [citation needed] the only way source for them is as a by-product of compiling that DLL.
(some people [prefer](http://blog.nuclex-games.com/2012/03/how-to-consume-dlls-in-visual-cxx/) to bundle the .lib and .h files with the project; we might end up going that route if this becomes too painful).
The proper way to do this is to compile and 'install' libsvm manually:
0) Install Visual Studio (libsvm does not yet come with a MinGW build script)
1) Download the libsvm source code. Unzip it.
2) Open up a command prompt in that folder, and run *some variant of*
```
C:>SET LIBSVM=C:\path\to\libsvm
C:>C:\path\to\MSVC\vcvarsall.bat amd64
C:>cd %LIBSVM%
C:\path\to\libsvm>nmake -f Makefile.win
```
As of this writing, this will get you %LIBSVM%\svm.h, %LIBSVM%\windows\libsvm.lib and %LIBSVM%\windows\libsvm.dll, where %LIBSVM% is where you unzipped the source.

Then, to get the build to pick them up, you will need to do
```
# set bu
C:> SET INCLUDE=%INCLUDE%;%LIBSVM%
C:> SET LIB=%LIB%;%LIBSVM%\windows
C:> SET PATH=%PATH%;%LIBSVM%\windows
```
You can make these settings permanent by editing your user environment variables via "Edit environment variables for your account" (available by search the Start Menu). Godspeed.

On OS X and Linux, installing the libsvm as normal will get you its build dependencies and will place them in system-accessible locations. See [INSTALL](INSTALL.md) for suggestions about what counts as 'as normal'.
If you choose to use MacPorts, pay attention to the part where you tell the system to look for libraries in /opt, much like the situation on Windows.

Building
--------

Once you have set up a compiler, open a shell **in the `src/` subdirectory** and run
```
$ make
```

(If the build fails for you **please file bug reports**. We are a small team and cannot cover all platforms at all times, but we will address your problem and help you to help us improve the package.)

Testing
-------

You can run the unit tests with, 
```
$ make test
```
but you will need Stata installed and activated for this, of course.

Installation/Deployment
-----------------------

TODO