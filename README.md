Stata-SVM
=========

This is a [Stata plugin](http://www.stata.com/plugins) wrapping [libsvm](http://www.csie.ntu.edu.tw/~cjlin/libsvm/)
to offer Support Vector Machine based algorithms, both regression and classification, to Stata users.

Originally written by [Nick Guenther](http://github.com/kousu) and [Professor Matthias Schonlau](http://www.schonlau.net).

Installation
------------

**THIS IS ALPHA CODE. IT IS NOT READY FOR PRODUCTION.
IT IS NOT YET PUBLISHED IN THE STATA REPOSITORY.
IF YOU WANT TO USE IT YOU MUST BE COMFORTABLE DEVELOPING IT, TOO.**

In Stata:
```
net search svm
```
should find and let you install this wrapper. If this does not work for you, please file bug reports. If you need it to work RIGHT NOW, read on for more specific instructions:


### Windows

On Windows, libsvm is bundled with this package, because dependency tracking is too difficult on Windows.
```
TODO
```

### OS X

* macports: `port install libsvm` ~OR~
* brew: `brew install libsvm`

TODO: or should we just bundle, as on Windows?

```
TODO
```

### Unix

On Unix, you need to have libsvm installed. Perhaps packagers will move statasvm into, though such a package would be out of places given that the Unix installer for Stata is a shell script which needs to be babied.

* Debian-derivatives: `apt-get install libsvm3`  'apt-get install libsvm-dev'
* Arch: libsvm is [in the AUR](https://aur.archlinux.org/packages/libsvm/)
* Redhat/Fedora: `yum install libsvm` (**UNTESTED**)
* You can manually [download](http://www.csie.ntu.edu.tw/~cjlin/cgi-bin/libsvm.cgi?+http://www.csie.ntu.edu.tw/~cjlin/libsvm+tar.gz) and follow the [build instructions](https://github.com/cjlin1/libsvm).

```
TODO
```

Usage
-----

TODO
