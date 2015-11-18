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

If either of these fail, you will need to install your compilers before continuing.

### Windows

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

### OS X

On OS X, you will need the **Command Line Tools** package.
If you have an older version XCode, this is available [in the menus](TODO, depending on version.
Otherwise, you can get them from the [ADC Downloads page](https://developer.apple.com/downloads/),
 but you will need to sign up for an Apple ID and agree to Apple's terms.
 Make sure you get the one that matches your version of OS X!
Finally, you can apparently, with no account, [on recent OS Xs](http://osxdaily.com/2014/02/12/install-command-line-tools-mac-os-x/), simply run
```
$ xcode-select --install
```

### *nix

On Linux or other *nix, there will usually be a toolchain metapackage, but its name differs depending on your distro.
In Debian, use `apt-get install build-essentials`,
on Arch use `pacman -S base-devel`, and
on the BSDs the toolchain should be installed as a core part of the OS.



libsvm
------

[libsvm](http://www.csie.ntu.edu.tw/~cjlin/libsvm/) is the C library which does the heavy lifting. Stata-SVM is a thin wrapper which exposes its routines and makes them Stata-esque.
If you get "'svm.h' file not found" when compiling, you are missing a libsvm installation.

### Windows

TODO: this is out of date. the repo has `windows/libsvm.{lib,dll}` which makes this; but it is still useful to know how to compile libsvm for Windows, in case of version bumps, so for now this stays. Sorry. I'll clean this up later.

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

As you make changes, you can just do `make` again to update the code.
However, as usual, you can get rid of the build cruft if you need to start from a known state with
```
$ make clean
```
(you have to do this, for example, when you change the Makefile, as make doesn't track its own Makefile)

Development Installation
-----------------------

The proper way to install Stata-SVM is to use the [install instructions](INSTALL.md).
However, for development you want to be able to use the code in the repository.
The simplest way and most replicable way to do this is to write a test case for every feature, bug, or change, and use `make tests`.
But if that is too slow for you---it is for me---or if you want to use bleeding edge in your daily Stata usage, follow these instructions; if you are familiar with python, these are similar to using `python setup.py develop`.

We will add the build directory to Stata's adopath, using [`profile.do`](http://www.stata.com/manuals13/gswb.pdf#B.3ExecutingcommandseverytimeStataisstarted). **If you have already customized your profile.do, you should edit the one you already have as Stata only runs one**.  If not, you can make `profile.do` in your home folder; this is typically `/home/<username>/ado' on Unix, '/Users/<username>/ado' on OS X, and 'C:\Users\<username>\Documents' on Windows. See the linked Stata documentation if you need more help.

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
then the plugin is corrupted; especially if you are on Windows, you probably have mistakenly cross-compiled StataSVM or libsvm.
You must match the architecture the plugin to the architecture of Stata:
Stata.exe can only run 32 bit plugins and Stata-64.exe can only run 64 bit plugins **including sub-DLLs**.


Testing
-------

There is a haphazard suite of test cases in `src/tests/`. Working in `src/`, for each file `tests/x.do` the test can be run with
```
src/$ make tests/x
```

To see more details you can use either Stata's tracing or the internal debug flag or together:
```
src/$ TRACE=1 DEBUG=1 make tests/x
```

Once you have a package, described below, you should make sure it installs properly.
First, put up an HTTP server in the `dist/` folder:
```
src/dist/$ python3 -m http.server  #there are lots of other options too if you do not have python3
```
Then point Stata at it:
```
. net from http://localhost:8000
. net install svm
. 
. // For a single package, it is equivalent and faster to write:
. net install svm, from(http://localhost:8000)
```


A tip: as you fix bugs in this stage, you can force reinstallation of only your changes. After you `make pkg` do
```
. net install svm, from(http://localhost:8000) replace
```
The "replace" option will report only those files it discovered needed updating, which should match your changes.



Deployment
----------

`make pkg` automates, as much as possible, creating a multiplatform Stata .pkg.
As a subroutine, it runs `make dist` which takes `.ado`s and `.sthlp`s in `./` along with everything in `bin/`, and `ancillary/`, and places them into `dist/`.
(`ancillary/` is for ancillary files---ones which will not get installed with `. net install svm` but can optionally be pulled *to the working directory* with `. net get svm`; it could contain, for example, datasets (.csv, .dta, .svmlight) and example code (.do)).
`make pkg` then scans and constructs `dist/svm.pkg` and `dist/stata.toc` from `dist/`.
The package is likely to install in subtly wrong ways if the .pkg file is malformed, so it is poor form to try to hand-roll it.

We do not have a cross-platform build bot available, so there is a manual process needed to do a complete (i.e. cross-platform) distribution.
We've attempted to make the chance for error minimal, and this only needs to be done for releases, never for just developing.
The goal this processes is to synchronize the code on all machines, build it,
and eventually collect the platform-specific pieces into *the same* `bin/` folder, each platform under `bin/<platform>/`,
*before* running `make pkg`, so that it can pick them up and index everything into the .pkg file.
Notice that if you are only testing one platform, you just need to run `make pkg` locally instead of this complication.

Process:

* Make sure the tree is clean of scrap .ado or backup files, to avoid cruft getting pulled in accidentally; `make dist` is intentionally simplistic. `git status` will help you determine if there is mess.
* Pick a primary build machine. It *must* be POSIX (`make pkg` is not Windows compatible); if you do not have a POSIX machine handy, consider making a virtual machine with VirtualBox or VMWare.
* Login remotely (ssh, RDP, or VNC) to each build machine, or just walk across the room to the other build machines.
  * SPECIAL WINDOWS EXCEPTION: Instead of having two Windows-32 and Windows-64 build machines, open terminals on one Windows machine:
    one with the 64 bit build (Visual Studio or MinGW) build tools loaded, and
    one with the 32 bit (Visual Studio or MinGW) build tools.
    Refer to "Toolchain" above.
* `cd` to repository/src on each machine
* synchronize:
  * while repos are out of sync:
    * for each build machine:
      * `git pull` + fix any merge conflicts
      * `git diff; git commit -a; git push`
* for each build machine: `make clean; make`
* manually copy the bin/ folder to your primary machine, over your choice of USB stick, SMB, NFS, SFTP, FTP, etc.
* on the primary build machine: `make pkg`


There is a shortcut version of this process, quicker but more prone to mistakes:

* Make sure the tree is clean, as above.
* Pick a primary build machine; make sure it is POSIX (`make pkg` is not Windows compatible).
* Login remotely (ssh, RDP, or VNC) to each build machine
* remotely mount (either via sshfs or smb, depending on platform) the repository from the primary
* `cd` into repository/src; this means the remotely mounted repository, for non-primary build machines
* on each machine: `make clean; make`
  * since the drive is network-shared, everything ends up in the same build folder, but platform-specific pieces get placed under `bin/<platform>/`, so they do not conflict with each other.
* on the primary: `make pkg`



Once `pkg` has gone through, **test it**. There may have been a packaging glitch which broke, say, 32 bit Windows, and if so you need to start this ritual from the top.
* On the primary, `../scripts/distserver.sh`
* For each build machine, run Stata and do `. net install svm, from(http://$PRIMARY:8000/)` and make sure everything in the package works.
  * better if you use fresh VM copies of the build machines, ones which definitely lack the repository and libsvm

Once you think the package is ready for deployment, zip up the `dist/` folder and submit it to [ssc](http://www.stata.com/support/ssc-installation/) by contacting [TODO]
