/* _svm.c: a Stata plugin to glue Stata to libsvm, providing the Support Vector Machine algorithm. */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>               //for NAN


#include "libsvm_patches.h"
#include "stutil.h"
#include "sttrampoline.h"
#include "_svm.h"



/* ******************************** */
/* platform cruft */
#ifndef HAVE_STRLCAT
#define HAVE_STRLCAT 1
#if __APPLE__
  /* OS X's libc has strlcat() */
#else
size_t strlcat(char * dst, const char * src, size_t size) {
        int d, s;
        d = strlen(dst);
        s = strlen(src);

        //stdebug("strlcat: dst[%d]='%s', src[%d]='%s', size=%d\n", s, dst, s, src, size);
#if _WIN32
        // TODO: check security ;)
        // TODO: find a better posix-to-windows compat libc
	errno_t err = strcat_s(dst, size, src);
	if(err) {
		// pass ???
                sterror("strlcat: errno=%d", err);
                return size; //strlcat can't signal an error directly, but all callers should be checking for the return to be size or more, signalling errorl
	}
#else
        /* strl*() gets the total length of the buffer, including the null;
         strn*() gets the length remaining;
         if dst is size in total, and d+1 is used already (d chars plus one nul which will be overwritten but recreated at the end),
         then there's size-(d+1) remaining
        */
        strncat(dst, src, size - d - 1); 
#endif // _WIN32
        // strlcat returns "the number of chars it tried to write" except if it overflows, in which "size" and it *doesn't* nul-terminate
        // notice that in proper operation the return value is always less than size, because the return value doesn't count the terminating null byte size does.
        // and anything else should be treated as an error
        return d + s < size ? d + s : size;
}
#endif //__APPLE__
#endif // HAVE_STRLCAT

/* ******************************** */
/* libsvm print hooks */

// these exist only to glue the small type variations together
static void libsvm_display(const char *s)
{
    stdisplay(s);
}

#ifdef HAVE_SVM_PRINT_ERROR
static void libsvm_error(const char *s)
{
    sterror(s);
}
#endif

static void libsvm_nodisplay(const char *s)
{
}

// Stata's original language provided no encapsulation, and though it now has OOP (`help class`),
// most of the core functions don't use it. The expectation is instead that returns
// are done by editing a single global dictionary, one of r(), e() or c().
// We could probably fake encapsulation by storing our 'this' pointers in global macros with giant namespacing-faking prefixes,
// but this would be foreign to Stata's style anyway
// and break strangely if someone did "clear" in Stata (which would not notify ths plugin)
// And that is why there is lobal state here;
struct svm_model *model = NULL;  // a fitted SVM model (or NULL)
int model_p = -1;                // the number of explanatory (X) variables; >= 0 when model is non-NULL;
                                 //   model doesn't track this because it works entirely in terms of kernel distances;
                                 //   instead it assumes that it can call "Kernel::k_function(x,model->SV[i],model->param);" and get a sensible result;
                                 //   but if the dimension of x doesn't agree with that of the i'th SV, there *will* be silent corruption.
                                 // In order to ensure predict() is behaving, it is simplest to have train() record model_p so that predict() can later check it was called correctly.



/* convert a (contiguous!) set of Stata variables x_l through x_u into a svm_node[].
 *
 * The range is *inclusive* of x_l and x_u (so the length is x_u - x_l + 1)
 * The row to read from is i.
 *
 * result is a array of svm_nodes; caller is responsible for freeing it when done; the result is slab-allocated so a single free() is enough.
 * If there was an error then err_missing, if non-null, tells if the exception was because of missing data (which libsvm does not handle);
 *  this is a kludge in order to support the subtly different uses this function has in the two places it is called.
 *
 * returns NULL if it fails.
 */
struct svm_node* stata_to_svm_nodes(int x_l, int x_u, int i, bool *err_missing) {

    if(err_missing) { *err_missing = false; }

    if(!( 1<= x_l && x_l <= x_u && x_u <= SF_nvars())) {
        sterror("stata_to_svm_nodes: x = [%d,%d] is not a valid subrange of available variables [%d,%d].\n", x_l, x_u, 1, SF_nvars());
        return NULL;
    }
    
