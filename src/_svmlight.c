

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>

#include <errno.h>

#include "stutil.h"
#include "_svmlight.h"

struct {
    const char *name;
     ST_retcode(*func) (int argc, char *argv[]);
} subcommands[] = {
    {"import", import},
    {"export", export},
    {NULL, NULL}
};



/* Helper routine for reading svmlight files into Stata.
 * We adopt the libsvm people's method: scan the data twice.
 *
 * Stata doesn't let C plugins add new variables, but parsing with gettoken is agonizingly slow
 * so there is this ugly marriage:
 *   i. find out the size (svmlight_read("pre", filename))
 *  ii. return this to Stata
 * iii. Stata edits the data table, allocating space
 *  iv. read in the data (svmlight_read(filename))
 *
 * Yes, it is at least an order of magnitude faster to read the data twice in C,
 * even with the interlude back to Stata, than to do one pass with gettoken (Stata's wrapper around strtok())
 *
 * To reduce code, both scans are handled by this one function.
 * and its behaviour is modified with a flag of "pre" given to indicate the preread phase i.
 * The results of the preread phase are passed back via Stata scalars
 *   N (the number of observations) and
 *   M (the number of 'features', i.e. the number of variables except for the first Y variable);
 * Stata's C interface doesn't (apparently) provide any way to use tempnam or the r() table.4
 *   but Stata scalars are in a single global namespace, so to avoid naming conflicts we prefix the N and M by the name of this function. 
 *
 * Special case: the tag on an X variable (a 'feature') could also be the special words
 * "sid:" or "cost:" (slack and weighting tweaks, respectively), according to the svmlight source.
 * libsvm does not support these so for simplicity neither do we.
 *
 * TODO:
 * [ ] better error messages
 * [x] check for off-by-ones
 * [ ] format conformity:
 *   - libsvm gets annoyed if features are given out of order
 *   - libsvm will accept feature id 0, though none of the. Perhaps we should also pass back a *minimum*?
 *   - how does svm_light compare?
 */
ST_retcode import(int argc, char *argv[])
{

    ST_retcode err = 0;

    bool reading = true;

    if (argc > 1) {
        char *subcmd = argv[0];
        argc--;
        argv++;
        if (strncmp(subcmd, "pre", 5) == 0) {
            reading = false;
        } else {
            sterror("Unrecognized read subcommand %s\n" /* subcmd */ );
            return 1;
        }
    }

    if (argc != 1) {
        sterror("Wrong number of arguments\n");
        return 1;
    }


    stdebug("svm read");
    if (!reading) {
        stdebug(" pre");
    }
    stdebug("\n");

    char *fname = argv[0];
    FILE *fd = fopen(fname, "r");
    if (fd == NULL) {
        sterror("Unable to open file\n");
        return 1;
    }

    int M = 0, N = 0;

    // N is the number of lines
    // M is the *maximum* number of features in a single line

    double y;

    long int id;
    double x;

    // we tree the svmlight format as a sequence of space-separated tokens, which is really easy to do with scanf(),
    // where some of the tokens are
    //   single floats (marking a new observation) and some are
    //   pairs feature_id:value (giving a feature value)
    // scanf is tricky, but it's the right tool for this job: parsing sequences of ascii numbers.
    // TODO: this parser is *not quite conformant* to the non-standard:
    //   it will treat two joined svmlight lines as two separate ones (that is, 1 3:4 5:6 2 3:9 will be two lines with classes '1' and '2' instead of an error; it should probably be an error)
    char tok[512];              //GNU fscanf() has a "%ms" sequence which means "malloc a string large enough", but BSD and Windows don't. 512 is probably excessive for a single token (it's what, at most?)
    while (fscanf(fd, "%511s", tok) == 1) {     //the OS X fscanf(3) page is unclear if a string fieldwidth includes or doesn't include the NUL, but the BSD page, which as almost the same wording, says it *does not*, and [Windows is the same](https://msdn.microsoft.com/en-us/library/6ttkkkhh.aspx), which is why 511 != 512 here
        //printf("read token=[%s]\n", tok); //DEBUG
        if (sscanf(tok, "%ld:%lf", &id, &x) == 2) {     //this is a more specific match than the y match so it must come first
            if (id < 1) {
                sterror("parse error: only positive feature IDs allowed\n");
                return 4;
            }
            if (M < id)
                M = id;

            if (reading) {
                //stdebug("storing to X[%d,%ld]=%lf; X is %dx%d\n", N, id, x, SF_nobs(), SF_nvar()-1); //DEBUG
                SF_vstore(id + 1
                          /*stata counts from 1, so y has index 1, x1 has index 2, ... , x7 has index 8 ... */
                          , N, x);
                if (err) {
                    sterror("unable to store to x\n");
                    return err;
                }
            }
        } else if (sscanf(tok, "%lf", &y) == 1) {       //this should get the first 'y' value

            N += 1;

            if (reading) {
                stdebug("storing to Y[%d]=%lf; Y is %dx1.\n", N, y, SF_nobs());   //DEBUG
                err = SF_vstore(1 /*stata counts from 1 */ , N, y);
                if (err) {
                    sterror("unable to store to y\n");
                    return err;
                }
            }

        } else {
            sterror("svmlight parse error\n");
            return 1;
        }
    }

    if (!reading) {
        stdebug("svm read pre: total dataset is %dx(1+%d)\n", N, M);
    }

    if (!reading) {
        // return the preread mode results, but only in preread mode
        err = SF_scal_save("_svm_load_N", (ST_double) N);
        if (err) {
            sterror("Unable to export scalar 'N' to Stata\n");
            return err;
        }

        err = SF_scal_save("_svm_load_M", (ST_double) M);
        if (err) {
            sterror("Unable to export scalar 'N' to Stata\n");
            return err;
        }
    }
    return 0;
}

ST_retcode export(int argc, char *argv[]) {
    ST_retcode err = 0;
    
    if(argc!=1) {
        sterror("export_svmlight: expected exactly one argument, the file to write to.\n");
        return 1;
    }
    
    FILE* fd = fopen(argv[0],"w");
    if(fd == NULL) {
        sterror("export_svmlight: unable to open %s: %s.\n", argv[0], strerror(errno));
        return 1;
    }

    for (ST_int i = SF_in1(); i <= SF_in2(); i++) {     //respect `in' option
        if (SF_ifobs(i)) {      //respect `if' option
            double value;
            err = SF_vdata(1, i, &value);
            if(err) { 
                sterror("export_svmlight: unable to read Stata value at [%d,%d]\n", 1, i);
                goto cleanup;
            }
            if(SF_is_missing(value)) { 
                sterror("export_svmlight: missing value for outcome variable [%d]; svmlight format cannot handle this\n", i);
                goto cleanup;
            }
            
            // TODO: is there a way to detect if the outcome is integer or not? it is safe to export, but it would be nice to not have to
            fprintf(fd, "%lf", value);
            
            for(int j=2; j<=SF_nvars(); j++) {
                err = SF_vdata(j, i, &value);
                if(err) { 
                    sterror("export_svmlight: unable to read Stata value at [%d,%d]\n", j, i);
                    goto cleanup;
                }
                if(SF_is_missing(value)/* || value == 0, uh oh, sklearn's load_svmlight_file() claims SVMLight treats missing entries as 0, *not* missing. TODO: check this outttttt. */) { 
                    continue; //missing values in the Xs are skipped; they are "sparse"
                }
                fprintf(fd, " %d:%lf", j-1, value);
            }
            fprintf(fd, "\n");
        }
    }
  
cleanup:
  fclose(fd);
  
  return err;
}


int stata_init() {
    return 0;
}