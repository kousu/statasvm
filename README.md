Stata-SVM
=========

This is a [Stata plugin](http://www.stata.com/plugins) wrapping [libsvm](http://www.csie.ntu.edu.tw/~cjlin/libsvm/)
to offer Support Vector Machine based algorithms, both regression and classification, to Stata users.

If you use this in a project, please cite it as:

> Guenther, Nick, and Matthias Schonlau. "Support vector machines." Stata Journal 16, no. 4 (December 23, 2016): 917-37. http://www.stata-journal.com/article.html?article=st0461. 


Originally written by [Nick Guenther](http://github.com/kousu) and [Professor Matthias Schonlau](http://www.schonlau.net).

Installation
------------

In Stata:
```
net search svmachines
```
should find and let you install this wrapper. If this does not work for you, please file bug reports. If you need it to work RIGHT NOW, read on for more specific instructions:


### Windows

On Windows, libsvm is bundled with this package, because dependency tracking is too difficult on Windows.


### OS X

* macports: `port install libsvm` ~OR~
* brew: `brew install libsvm`


### Unix

On Unix, you need to have libsvm installed. Perhaps packagers will move statasvm into, though such a package would be out of places given that the Unix installer for Stata is a shell script which needs to be babied.

* Debian-derivatives: `apt-get install libsvm3`
* Arch: libsvm is [in the AUR](https://aur.archlinux.org/packages/libsvm/)
* Redhat/Fedora: `yum install libsvm` (**UNTESTED**)
* You can manually [download](http://www.csie.ntu.edu.tw/~cjlin/cgi-bin/libsvm.cgi?+http://www.csie.ntu.edu.tw/~cjlin/libsvm+tar.gz) and follow the [build instructions](https://github.com/cjlin1/libsvm).


Usage
-----

See `help svmachines`