    // svm_node[] is used like a C-string: its actual length is one more than it's stated length, since it needs a final finisher token.
    // the length of each row is indicated by index=-1 on the last entry]
    // also it's a sparse array: each entry is a pair {index, value}
    // which we faithfully fill in.
    // But, because Stata isn't sparse there's no win to trying to make the inner thing be sparse.
    // So the particular order of values doesn't matter and there can be gaps.
    // 
    // This datastructure connotes that missing values can (should?) not be allocated, and they'll just be ignored,
    // but empirically that causes wrong values (if you read libsvm::k_function() you can see why), so we deny it.
    struct svm_node* x = calloc(x_u - x_l + 1 + 1, sizeof(struct svm_node));
    if(x == NULL) {
        sterror("stata_to_svm_nodes: Unable to allocate memory.");
        return NULL;
    }
    
    double z;           // scratch space to pass data out of Stata
    int c = 0;          //and the current position within the subarray is tracked here
                        // note that this is ZERO-BASED not one-based like Stata; libsvm doesn't care what base you use so long as you are consistent
                        // TODO: factor predict() so that this code is the same as used there
    for (int j = x_l; j <= x_u; j++) { // this was j = 1 to SF_nvars() - 1, inclusive, which then was shifted by j+2 to 2 to SF_nvars() for everything
       if (SF_vdata(j, i, &z) != 0) {
            sterror("error reading Stata column %d on observation %d into libsvm\n", j, i);
            goto fail;
        }
        if (SF_is_missing(z)) {
            // Stata's regress and logistic and mlogit silently ignore missing data
            // but it's unclear what effect this will have long-term, so we ban it.
            if(err_missing) { *err_missing = true; }
            goto fail;
        }
        stdebug("read stata[%d,%d] = %f\n", j, i, z);
        x[c].index = c;
        x[c].value = z;
        c++;
    }
    x[c].index = -1;      // mark the last entry as end-of-row.
    x[c].value = NAN;     // setting this one is not actually necessary.

    return x;

fail:
    free(x);
    return NULL;
}

/* 
 * convert the Stata varlist format to libsvm sparse format
 *
 * y: the index of the outcome (Y) variable
 * x_l, x_u: the lower and upper bounds (inclusive!) of the explanator (aka features) (aka X) variables
 * 
 * The result is a svm_problem, which is essentially just two arrays:
 * the Y vector and the X design matrix. See svm.h for details of svm_problem.
 *
 * Note that this will mangle the indecies: the libsvm indecies will start from 1, mapping *whichever variable was 2nd given in varlist to 1, 3rd to 2, ...*.
 * If your workflow is "svm load using file.svmlight; svm train *" then there will be no mangling, but if you instead say "svm train y x3 x9" then 3 [Stata]->1 [libsvm] and 9 [Stata]->2 [libsvm]
 * this is acceptable since the libsvm indices are ephemeral, never exposed to the Stata user, it just makes debugging confusing.
 *
 * caller is responsible for freeing the result.
 * 
 * Compare sklearn's [dense2libsvm](TODO), which does the same job but coming from a numpy matrix instead 
 * TODO: factor into stata2svm_problem() and stata2svm_node(int obs, int startvar, int endvar)
 */
struct svm_problem *stata_to_svm_problem(int y, int x_l, int x_u)
{
    ST_retcode err = -1;
    double z = NAN;

    if(!( 1<= y && y <= SF_nvars())) {
        sterror("stata_to_svm_problem: y = %d is not in range of available variables [%d,%d].\n", y, 1, SF_nvars());
        goto cleanup;
    }

    struct svm_problem *prob = malloc(sizeof(struct svm_problem));
    if (prob == NULL) {
        sterror("stata_to_svm_problem: unable to allocate memory.");
        goto cleanup;
    }
    memset(prob, 0, sizeof(struct svm_problem));        //zap the memory just in case

    prob->l = 0;                //initialize the number of observations
    // we cannot simply malloc into mordor, because `if' and `in' cull what's available
    // so what we really need is a dynamic array
    // for now, in lieu of importing a datastructure to handle this, I'll do it with realloc
    int capacity = 1;
    prob->y = malloc(sizeof(*(prob->y)) * capacity);
    if (prob->y == NULL) {
        //TODO: error
        goto cleanup;
    }
    prob->x = malloc(sizeof(*(prob->x)) * capacity);
    if (prob->x == NULL) {
        //TODO: error
        goto cleanup;
    }

