
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "stplugin.h"
#include "stutil.h"


STDLL stata_call(int argc, char *argv[])
{
    ST_retcode err = 0;
    
    
    stdebug("_setenv: first %s = %s\n", argv[0], getenv(argv[0]));
    
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
    
    stdebug("_setenv: now %s = %s\n", argv[0], getenv(argv[0]));
    
    return 0;
}

