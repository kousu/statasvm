

#include "stplugin.h"
#include "stutil.h"

#define SUBCOMMAND_MAX 12 //this is good to have symbolically even if it doesn't actually enforce storage limits because reasons
                          // (if we say 'const char name[COMMAND_MAX]' then it is 

struct subcommand_t {
    const char *name;
     ST_retcode(*func) (int argc, char *argv[]);
};

extern struct subcommand_t subcommands[];

ST_retcode sttrampoline(int argc, char* argv[]);