    // Copy in the data.
    // BEWARE:
    // This code is super prone to off-by-one errors because we're dealing with three enumeration systems:
    //  C's 0-based, Stata's 1-based, and libsvm's (.index) which is 0-based and also sparse
    for (ST_int i = SF_in1(); i <= SF_in2(); i++) {     //respect `in' option
        if (SF_ifobs(i)) {      //respect `if' option            
            if (prob->l >= capacity) {  // amortized-resizing
                capacity <<= 1; //double the capacity
                prob->y = realloc(prob->y, sizeof(*(prob->y)) * capacity);
                if (prob->y == NULL) {
                    //TODO: error
                    goto cleanup;
                }
                prob->x = realloc(prob->x, sizeof(*(prob->x)) * capacity);
                if (prob->x == NULL) {
                    //TODO: error
                    goto cleanup;
                }
            }
            // put data into Y[l]
            // (there is only one Y so we hard-code the variable index)
            err = SF_vdata(y, i, &z);
            stdebug("Reading in Y[%d]=%lf, (err=%d)\n", i, z, err);
            if(err) {
                sterror("Unable to read Stata dependent variable column into libsvm\n");
                return NULL;
            }
            if(SF_is_missing(z)) {
                // Stata's regress and logistic and mlogit silently ignore missing data
                // but it's unclear what effect this will have long-term, so we ban it.
                sterror("svm cannot handle missing data. Found at Y[%d]\n", i);
                goto cleanup;
            }
            prob->y[prob->l] = z;

            // put data into X[l]
            // (there are multiple values so we use a subroutine)
            bool missing;
            if((prob->x[prob->l] = stata_to_svm_nodes(x_l, x_u, i, &missing)) == NULL) {
                if(missing) {
                    sterror("missing data found in observation %d. svm cannot handle this.\n", i);
                }
                goto cleanup;
            }
            
            prob->l++;
        }
    }

    //return overallocated memory by downsizing
    prob->y = realloc(prob->y, sizeof(*(prob->y)) * prob->l);
    prob->x = realloc(prob->x, sizeof(*(prob->x)) * prob->l);

    return prob;

  cleanup:
    stdebug("stata_to_svm_problem failed\n");
    
    //TODO: clean up after ourselves
    //TODO: be careful to check the last entry for partially initialized subarrays
    return NULL;
}


// comparison callback for qsort()
int cmp_int(const void * a, const void * b)
{
    return (*(int*)a - *(int*)b);
}

