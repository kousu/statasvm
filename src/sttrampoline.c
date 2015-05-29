

#include <string.h>

#include "stplugin.h"
#include "stutil.h"

/* Stata only lets an extension module export a single function (which I guess is modelled after each .ado file being a single function, a tradition Matlab embraced as well)
 * to support multiple routines the proper way we would have to build multiple DLLs, and to pass variables between them we'd have to figure out
 * instead of fighting with that, I'm using a tried and true method: indirection:
 *  the single function we export is a trampoline, and the subcommands array the list of places it can go.
 *
 * This file can be included by any plugin which wants to use a trampoline.
 */

//TODO: move this header stuff into sttrampoline.h and especially clean up the struct with a typedef
#define SUBCOMMAND_MAX 12 //this is good to have symbolically even if it doesn't actually enforce storage limits because reasons
                          // (if we say 'const char name[COMMAND_MAX]' then it is 

extern struct {
    const char *name;
     ST_retcode(*func) (int argc, char *argv[]);
} subcommands[];







/* the Stata plugin interface is really really really basic:
 * . plugin call var1 var2, op1 op2 77 op3
 * causes argv to contain "op1", "op2", "77", "op3", and
 * /implicitly/, var1 and var2 are available through the macros SF_{nvars,{v,s}{data,store}}().
 *  (The plugin doesn't get to know (?) the names of the variables in `varlist'. [citation needed])
 *
 * The SF_mat_<op>(char* M, ...) macros access matrices in Stata's global namespace, by their global name.
 */
STDLL stata_call(int argc, char *argv[])
{
    for (int i = 0; i < argc; i++) {
        stdebug("argv[%d]=%s\n", i, argv[i]);
    }

    stdebug("Total dataset size: %dx%d. We have been asked operate on [%d:%d,%d].\n",
         SF_nobs(), SF_nvar(), SF_in1(), SF_in2(), SF_nvars());

    if (argc < 1) {
        sterror("no subcommand specified\n");
        return (1);
    }

    char *command = argv[0];
    argc--;
    argv++;                     //shift off the first arg before passing argv to the subcommand

    int i = 0;
    while (subcommands[i].name) {
        if (strncmp(command, subcommands[i].name, SUBCOMMAND_MAX) == 0) {
            return subcommands[i].func(argc, argv);
        }

        i++;
    }

    sterror("unrecognized subcommand '%s'\n", command);

    return 1;
}

