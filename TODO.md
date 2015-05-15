TODO
====

* [ ] Agree upon a License
* [ ] Set up a cross-platform makefile
  * [?] Linux (32 bit and 64 bit should be identical; it's just a matter of compiling 
    * [x] ArchLinux
    * [?] Debian
    * [?] Fedora
  * [ ] Windows
    * [ ] XP (32 bit!)
    * [ ] 7  (64 bit!)
    * [ ] 8  (64 bit!)
  * [?] 64 bit OS X
    * [x] Mountain Lion (10.8)
    * [?] Mavericks (10.9)
    * [?] Yosemite (10.10)
  * [-] 32 bit OS X (does this even exist anymore?)
* [ ] Set up a cross-compiler (this is much harder!)
* [ ] Support installing without root (..i.e. distribute libsvm and install it next to the things)

* [ ] Add stata/ to the include path instead of "stata/stplugin.h"? maybe?
* [ ] Define a DEFINES macro in the makefile which works like LIBS
* [ ] Separate the generic cross-platform make parts from the svm-specific parts.


libsvm:
* [x] patch the Makefile to be saner
* [ ] make print_func support printf arguments
* [ ] replace all `fprintf(stderr, )`s with error_func (and make it also support printf args)
  * -> and then linkup error_func to Stata