ST_retcode _model2stata(int argc, char *argv[])
{
    ST_retcode err = 0;
    double z;

    if (argc != 1) {
        sterror("Wrong number of arguments\n");
        return 1;
    }
    // in combination with the read the model parameters out into the r() dict
    // again, we can't actually access r() directly.
    // All we have for communication are
    // - variables, which are reserved for the data table,
    // - macros, which are strings,h
    // - scalars, which can only be numeric in the C interface, though Stata can handle string scalars
    // - matrices
    // Further complicating things is that certain parts of svm_model are only applicable to certain svm_types (as documented in <svm.h>)
    // and further some of the values are matrices (probA and probB are, apparently, some sort of pairwise probability matrix between trained classes, but stored as a single array because the authors got lazy)
    // and further complicating things:
    if (model == NULL) {
        sterror("no trained model available\n");
        return 1;
    }

    char phase = argv[0][0];
    if (phase == '1') {
        /* copy out model->nr_class */
        SF_scal_save("_model2stata_nr_class", model->nr_class);

        /* copy out model->l */
        SF_scal_save("_model2stata_l", model->l);
		
        /* these macros have underscores because, according to the official docs, Stata actually only has a single global namespace for macros and just prefixes locals with _ */

#if LIBSVM_VERSION >= 320
        if (model->sv_indices != NULL) {
            err = SF_macro_save("_have_sv_indices", "1");
            if (err) {
                sterror("error writing to have_sv_indices\n");
                return err;
            }
        }
#endif
        if (model->sv_coef != NULL) {
            err = SF_macro_save("_have_sv_coef", "1");
            if (err) {
                sterror("error writing to have_sv_coef\n");
                return err;
            }
        }
        if (model->rho != NULL) {
            err = SF_macro_save("_have_rho", "1");
            if (err) {
                sterror("error writing to have_rho\n");
                return err;
            }
        }

    } else if (phase == '2') {
        
        char buf[20]; //XXX is 20 big enough?
        int lstrLabels = model->nr_class*sizeof(buf) + 1;
        char *strLabels = malloc(lstrLabels);
        if(strLabels == NULL) {
            sterror("unable to allocate memory for strLabels\n");
            return 1;
        }
        strLabels[0] = '\0';
        
		
        if (model->label) {
            for (int i = 0; i < model->nr_class; i++) {
                /* copy out model->label *as a string of space separated tokens; this is a shortcut for 'matrix rownames' */
                snprintf(buf, sizeof(buf), " %d", model->label[i]);
                if(strlcat(strLabels, buf, lstrLabels) >= lstrLabels) {
                  sterror("overflow while writing to _labels");
                  // XXX memory leak
                  return 1;
                }
                stdebug("labels now = |%s|\n", strLabels);
            }
        }
        err = SF_macro_save("_labels", strLabels);
        if(err) {
            sterror("error writing to _labels\n");
            // XXX memory leak
            return err;
        }
        free(strLabels);

        /* copy out model->sv_coef */
        // TODO: this should first check if the matrix exists (by trying to read it?)
        if(SF_mat_el("sv_coef", 1, 1, &z) == 0) {
            for (int i = 0; i < model->nr_class - 1; i++) { //the -1 is taken directly from <svm.h>! (plus this segfaults if it tries to read a next row). Because...between k classes there's k-1 decisions? or something? I wish libsvm actually explained itself.
                for (int j = 0; j < model->l; j++) {
                    err =
                        SF_mat_store("sv_coef", i + 1, j + 1,
                                     (ST_double) (model->sv_coef[i][j]));
                    if (err) {
                        sterror("error writing to sv_coef\n");
                        return err;
                    }
                }
            }
        }


        /* from the libsvm README:

           rho is the bias term (-b). probA and probB are parameters used in
           probability outputs. If there are k classes, there are k*(k-1)/2
           binary problems as well as rho, probA, and probB values. They are
           aligned in the order of binary problems:
           1 vs 2, 1 vs 3, ..., 1 vs k, 2 vs 3, ..., 2 vs k, ..., k-1 vs k. 

           : in other words: upper triangularly.

           Rather than try to work out a fragile (and probably slow, requiring of the % operator)
           formula to map the array index to matrix indecies or vice versa, this loop simply
           walks *three* variables together: i,j are the matrix index, c is the array index.
         */

        /* copy out model->rho */
        if (model->rho && SF_mat_el("rho", 1, 1, &z) == 0) {
          int c = 0;
          for (int i = 0; i < model->nr_class; i++) {
              for (int j = i + 1; j < model->nr_class; j++) {
                    //stdebug("rho[%d][%d] == rho[%d] = %lf\n", i, j, c, model->rho[c]);
                    err =
                        SF_mat_store("rho", i + 1, j + 1,
                                     (ST_double) (model->rho[c]));
                    if (err) {
                        sterror("error writing to rho\n");
                        return err;
                    }
                }
            }
        }

        /* copy out model->probA */
        if (model->probA && SF_mat_el("probA", 1, 1, &z) == 0) {
          int c = 0;
          for (int i = 0; i < model->nr_class; i++) {
              for (int j = i + 1; j < model->nr_class; j++) {
                    //stdebug("probA[%d][%d] == probA[%d] = %lf\n", i, j, c, model->probA[c]);
                    err =
                        SF_mat_store("probA", i + 1, j + 1,
                                     (ST_double) (model->probA[c]));
                    if (err) {
                        sterror("error writing to probA\n");
                        return err;
                    }
                }
            }
        }
        

        /* copy out model->probB */
        if (model->probB && SF_mat_el("probB", 1, 1, &z) == 0) {
          int c = 0;
          for (int i = 0; i < model->nr_class; i++) {
              for (int j = i + 1; j < model->nr_class; j++) {
                    //stdebug("probB[%d][%d] == probB[%d] = %lf\n", i, j, c, model->probB[c]);
                    err =
                        SF_mat_store("probB", i + 1, j + 1,
                                     (ST_double) (model->probB[c]));
                    if (err) {
                        sterror("error writing to probB\n");
                        return err;
                    }
                }
            }
        }
    
    } else if(phase == '3') {
#if LIBSVM_VERSION >= 320
        /* copy out model->sv_indices */
        /* these end up as indicators variables in the (single)  */
        if(SF_nvars() != 1) {
            sterror("wrong number of variables to _model2stata phase 3: got %d, expected 1\n", SF_nvars());
            return 3;
        }
        
        if (model->sv_indices) {
            // sort the indices, in place (libsvm does not guarantee this)
            // XXX is it safe to do this? does libsvm make assumptions about its array being unsorted?
            qsort(model->sv_indices, model->l, sizeof(*model->sv_indices), cmp_int);
            
            // if there are skipped rows (due to if/in) then the Stata indices get out of step with the sv_indices
            // to fix this, we assume sv_indices is sorted and walk three iterators in partial-lockstep:
            //  i over Stata rows
            //  k over libsvm rows -- which are a subset of the Stata rows, but with different indices because
            //   in svm_train only the subset matching if/in got fed to libsvm
            //   => PRECONDITION: the if/in conditions fed to model2stata() are identical to those fed to train() 
            //  s over support vectors, as stored in sv_indices
            ST_int i;
            int k = 1; //the content of sv_indices is 1-based, because libsvm is weird
            int s = 0; //the index of sv_indices is 0-based, because it's a C-array
            for (i = SF_in1(); i <= SF_in2(); i++) {     //respect `in' option
                stdebug("_model2stata phase 3: i=%d, k=%d, s=%d, \t sv_indices[%d]=%d (l=%d)\n", i, k, s,    s, model->sv_indices[s], model->l); 
                if (SF_ifobs(i)) {                              //respect `if' option
                    if(s >= model->l) {
                        // we ran out of SVs before we ran out of rows
                        // because we sorted, this simply means that the remainder are not support vectors:
                        // afterall, we just crossed the largest-index support vector.
                        break;
                    }                   
                    
                    if(k == model->sv_indices[s]) {
                        // when the (libsvm) row equals one of the recorded indices, we have found an SV.
                        // hurray!  Write the result back...
                        err = SF_vstore(1, i, (ST_double) 1);
                        if (err) {
                            sterror("_model2stata phase 3: error writing SV[%d]=1\n", i);
                            //return err;
                        }
                        // ...and advance which SV we're looking for.
                        s++;
                    }
                    k++;
                }
            }
            if(s != model->l) {
                // this should be impossible
                sterror("_model2stata phase 3: did not exhaust SV array by i=%d, k=%d. s=%d but there are %d SVs.\n", i, k, s, model->l);
                return 1;
            }
        }
#endif
    }

    return 0;
}






