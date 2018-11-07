/* svm_ensurelib: at runtime, make sure libsvm is available and loadable */
/*       This would be ensurelib.ado, but for packaging safety, because Stata
         has no sensible way of protecting against namespace conflicts, this
         gets the same prefix as the rest of the package.

   If you want to use ensurelib by itself then delete this header and first function and rename the file,
   and rename the plugins loaded below.
*/

program define svm_ensurelib
  version 13
  // call the real ensurelib, which is defined below (as an inner "helper" function)
  ensurelib svm
end


/* ensurelib: edit the OS shared library path to ensure shared library dependencies will be found when Stata loads plugins.
 *
 * This allows you to bundle non-plugin DLLs, which you will have to do to create wrapper plugins
 * (unless you want to statically link, which is a almost always wrong).
 *
 * Nick Guenther <nguenthe@uwaterloo.ca>, June 2015.
 * BSD License.
 *
 * Example usage:
 * Suppose you have joesstore.plugin which is linked (dynamically) against library joesmeat and veggiegarden.
 * For Windows, OS X, and *nix joesmeat should be, respectively, compiled to joesmeat.dll, libjoesmeat.dylib,
 * or libjoesmeat.so, and similarly for veggiegarden. It should be distributed to users' adopaths with the
 * special *capitalized* .pkg commands
 *   G WIN joesmeat.dll
 *   G MACINTEL libjoesmeat.dylib
 *   G UNIX libjoesmeat.so
 * Then, in your code
 *   ensurelib joesmeat
 *   ensurelib veggiegarden
 *   program joesstore, plugin
 * 
 *
 * libraryname should be as in your (gcc!) linker commandline: e.g. if you specify "-ljoesmeat" there, specific "joesmeat" here.
 * This will search your adopath for the file named
 *   Windows: libraryname.dll
 *   OS X:    liblibraryname.dylib
 *   *nix:    liblibraryname.so
 * and add the specific directory that file is in (e.g. C:\ado\plus\l\) to your shared library path
 *   Windows: %PATH%
 *   OS X:    $DYLD_LIBRARY_PATH
 *   *nix:    $LIBRARY_PATH
 * But if it does not find the library in your adopath, it will let the system use its usual library directories.
 *
 * Roughly, it is as if we have done:
 *   export LD_LIBARY_PATH=$ADOPATH:$LD_LIBRARY_PATH
 * but in a cross-platform way which also handles Stata's tricky alphabetical installation chunks ([M-5] adosubdir()).
 *
 * Since Stata usually includes "." in the adopath, you can use this during development as well:
 *   just keep the DLLs you plan to bundle in your working directory.
 *
 * We follow close to [MinGW's naming rules](http://www.mingw.org/wiki/specify_the_libraries_for_the_linker_to_use),
 * except that since we're only loading shared (not static) libraries, on Windows there is only one option just like the rest.
 * In particular from MinGW's rules, **if your library on Windows is uses the aberrant lib<name>.dll** you will must either:
 * - special-case your loading on Windows to call "ensurelib lib<name>"**,
 * - change the naming scheme of the .dll to conform to Windows standard: <name>.dll.
 * This problem generally only comes up with libraries that have been ported carelessly from *nix.
 * 
 * Works on Windows, OS X, and Linux (which are the only platforms Stata supports) 
 *
 * Dependencies:
 *  _setenv.plugin
 *  _getenv.plugin (Stata provides the "environment" macro function for read-only env access,
 *                  but it doesn't seem to be live: it just caches the env at boot, not expecting it to be edited)  
 *
 * TODO:
 * [ ] Pull this into a separate .pkg
 *     Stata has, essentially, a global install namespace and no dependency tracking.
 *     So what happens if two packages bundle this? Does the second overwrite the first?
 *     Get denied? Mysteriously break the first one? And what happens if one package uninstalls?
 * [ ] Is this worth factoring further? maybe "prependpath" could come out?
 */

