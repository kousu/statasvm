
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "stplugin.h"
#include "stutil.h"

#ifdef _WIN32

#ifdef __MINGW32__
/* MINGW defines _wgetenv_s(), but not getenv_s */
/* however, it *is* in the runtime .dll, so if we just add it here we're good */
/* MINGW wants you to use getenv(), I suppose, but getenv() makes */
errno_t getenv_s( 
   size_t *pReturnValue,
   char* buffer,
   size_t numberOfElements,
   const char *varname 
);
#endif

/* from http://stackoverflow.com/questions/17258029/c-setenv-undefined-identifier-in-visual-studio */
int setenv(const char *name, const char *value, int overwrite)
{
    if(!overwrite) {
		// "if overwrite is zero, [if the name does not exist] the value of name is not changed"
        if(getenv(name)) {
			// "(and setenv returns a success status)"
			return 0;
		}
		// i.e. if the name exists and you said "don't overwrite" then bail early and pretend we succeeded
    }
    return _putenv_s(name, value);
}

int unsetenv(const char *name) {
	return _putenv_s(name, "");
}
#endif

STDLL stata_call(int argc, char *argv[])
{
    ST_retcode err = 0;
    
    if(argc == 1) {
      err = unsetenv(argv[0]);
      if(err) {
        sterror("_setenv: unable to unset %s: %s\n", argv[0], strerror(err));
        return err;
      }
    } else if(argc == 2) {
      err = setenv(argv[0],argv[1],1);
      if(err) {
        sterror("_setenv: unable to write %s=%s: %s\n", argv[0], argv[1], strerror(err));
        return err;
      }
    } else {
        sterror("_setenv: incorrect number of arguments (%d), can only 1 or 2\n", argc);
        return 1;
    }
    
    return 0;
}


int stata_init() { return 0; }