struct subcommand_t subcommands[] = {
    {"train", train},
    {"predict", predict},
    {"_model2stata", _model2stata},
    {NULL, NULL}
};





ST_retcode train(int argc, char *argv[])
{

    // XXX there is a VERY FIXED set of arguments
    // corresponding to entries
    // in a VERY PARTICULAR order
    // make sure you keep svm_train.ado and this function in sync
    if(argc != 12) {
        sterror("_svm_train: expected exactly 12 arguments. Do not try to call the plugin's train routine directly, use svm_train.ado\n");
        return 1;
    }
    
    if (SF_nvars() < 2) {
        sterror("_svm_train: need one dependent and at least one independent variable.\n");
        return 1;
    }
    
    
    struct svm_parameter param;
    
    // XXX there is a string<->enum mapping buried in the libsvm code somewhere, but it's got no API :(
    //     so the mapping is replicated ad naseum
    // enum { C_SVC, NU_SVC, ONE_CLASS, EPSILON_SVR, NU_SVR };	/* svm_type */
    if(strncmp(argv[0], "SVC", 10)==0) {
        param.svm_type = C_SVC;
    } else if(strncmp(argv[0], "NU_SVC", 10)==0) {
        param.svm_type = NU_SVC;
    } else if(strncmp(argv[0], "ONE_CLASS", 10)==0) {
        param.svm_type = ONE_CLASS;
    } else if(strncmp(argv[0], "SVR", 10)==0) {
        param.svm_type = EPSILON_SVR;
    } else if(strncmp(argv[0], "NU_SVR", 10)==0) {
        param.svm_type = NU_SVR;
    } else {
        sterror("_svm_train: unrecognized SVM type '%s'\n", argv[0]);
        return 1;
    }
    argc--; argv++; //shift
    
    // XXX ditto: copy-paste danger zone!
    //enum { LINEAR, POLY, RBF, SIGMOID, PRECOMPUTED }; /* kernel_type */
    if(strncmp(argv[0], "LINEAR", 10)==0) {
        param.kernel_type = LINEAR;
    } else if(strncmp(argv[0], "POLY", 10)==0) {
        param.kernel_type = POLY;
    } else if(strncmp(argv[0], "RBF", 10)==0) {
        param.kernel_type = RBF;
    } else if(strncmp(argv[0], "SIGMOID", 10)==0) {
        param.kernel_type = SIGMOID;
    } else if(strncmp(argv[0], "PRECOMPUTED", 10)==0) {
        param.kernel_type = PRECOMPUTED;
    } else {
        sterror("_svm_train: unrecognized kernel type '%s'\n", argv[0]);
        return 1;
    }
    argc--; argv++; //shift
    
    
    param.gamma = atof(argv[0]);
    argc--; argv++; //shift
    
    param.coef0 = atof(argv[0]);
    argc--; argv++; //shift;
    
    param.degree = atoi(argv[0]);
    argc--; argv++; //shift
    
    
    param.C = atof(argv[0]);
    argc--; argv++; //shift;
    
    param.p = atof(argv[0]);
    argc--; argv++; //shift
    
    param.nu = atof(argv[0]);
    argc--; argv++; //shift
    
    
    param.eps = atof(argv[0]);
    argc--; argv++; //shift
    
    // TODO:
    param.nr_weight = 0;
    param.weight_label = NULL;
    param.weight = NULL;
    
    
    param.shrinking = atoi(argv[0]);
    argc--; argv++; //shift
    
    param.probability = atoi(argv[0]);
    argc--; argv++; //shift
    
    param.cache_size = atoi(argv[0]);
    argc--; argv++; //shift
    
    // special case: gamma = 0 means gamma = not specified
    // default it to 1/num_features if not explicitly given
    // XXX i have no idea what any of these numbers represent in the algorithms
    if (param.gamma == 0) {
        // XXX is -1 correct here?
        param.gamma = ((double) 1) / (SF_nvars() - 1);  // remember: without the cast this does integer division and gives 0
    }
    

    if (model != NULL) {
        // we have a singleton struct svm_model, so we need to clean up the old one before allocating a new one
        svm_free_and_destroy_model(&model);     //_and_destroy() means set pointer to NULL
        model_p = -1;                           // and clear model_p, which is our extension to struct svm_model
    }
    
    
    struct svm_problem *prob = stata_to_svm_problem(1, 2, SF_nvars());
    if (prob == NULL) {
        //assumption: stata_to_svm_problem already printed relevant error messages
        return 1;
    }
    
    if(getenv("DEBUG")) {                    //this is wrapped here because svm_*_pprint() don't go through the hooks above
        stdebug("Parameters to svm_train with:\n");
        svm_parameter_pprint(&param);
        stdebug("Problem to svm_train on:\n");
        svm_problem_pprint(prob);
    }
    
    const char *error_msg = NULL;
    error_msg = svm_check_parameter(prob, &param);
    if (error_msg) {
        sterror("SVM parameter error: %s.\n", error_msg);
        svm_parameter_pprint(&param);
        return 1;
    }

    // compute the fit
    // a 'model' in libsvm is what I would call a 'fit', but beggars can't be choosers
    model = svm_train(prob, &param);
    model_p = SF_nvars() - 1;           // NB: pretend model_p is model->p;

    // export r(N)
    SF_scal_save("_model2stata_N", (ST_double)prob->l);
	
    svm_destroy_param(&param);  //the model copies 'param' into itself, so we should free it here
    //svm_problem_free(prob);   //but as the libsvm README warns, do not free a problem while its model is still about
    
	
    return 0;
}



