
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#ifdef _WIN32
// Windows
#include <Windows.h> //for LoadLibrary()
#else
//OSX and *nix
#include <dlfcn.h> //for dlopen()
#endif

#include "stplugin.h"
#include "stutil.h"


/* dlopenable: test if a given dll is loadable (i.e. readable and the correct architecture) by loading it and immediately unloading it.
 * beware: this offers a security hole if an attacker can write malicious DLLs, especially on Windows where the current directory is in the library path.
 *
 * TODO:
 * [ ] Write a wrapper layer to map posix calls to Windows so that there's only one code path
     dlopen -> LoadLibrary
     dlclose -> FreeLibrary
     dlerror -> GetLastError + FormatMessage (example https://msdn.microsoft.com/en-us/library/windows/desktop/ms680582%28v=vs.85%29.aspx)
 */


STDLL stata_call(int argc, char *argv[])
{

    /* argument checking */
    if(argc != 1) {
        sterror("_dlopenable: incorrect number of arguments (%d), can only take 1\n", argc);
        return 1;
    }
    
    /* try to load the library; immediately unload it */
#ifdef _WIN32
    HMODULE lib = LoadLibrary(argv[0]);
    if(lib == NULL) {
        sterror("unable to open shared library %s: [TODO]\n", argv[0]);
        return 1;
    }
    if(FreeLibrary(lib) == 0) {
        sterror("unable to close shared library %s: [TODO]\n", argv[0]);
        return 2;
    }
#else
    void *lib = dlopen(argv[0], RTLD_NOW /* fully resolve this lib and all deps immediately; RTLD_LAZY is the usual default, but probbbably for this usage we want RTLD_NOW.. probably... patches welcome. */);
    if(lib == NULL) {
        sterror("unable to open shared library %s: %s\n", argv[0], dlerror());
        return 1;
    }
    if(dlclose(lib) != 0) {
        sterror("unable to close shared library %s: %s\n", argv[0], dlerror());
        return 2;
    }
#endif
    
    /* if we get here, we win! cognac for everyone. */
    return 0;
    
}

int stata_init() { return 0; }