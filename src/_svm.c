/* _svm.c: a Stata plugin to glue Stata to libsvm, providing the Support Vector Machine algorithm. */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>               //for NAN

#if __linux__
#include <bsd/string.h>
#endif

#include "libsvm_patches.h"
#include "stutil.h"
#include "sttrampoline.h"
#include "_svm.h"



/* ******************************** */
/* platform cruft */
#if _WIN32

// TODO: check security ;)
// TODO: find a posix-to-windows compat libc
size_t strlcat(char * dst, const char * src, size_t size) {
	errno_t err = strcat_s(dst, size, src);
	if(err) {
		// pass
	}
	return strlen(dst) + strlen(src);
}


#endif

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
struct svm_problem *stata2libsvm(int y, int x_l, int x_u)
{
    ST_retcode err = -1;
    double z = NAN;

    if (SF_nvars() < 1) {
        sterror("stata2libsvm: no outcome variable specified\n");
        return NULL;
    }

    struct svm_problem *prob = malloc(sizeof(struct svm_problem));
    if (prob == NULL) {
        // TODO: error
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
    //TODO: double-check this for off-by-one bugs
    // This code is super confusing because we're dealing with three numbering systems: C's 0-based, Stata's 1-based, and libsvm's (.index) which is 0-based but sparse

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
                // regress and logistic and mlogit silently ignore missing data
                // since that is drastically easier for everyone, we'll do that too
                // although it will lead to silent bias if the user doesn't notice
                stdebug("skipping because Y[%d] is missing\n", i);
                continue;
            }
            prob->y[prob->l] = z;

            // put data into X[l]
            // (there are many values)
            prob->x[prob->l] = calloc(SF_nvars(), sizeof(struct svm_node));     //TODO: make these inner arrays also dynamically grow. for a sparse problem this will drastically overallocate. (though I suppose your real bottleneck will be Stata, which doesn't do sparse)
            //svm_node[] is like a C-string: its actual length is one more than it's stated length, since it needs a final finisher token; so (SF_nvars()-1)+1 is the upper limit that we might need: -1 to take out the y column, +1 for the finisher token
            if (prob->x[prob->l] == NULL) {
                goto cleanup;
            }
            // libsvm uses a sparse datastructure, a pairlist [{index, value}, ...
            // the length of each row is indicated by index=-1 on the last entry]
            // which we faithfully fill in.
            // This datastructure connotes that missing values can (should?) not be allocated, but empirically that causes wrong values,
            //  so we deny it (e.g. rho = all 0, sv_coef = all {-1, 1}), which means that it is actually impossible to input an actually sparse data structure

