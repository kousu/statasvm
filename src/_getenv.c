
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "stplugin.h"
#include "stutil.h"

#define OUTPUT "__getenv" //two underscores means that it is a local macro (the first underscore) with name "_getenv" (to match the plugin)

char* EMPTY = "";

STDLL stata_call(int argc, char *argv[])
{
    ST_retcode err = 0;
    
    // argument checking
    if(argc != 1) {
        sterror("_getenv: incorrect number of arguments (%d), can only take 1\n", argc);
        return 1;
    }
    
    // lookup the environemnt variable
    char* value = getenv(argv[0]);
    if(value == NULL) {
        //sterror("_getenv: '%s' not found.\n", argv[0]); //DEBUG
        value = EMPTY;
    }
    
    // return (via a Stata macro, because the plugin interface offers nothing else)
    err = SF_macro_save(OUTPUT, value);
    if(err) {
      sterror("_getenv: unable to write '%s' to output macro '%s'[%d]: \n", err, value, OUTPUT, strerror(err), err);
      return err;
    }
    return 0;
}

int stata_init() { return 0; }