capture noisily {
program _svm_getenv, plugin
program _svm_setenv, plugin
program _svm_dlopenable, plugin
}
if(_rc != 0) {
  di as error "ensurelib's prerequisites are missing. If you are running this from the source repo you need to 'make'."
  exit _rc
}

program define ensurelib
  version 13
  gettoken lib 0 : 0
  syntax /* deny further args */
  
  /* this handles libraries whose names on Windows follow the aberrant "lib<name>.dll" format,
     which commonly happens when unix libraries get ported without much care to Windows.
     
     The logic is stupid-simple here: first try lib<name>.dll,
     and if that works we assume it's correct, no further questions asked.
     Otherwise we fall back to <name>.dll.
     
     On non-Windows systems, we immediately fall back to the regular path,
     which looks up lib<name>.so or <name>.dylib or whatever else dlopen() does.
   */
  if("`c(os)'"=="Windows") {
    capture _ensurelib "lib`lib'"
    if(_rc==0) {
      // success!
      exit
    }
  }
  
  _ensurelib `lib'
end

program define _ensurelib
  version 13
  gettoken libname 0 : 0
  if("`libname'"=="") {
    di as error "ensurelib: argument required"
    exit 1
  }
  syntax , []/* disallow everything else */
  
  /* platform-settings */
  // libvar == platform specific environment variable that can be edited (there may be more than one option)
  // sep    == platform specific path separator
  // dl{prefix,ext} == what to wrap the libname in to generate the library filename
  if("`c(os)'"=="Windows") {
    local libvar = "PATH"
    local sep = ";"
    local dlprefix = ""
    local dlext = "dll"
  }
  else if("`c(os)'"=="MacOSX") {
    local libvar = "DYLD_LIBRARY_PATH" /* or is this DYLD_FALLBACK_LIBRARY_PATH ?? */
    local sep = ":"
    local dlprefix = "lib"
    local dlext = "dylib"
  }
  else if("`c(os)'"=="Unix") { //i.e. Linux, and on Linux really only like Fedora and Ubuntu; Stata doesn't test builds for others.
    local libvar = "LD_LIBRARY_PATH"
    local sep = ":"
    local dlprefix = "lib"
    local dlext = "so"
  }
  else {
    di as error "ensurelib: Unsupported OS `c(os)'"
    exit 1
  }
  
  /* wrap the library name into a file name */
  local lib = "`dlprefix'`libname'.`dlext'"
  
  /* If the lib is in the adopath, prepend its path to the system library path */
  capture quietly findfile "`lib'"
  if(_rc==0) {
    /* the path to the library on the adopath */
    local adolib = "`r(fn)'"
    
    /* extract the directory from the file path */
    mata pathsplit("`adolib'",adopath="",lib="") //_Stata_ doesn't have pathname manipulation, but _mata_ does. the ="" are to declare variables (variables need to be declared before use, even if they are just for output)
    mata st_local("adopath",adopath)  // getting values out of mata to Stata is inconsistent: numerics in r() go through st_numscalar(), strings have to go through st_global(), however non-r() scalars have to go through st_strscalar
    mata st_global("lib",lib)
	
    /* prepend the discovered library path (adopath) to the system library path (libvar) */
    // get the current value of libvar into libpath
    plugin call _svm_getenv, "`libvar'"
    local libpath = "`_getenv'"
	
    // skip prepending if adopath is already there in `libvar', to prevent explosion
    local k = ustrpos("`libpath'", "`adopath'")
    if(`k' == 0) {
      // prepend
      plugin call _svm_setenv, "`libvar'" "`adopath'`sep'`libpath'"
    }
  }
  /* Check that the library is now loadable */
  /* by checking here, we prevent Stata's "unable to load [...].plugin" with an error which points out the actual problem. */
  capture plugin call _svm_dlopenable, "`lib'"
  if(_rc!=0) {
    di as error "ensurelib: unable to load `libname'.  You must install dynamic link library `libname' to use this program."
    exit _rc
  }
  
  
end

