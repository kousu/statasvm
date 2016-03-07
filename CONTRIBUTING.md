Stata-SVM Contribution Guidelines
=================================


Licensing
---------

TODO


Git workflow
------------


We use the [tip](https://www.backblaze.com/blog/10-rules-for-how-to-write-cross-platform-code/) from BackBlaze that source control is our cross-platform sync method.

Whenever you make a change, you need to make sure it is cross-compatible.
In principle, the best way to do this is to use a testing branch that won't impinge on the main branch, perhaps `cross`. For example:
```
# ..make changes...
make test
git checkout [-b] cross
git add -u ... && git commit 
git push

ssh OSX
cd statasvm
git checkout [-b] cross
git pull 
make test
exit

ssh Windows #or maybe rdesktop, or VNC
cd statasvm
git checkout [-b] cross
git pull
make test
exit

# back on the original machine
git checkout master
git merge cross
```

If you don't have access to the range of platforms we're supporting, you need to get someone else to do this step

In practice, you can probably just push to master, like Brian BackBlaze suggests. It'll mean there might be awkward one-liner nit commits that end up on master,
but since we're using the decentralized Github workflow, your master is your own so so long as you immediately complete all the testing, this won't be a problem.
If you used `cross` these would end up there anyway (and you can always commit-squash them away if you are pedantic).

Compiling
---------

See [COMPILE](COMPILE.md)

Testing
-------

You can run the unit tests with, 
```
$ make tests
```
but you will need Stata installed and activated for this, of course.

You can also run specific tests by appending the basename of the testing .do file. For example
```
$ make tests/train
```
will run `tests/train.do` in a harness that detects errors.

Most tests require some sort of example data. We use the [libsvm data archive](http://www.csie.ntu.edu.tw/~cjlin/libsvmtools/datasets/) as a very convenient source, and as the running the tests will auto-download datasets as needed, you need to be aware of the copyright notice:
* Chih-Chung Chang and Chih-Jen Lin, LIBSVM : a library for support vector machines. ACM Transactions on Intelligent Systems and Technology, 2:27:1--27:27, 2011. Software available at http://www.csie.ntu.edu.tw/~cjlin/libsvm.

To compare test results from different platforms, try this:
```
make clean; make tests > `uname -s`.out
```

If some tests are failing, you can isolate them by telling make to (-k)eep going like so:
```
$ make -k tests | grep Error
```



You can force-reinstall with
```
. net install svm, from(<distribution site>) replace
```

(users should use)
```
. adoupdate svm, update
```
(but this only has 1-day resolution, so it's not great for debugging)


### Duplicating StataSVM with the libsvm command line tools

The Stata commands
```
. svm `varlist'
. svm_export using "data.stata.model"
. predict C3
```

can be done with
```
. export_svmlight `varlist' using "data.svmlight"
```
Then
```
$ svm-train -b 1 data.svmlight data.libsvm.model
$ svm-predict data.svmlight data.libsvm.model C3.txt
```
(-b 1 enables probability estimates, which is (currently) the default in StataSVM)

Try
```
$ diff data.stata.model data.libsvm.model
```
to see if things are comparable. The "probA" and "probB" matrices are probably going to differ because, apparently, libsvm uses some stochastic process to estimate those, but they will be close, and the output supported vectors should be identical.


Deployment (aka Distribution)
----------------------------

Stata has its own home-grown package manager, as described in [[R]](http://www.stata.com/manuals14/rnet.pdf).
Since it is closed-source, it would be rare for its packages to show up in package managers, anyway.
This means that we are responsible for packaging because we are the downstream.

To make a package ready for distribution, go to *each* build machine and do:
```
$ make
```

Copy all the results (the only differences should in the bin/ subfolder). When you have done all the builds,
you should see all the platforms waiting
```
$ ls -l bin/
[TODO]
```

Next, you need to find copies of libsvm to bundle for the Windows and OS X builds (we rely on package managers for other systems).
For WIN, the 32 bit Windows, you need to get a 32 bit libsvm.dll. For WIN64A, you need a 64 bit libsvm.dll.
Similarly on Mac.
Put these DLLs next to their respective _svm.plugins, so that you have:
```
ls -l bin/*/
[TODO]
```

Now you are ready to
```
$ make dist
```

You should run a testing server and note down your hostame
```
$ ../scripts/dist.sh
```
so that, on each platform, you can make sure the plugin loads:
```
. net from http://$HOSTNAME:8000
. net describe svm
. net install svm
. svm
. net uninstall svm
```

Development Tips
----------------

To inspect DLL dependencies of a compiled file:
Windows: _______
OS X: `otool -L`
*nix: `readelf -d` (or `objdump -x`)




Plugin Interface
----------------

The plugin interface is the same as the C main() interface: argc/argv.
But unlike normal command line programs, we cannot rely on getopt existing everywhere,
and it is easy to get empty strings as individual arguments since there is no shell in the way.

TODO
