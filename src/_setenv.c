
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "stplugin.h"
#include "stutil.h"

#ifdef _WIN32
/* from http://stackoverflow.com/questions/17258029/c-setenv-undefined-identifier-in-visual-studio */
int setenv(const char *name, const char *value, int overwrite)
{
    int errcode = 0;
    if(!overwrite) {
        size_t envsize = 0;
        errcode = getenv_s(&envsize, NULL, 0, name);
        if(errcode || envsize) return errcode;
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
    
    
    stdisplay("_setenv: first %s = %s\n", argv[0], getenv(argv[0]));
    
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
    
    stdisplay("_setenv: now %s = %s\n", argv[0], getenv(argv[0]));
    
    return 0;
}

