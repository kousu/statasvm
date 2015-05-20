Compiling Stata-SVM
===================

This is a guide for building the code for developers of Stata-SVM.
If you just want to use it, see [INSTALL](INSTALL.md).

Build requirements:
* GNU make
* a compiler
* libsvm

Toolchain
---------

To build, you will need to have your platform's compilation toolchain installed, as well as GNU make (gmake), as the Makefile is written against gmake.

On Windows, you can [get the gmake package](http://gnuwin32.sourceforge.net/packages/make.htm) or install it [MinGW's subproject MSYS](http://www.mingw.org/wiki/MSYS).
In the former case, you will need to add it to your %PATH% manually, by [editing your environment variables](http://www.computerhope.com/issues/ch000549.htm) to append
the GnuWin32 program folder, usually "C:\Program Files (x86)\GnuWin32\bin" to the PATH variable; for the latter you will have to follow their instructions.

For a Windows compiler, you can use [MinGW](http://www.mingw.org/) or Visual Studio.

The latter demands you amend your %PATH% by [using `vcvarsall.bat`](https://msdn.microsoft.com/en-us/library/f2ccy3wt.aspx) every time you start a command prompt session; here are some command lines which will accomplish this but **beware that you will need to adjust these paths if you have a different version of VS**. For 32 bit builds:
```
C:> "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat"
```
and for 64-bit:
```
C:> "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" x86_amd64
```
There are also "Developer Command Prompt" shortcuts in your start menu, as described in the above link. Remember that whichever method you use, you must do it every time you begin a session!

For the former, make sure you've followed the [official MinGW setup instructions](http://www.mingw.org/wiki/Getting_Started). Those instructions leave some things up to you, however: you can install [MSYS]() and, or your can add C:\MinGW\bin to your %PATH%.  Be warned though: MinGW only does 32-bit builds (there is a [MinGW64 fork](http://mingw-w64.yaxm.org/) and some sketchy [instructions](http://ascend4.org/Setting_up_a_MinGW-w64_build_environment#Switchable_32-_and_64-bit_modes) which let you dual-boot them), and the only symptom you will have of tripping over this is mysterious linker errors that won't go away.   TODO
The Makefile checks for VS first, so if you have both installed you can choose which to use simply by amending or not amending your %PATH%.  TODO

On OS X, you will need the [Command Line Tools](TODO) package. If you have XCode, this is available [in the menus](TODO); otherwise, you will need to sign up for an Apple ID and download it: make sure you get the one that matches your version of OS X!

On Linux or other *nix, there will usually be a toolchain metapackage, but its name differs depending on your distro. In Debian, use `apt-get install build-essentials`, on Arch use `pacman -S base-devel`, and the BSDs install the toolchain with the OS.

You can test if you have the compiler installed with (*nix, including OS X and MinGW):
```
$ gcc -v
```

or (Windows with VS)
```
C:> cl.exe
```

And you can test if you have make installed by running it in an empty directory:
```
$ make
make: *** No targets specified and no makefile found.  Stop.
```


libsvm
------

[libsvm](http://www.csie.ntu.edu.tw/~cjlin/libsvm/) is the C library which does the heavy lifting. Stata-SVM is a thin wrapper which exposes its routines and makes them Stata-esque.

### Windows

To compile against a DLL on Windows, you must have its associated .lib file. Unless the library author provides it [citation needed] the only way source for them is as a by-product of compiling that DLL.
The proper way to do this is to compile and 'install' libsvm manually:
0) Install Visual Studio (libsvm does not yet come with a MinGW build script)
1) Download the libsvm source code. Unzip it.
2) Open up a command prompt in that folder (Shift+Right Click on the folder -> Open Command Window Here) and run
```
C:\path\to\libsvm>"C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" x86_amd64
C:\path\to\libsvm>nmake -f Makefile.win
```
This will get you svm.h, windows\libsvm.lib and windows\libsvm.dll in that folder, which are the three things you need to build Stata-SVM successfully.
To get the build to pick them up, you will need to set three corresponding environment variables:
```
C:\path\to\libsvm>SET INCLUDE=%INCLUDE%;C:\path\to\libsvm
C:\path\to\libsvm>SET LIB=%LIB%;C:\path\to\libsvm\windows
C:\path\to\libsvm>SET PATH=%PATH%;C:\path\to\libsvm\windows
```
INCLUDE is an environment variable used by the the VS compiler; LIB is used by the VS linker; the PATH is how Windows finds libsvm.dll at run time.
When the Makefile detects MinGW it patches the contents of these variables over MinGW, so you only need to do this configuration once.
Make sure to substitute C:\path\to\libsvm with the actual path (Shift+Right Click on the folder->Copy As Path)!

To make this permanent, "Edit Environment Variables for your Account" (available by search the Start Menu) (make sure you append to, not overwrite, whichever of these already exist, as those SET commands do).
Restart your command prompt and inspect
```
C:> echo %INCLUDE%
C:> echo %LIB%
C:> echo %PATH%
```
to ensure your changes took.

In theory, you should also be able to skip these tweaks and just install libsvm as a system library, as you would on *nix.
For example, you could install libsvm into msys, as described at [Installation and Use of Supplementary Libraries with MinGW](http://www.mingw.org/wiki/HOWTO_Specify_the_Location_of_Libraries_for_use_with_MinGW#toc3),
or maybe [chocolatey](https://chocolatey.org/packages) will get a libsvm package, but this is as yet untested.

### *nix: (including OS X)

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

You can also run specific tests by appending the basename of the testing .do file. For example
```
$ make test_train
```
will run `tests/train.do`.

Most tests require some sort of example data. We use the [libsvm data archive](http://www.csie.ntu.edu.tw/~cjlin/libsvmtools/datasets/) as a very convenient source, and as the running the tests will auto-download datasets as needed, you need to be aware of the copyright notice:
* Chih-Chung Chang and Chih-Jen Lin, LIBSVM : a library for support vector machines. ACM Transactions on Intelligent Systems and Technology, 2:27:1--27:27, 2011. Software available at http://www.csie.ntu.edu.tw/~cjlin/libsvm.

To compare test results from different platforms, try this:
```
make clean; make test > `uname -s`.out
```

Installation/Deployment
-----------------------

The proper way to install Stata-SVM is to use the [install instructions](INSTALL.md). However, if you want to use the development version in your normal Stata usage, follow these; if you are familiar with python, these are similar to using `python setup.py develop`.

To use the, we will add the build directory to Stata's adopath, using [`profile.do`](http://www.stata.com/manuals13/gswb.pdf#B.3ExecutingcommandseverytimeStataisstarted). **If you have already customized your profile.do, you should edit the one you already have as Stata only runs one**.  If not, you can make `profile.do` in your home folder; this is typically `/home/<username>' on Unix, '/Users/<username>' on OS X, and 'C:\Users\<username>' on Windows. See the linked Stata documentation if you need more help.

Once you have found your `profile.do`, add this one line:
```
adopath + "path/to/statasvm/src"
```

Restart Stata and you should be able to run
```
. svm
varlist required
r(100);
```

If instead you see
```
. svm
command svm is unrecognized
r(199);
```
then *either* you have the path set wrong *or* the .plugin file is unloadable, which might happen if you have compiled a 32 bit version and are running 64 bit Stata or you're trying to run a Mac OS X build on Windows, and unfortunately Stata does not distinguish the cases for us. To tell, first try to load the .plugin manually:
```
. program _svm, plugin
```
If that says "file not found" then your path is wrong, and you should double check it with `adopath`.

If instead you see
```
. program _svm, plugin
Could not load plugin: .\_svm.plugin
```
then the plugin is corrupted; especially if you are on Windows, you probably have cross-compiled without realizing it and need to switch toolchains:
you must build for the same architecture as your copy of Stata, because Stata links your DLL into its own memory.