/* 
 * wrap libsvm:svm_predict()
 * that function is *not* vectorized, but Stata is all about operating on whole datasets, so this is looped, in CPU
 */
ST_retcode predict(int argc, char *argv[])
{

    ST_retcode err = 0;

    if (model == NULL) {
        sterror("svm_predict: no active model\n");
        return 1;
    }
    
    int no_levels = svm_get_nr_class(model);                 //the number of levels
    int no_vars = SF_nvars(); //the number of variables, i.e. n+1 in [y; x1; x2; ... ; xn]
    double *probabilities = NULL;
    if(argc > 0 && strcmp(argv[0],"probability")==0) {
        if(!svm_check_probability_model(model)) {
            sterror("svm_predict: active model cannot produce probabilities.\n");
            return 1;
        }

        // svm_predict.ado must pass a trailing set of variables where writeback goes
        if((1 + model_p + no_levels) != SF_nvars()) {
            sterror("svm_predict: in probability mode, there must be exactly %d + %d + %d columns passed, but instead got %d columns.\n", 1, model_p, no_levels, SF_nvars());
            return 1;
        }
        no_vars -= no_levels;
        
        probabilities = calloc(no_levels, sizeof(double));
        if(probabilities == NULL) {
            sterror("svm_predict: unable to allocate memory\n");
            return 1;
        }
        
        // Init probabilities to catch bugs
        for(int k=0; k<no_levels; k++) {
            probabilities[k] = SV_missval;
        }

        argc--; argv++; //shift
    }
    
    // we can also ask for decision values (what the svm evaluates to classify things)
    // NOTE: the internal libsvm API says "decision values", but for conciseness we decided the external API says "scores". Keep this in mind as you read on.
    // (this is redundant in regression (NU/EPSILON_SVR) models, but we allow users to discover that for themselves)
    int no_level_pairs = no_levels*(no_levels - 1)/2; // how many *pairs of levels* there are, which is important to figure out which in the variable list corresponds to which here
    double* decision_values = NULL;
    bool decision = false;
    if(argc > 0 && strcmp(argv[0],"scores")==0) {
        if(probabilities) {
            sterror("svm_predict: probability and scores are mutually exclusive options.\n"); // because probability => svm_predict_probability() which uses generates predictions from the Platt-Scaled model instead of using decision values directly.
            // now clean up and bail
            free(probabilities);
            return 1;
        }
        // svm_predict.ado must pass a trailing set of variables where writeback goes
        if((1 + model_p + no_level_pairs) != SF_nvars()) {
            sterror("svm_predict: in scores mode, there must be exactly %d + %d + %d columns passed, but instead got %d columns.\n", 1, model_p, no_level_pairs, SF_nvars());
            return 1;
        }
        no_vars -= no_level_pairs;

        decision = true;
        argc--; argv++; //shift
    }
    // Allocate space for the lower-triangular matrix (compressed) that svm_predict_values() wants.
    // NB: we do this *regardless* of if decision is passed because then we can just call svm_predict_values() in all cases anyway;
    ///    svm_predict() internally does this allocation, so it saves no work (actually, uses a little extra CPU) to try to coordinate the right API with the given options.
    // NB: svm_predict() is misleading: it special-cases the classification models to fix no_level_pairs = 1,
    //     but svm.h and experiment both show "no_levels = 2 in regression/one class svm" which implies no_level_pairs = 1, so we can drop the special case
    //     however in EPSILON_SVR and NU_SVR, the single decision value is the same as the prediction, but redundant isn't /wrong/.
    decision_values = calloc(no_level_pairs, sizeof(double));
    if(decision_values == NULL) {
        sterror("svm_predict: unable to allocate memory\n");
        free(probabilities);
        return 1;
    }
    for(int k=0; k<no_level_pairs; k++) { // init decision_values to make bugs more obvious
        decision_values[k] = SV_missval;
    }
    
    stdebug("svm_predict: no_levels = %d, no_vars = %d, probability mode = %s, scores mode = %s\n", no_levels, no_vars, probabilities ? "on" : "off", decision ? "on" : "off");
        
    struct svm_node* X = NULL;
    for (ST_int i = SF_in1(); i <= SF_in2(); i++) {     //respect `in' option
        if (SF_ifobs(i)) {                              //respect `if' option
            // Map the current row into a libsvm svm_node list
            bool missing;
            if((X = stata_to_svm_nodes(2, no_vars, i, &missing)) == NULL) {
                if(missing) {
                    // we can't handle missing data directly, but we can "predict" missing.
                    // just skipping ("continue") the current observation effectively does this
                    // because svm_train.ado inits a column of missings for us to write into
                    continue;
                } else {
                    // but if the call failed for some other reason, we should bail
                    err = 1;
                    goto cleanup;
                }
            }
            
            // Do the prediction! (one observation at a time)
            double y;
            if(!probabilities) {
                y = svm_predict_values(model, X, decision_values);
                
                if(decision) {
                    // Export decision_values
                    // PRECONDITION: the variables as presented to the plugin are ordered *in the right order* for svm_predict_values (described in libsvm/README)
                    //   model->label[0] vs model->label[1], [...] model->label[0] vs model->label[no_levels], then
                    //   model->label[1] vs model->label[2] [...] model->label[1] vs model->label[no_levels], then
                    //   [...]
                    //   model->label[no_levels-2] vs model->label[no_levels-1],  model->label[no_levels-2] vs model->label[no_levels]
                    //   model->label[no_levels-1] vs model->label[no_levels]
                    for(int k=0; k<no_level_pairs; k++) {
                        err = SF_vstore(no_vars+1+k, i, decision_values[k]);
                        if(err) {
                            sterror("svm_predict: unable to writeback svm score %d (target column %d) at observation %d\n", k,  no_vars+1+k, i);
                            goto cleanup;
                        }
                    }
                }
            } else {
                // TODO: should we error if svm_model is not a classification?
                // (libsvm::svm_predict_probabilities() should be responsible for this, but instead it just silently falls back to svm_predict())

                y = svm_predict_probability(model, X, probabilities);
                
                // Export probabilities
                // PRECONDITION: the variables as presented to the plugin are ordered *in the same order as the levels in model->label and probabilities are ordered* 
                for(int k=0; k<no_levels; k++) {
                    err = SF_vstore(no_vars+1+k, i, probabilities[k]);
                    //stdebug("prob: [%d,%d]=%lf\n", i,no_vars+1+k,probabilities[k]);
                    if(err) {
                        sterror("svm_predict: unable to writeback probability for level #%d (target column %d) at observation %d\n", k,  no_vars+1+k, i);
                        goto cleanup;
                    }
                }
            }
            
            // Write back the prediction
            // by convention wtih svm_predict.ado, the 1th variable, i.e. the first on the varlist (not the first in the dataset), is the output location
            err = SF_vstore(1 /* stata counts from 1 */ , i, y);
            if (err) {
                sterror("predict: unable to store prediction to [%d,%d].\n", 1, i);
                goto cleanup;
            }
            
            free(X); X = NULL;
        }
    }

cleanup:
    if(X) { free(X); }
    if(probabilities) { free(probabilities); }
    if(decision_values) { free(decision_values); }
    
    return err;
}


STDLL stata_call(int argc, char *argv[])
{
    if(strncmp(argv[0], "verbose", 7) == 0) {
        argc--; argv++;
        
        svm_set_print_string_function(libsvm_display);
#ifdef HAVE_SVM_PRINT_ERROR
        svm_set_error_string_function(libsvm_error);
#endif
    }
    ST_retcode r = sttrampoline(argc, argv);
    
    
    svm_set_print_string_function(libsvm_nodisplay);
#ifdef HAVE_SVM_PRINT_ERROR
    svm_set_error_string_function(libsvm_nodisplay);
#endif
    
    return r;
}




int stata_init() {
    svm_set_print_string_function(libsvm_nodisplay);
#ifdef HAVE_SVM_PRINT_ERROR
    svm_set_error_string_function(libsvm_nodisplay);
#endif
    return 0;
}

