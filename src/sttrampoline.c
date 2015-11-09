/* sttrampoline.c: this is an optional helper file to link into Stata plugins which provides infrastructure plugins to define subcommands. */
/*                 This lets a single plugin operate in multiple steps which is necessary sometimes to work around the limited Stata API,  */
/*                 and it lets a single plugin provide multiple services, if that makes sense. */

#include <string.h>

#include "sttrampoline.h"

/* Stata only lets an extension module export a single function (which I guess is modelled after each .ado file being a single function, a tradition Matlab embraced as well)
 * to support multiple routines the proper way we would have to build multiple DLLs, and to pass variables between them we'd have to figure out
 * instead of fighting with that, I'm using a tried and true method: indirection:
 *  the single function we export is a trampoline, and the subcommands array the list of places it can go.
 *
 * This file can be included by any plugin which wants to use a trampoline.
 */


ST_retcode sttrampoline(int argc, char* argv[]) {
    for (int i = 0; i < argc; i++) {
        stdebug("\targv[%d]=%s\n", i, argv[i]);
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