            int c = 0;          //and the current position within the subarray is tracked here
                                // note that this is ZERO-BASED not one-based like Stata; libsvm doesn't care what base you use so long as you are consistent
                                // TODO: factor predict() so that this code is the same as used there
            for (int j = x_l; j <= x_u; j++) { // this was j = 1 to SF_nvars() - 1, inclusive, which then was shifted by j+2 to 2 to SF_nvars() for everything
                if ((err = SF_vdata(j, i, &z))) {
                    sterror("error reading Stata columns into libsvm\n");
                    goto cleanup;
                }
                if (SF_is_missing(z)) {
                    stdebug("skipping because X[%d,%d] is missing\n", i, j);
                    goto continue_outer; // see above
                    // XXX memory leak
                }
                stdebug("read stata[%d,%d] = %f\n", j, i, z);
                prob->x[prob->l][c].index = c;
                prob->x[prob->l][c].value = z;
                c++;
            }
            prob->x[prob->l][c].index = -1;      //mark the next entry as the current end-of-row
            prob->x[prob->l][c].value = NAN;     //libsvm is *supposed* to ignore this; if you get NaNs everywhere you have a clue it didn't.
            prob->l++;
continue_outer:
            (void)z; /*NOP*/
        }
    }

    //return overallocated memory by downsizing
    prob->y = realloc(prob->y, sizeof(*(prob->y)) * prob->l);
    prob->x = realloc(prob->x, sizeof(*(prob->x)) * prob->l);

    return prob;

  cleanup:
    stdebug("XXX stata2libsvm failed\n");
    
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
        if (model->sv_indices != NULL) {
            err = SF_macro_save("_have_sv_indices", "1");
            if (err) {
                sterror("error writing to have_sv_indices\n");
                return err;
            }
        }
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
                strlcat(strLabels, buf, lstrLabels);
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
    
    
    struct svm_problem *prob = stata2libsvm(1, 2, SF_nvars());
    if (prob == NULL) {
        //assumption: stata2libsvm has already printed any relevant error messages
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
    // (this is redundant in regression (NU/EPSILON_SVR) models, but we allow users to discover that for themselves)
    int no_level_pairs = no_levels*(no_levels - 1)/2; // how many *pairs of levels* there are, which is important to figure out which in the variable list corresponds to which here
    double* decision_values = NULL;
    bool decision = false;
    if(argc > 0 && strcmp(argv[0],"decision")==0) {
        if(probabilities) {
            sterror("svm_predict: probability and decision are mutually exclusive options.\n"); // because probability => svm_predict_probability() which uses generates predictions from the Platt-Scaled model instead of using decision values directly.
            // now clean up and bail
            free(probabilities);
            return 1;
        }
        // assert 1 + no_level_pairs + no_vars
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
    
    stdebug("svm_predict: no_levels = %d, no_vars = %d, probability mode = %s, decision mode = %s\n", no_levels, no_vars, probabilities ? "on" : "off", decision ? "on" : "off");
    
    // TODO: error if probabilites is set but the svm_model is not a classification one
    // (svm_predict_probabilities should do this, but instead it just silently falls back to svm_predict())
    
    if (no_vars < 1) {
        sterror("svm_predict: need at least a target\n");
        return 1;
    }
    
    struct svm_node *X = calloc(no_vars, sizeof(struct svm_node));
    if (X == NULL) {
        sterror("svm_predict: unable to allocate memory\n");
        err = 1;
        goto cleanup;
    }
    
    //TODO: C doesn't have a real `break outer`, but if I factor out the svm_node[] generating loop I can use error returns to fake exceptions
    //      for now a flag will have to do
    //      this is used let the inner loop cause the outer loop to skip to the next observation if one of the datapoints is bad
    bool continue_outer = false;
    
    for (ST_int i = SF_in1(); i <= SF_in2(); i++) {     //respect `in' option
        if (SF_ifobs(i)) {      //respect `if' option
            // Map the current row into a libsvm svm_node list
            //XXX TODO: this code was copied verbatim from stata2libsvm then tweaked; it needs to be factored instead!!
            
            // libsvm uses a sparse datastructure
            // that means that missing values should not be allocated
            // the length of each row is indicated by index=-1 on the last entry
            int c = 0;          //and the current position within the subarray is tracked here
            for (int j = 2; j <= no_vars; j++) {
                ST_double value;
                err = SF_vdata(j, i, &value);
                //stdebug("[%d,%d]=%lf\n", i,j,value);
                if(err) {
                  sterror("svm_predict: unable to read observation %d, column %d. err=%d\n", i, j, err);
                  goto cleanup;
                }
                if(SF_is_missing(value)) {
                  stdebug("svm_predict: svm cannot handle missing data (found at observation %d, column %d), so skipping.\n", i, j);
                  continue_outer = true;
                  break;
                }
                X[c].index = c;
                X[c].value = value;
                c++;
            }
            if(continue_outer) {
              continue_outer = false;
              continue;
            }
            X[c].index = -1;    //mark end-of-row
            X[c].value = SV_missval;    //not strictly necessary, but it makes me feel good
            
            // do the prediction! (one observation at a time)
            double y;
            if(!probabilities) {
              y = svm_predict_values(model, X, decision_values);
            } else {
              y = svm_predict_probability(model, X, probabilities);
              
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
            
            // write back
            // by convention wtih svm_predict.ado, the 1th variable, i.e. the first on the varlist (not the first in the dataset), is the output location
            err = SF_vstore(1 /* stata counts from 1 */ , i, y);
            if (err) {
                sterror("unable to store prediction\n");
                return err;
            }

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

