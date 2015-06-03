/* ensurelib: edit the OS shared library path to ensure shared library dependencies will be found when Stata loads plugins.
 *
 * Nick Guenther <nguenthe@uwaterloo.ca>, June 2015.
 * BSD License.
 *
 * Usage:
 * . ensurelib libraryname
 * 
 * libraryname should be as in your (gcc!) linker commandline: e.g. if you specify "-lsvm" there, specific "svm" here.
 * This will search your adopath for the file
 *   Windows: libraryname.dll
 *   OS X:    liblibraryname.dylib
 *   *nix:    liblibraryname.so
 * and add the specific directory that file is in (e.g. C:\ado\plus\l\) to your shared library path
 *   Windows: %PATH%
 *   OS X:    $DYLD_LIBRARY_PATH
 *   *nix:    $LIBRARY_PATH
 * Since Stata usually includes "." in the adopath, you can use this during development as well:
 *   just keep the DLLs you plan to bundle in your working directory.
 * We follow close to [MinGW's rules](http://www.mingw.org/wiki/specify_the_libraries_for_the_linker_to_use), except that since we're only loading DLLs, on Windows, 
 *
 *
 * This allows you to bundle non-plugin DLLs, which you will have to do to create wrapper plugins
 * (unless you want to statically link, which is a almost always wrong).
 * 
 * Works on Windows, OS X, and Linux (which are the only platforms Stata supports) 
 *
 * Dependencies:
 *  _setenv.plugin
 *  _getenv.plugin (Stata provides the "environment" macro function for read-only env access,
 *                  but it doesn't seem to be live: it just caches the env at boot, not expecting it to be edited)  
 *
 * TODO:
 * [ ] Stata has, essentially, a global install namespace but no dependency tracking.
 *     So what happens if two packages bundle this? Does the second overwrite the first? Get denied? Mysteriously break the first one? And what happens if one package uninstalls?
 * [ ] Is this worth factoring? maybe "prependpath"?
 */

program _getenv, plugin
program _setenv, plugin

program define ensurelib
  gettoken lib 0 : 0
  if("`lib'"=="") {
    di as error "ensurelib: argument required"
    exit 1
  }
  syntax , []/* disallow everything else */
  
  if("`c(os)'"=="Windows") {
    local libvar = "PATH"
    local sep = ";"
    local dlprefix = ""
    local dlext = ".dll"
  }
  else if("`c(os)'"=="MacOSX") {
    local libvar = "DYLD_LIBRARY_PATH" /* or is this DYLD_FALLBACK_LIBRARY_PATH ?? */
    local sep = ":"
    local dlprefix = "lib"
    local dlext = ".dylib"
  }
  else if("`c(os)'"=="Unix") { //i.e. Linux, and on Linux really only like Fedora and Ubuntu; Stata doesn't test builds for others.
    local libvar = "LD_LIBRARY_PATH"
    local sep = ":"
    local dlprefix = "lib"
    local dlext = ".so"
  }
  else {
    di as error "ensurelib: Unsupported OS `c(os)'"
    exit 1
  }
  
  // get the full path to the lib:
  // i. try to find it (in the adopath)
  //ii. extract the dirname from the return value
  quietly findfile "`lib'`dlext'" /* this will crash if not found */
  local lib = "`r(fn)'"

  mata pathsplit("`lib'",libpath="",basename="") //_Stata_ doesn't have pathname manipulation, but _mata_ does. the ="" are to declare variables (variables need to be declared before use, even if they are just for output)
  mata st_global("r(libpath)",libpath)  // getting values out of mata to Stata is inconsistent: numerics in r() go through st_numscalar(), strings have to go through st_global(), however non-r() scalars have to go through st_strscalar
  mata st_global("r(basename)",basename)
  
  //di as txt "lib=`lib'" //DEBUG
  //di as txt "r(libpath)=`r(libpath)'" //DEBUG
  
  // prepend libpath, if it doesn't exist yet
  plugin call _getenv, "`libvar'"
  local curpath = "`_getenv'"
  //di as txt "ensurelib: pre: `libvar'=`_getenv'" //DEBUG
  
  local k = ustrpos("`curpath'", "`r(libpath)'")
  if(`k' == 0) {
    plugin call _setenv, "`libvar'" "`r(libpath)'`sep'`curpath'"
  }
  else {
    //di as txt "`r(libpath)' already found in `libvar'" //DEBUG
  }
  
  // DEBUG  
  //plugin call _getenv, "`libvar'"
  //di as txt "ensurelib: post: `libvar'=`_getenv'"p
  
end
