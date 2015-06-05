
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>               //for NAN

#include "libsvm_patches.h"
#include "stutil.h"
#include "_svm.h"



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


// Stata's original language provided no encapsulation, and though it now has OOP (`help class`),
// most of the core functions don't use it. The expectation is instead that returns
// are done by editing a single global dictionary, one of r(), e() or c().
// We could probably fake encapsulation by storing our 'this' pointers in global macros with giant namespacing-faking prefixes,
// but this would be foreign to Stata's style anyway
// and break strangely if someone did "clear" in Stata (which would not notify ths plugin)
// And that is why there is a global here.
struct svm_model *model = NULL;




/* 
 * convert the Stata varlist format to libsvm sparse format
 * takes no arguments because the varlist is an implicit global (from stplugin.h)
 * as is Stata-standard, the first variable is the regressor Y, the rest are regressees (aka features) X
 * The result is a svm_problem, which is essentially just two arrays:
 * the Y vector and the X design matrix. See svm.h for details.
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
struct svm_problem *stata2libsvm()
{
    ST_retcode err;

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
            err = SF_vdata(1, i, &(prob->y[prob->l]));
            stdebug("Reading in Y[%d]=%lf, (err=%d)\n", i, prob->y[prob->l], err);
            if(err) {
                sterror("Unable to read Stata dependent variable column into libsvm\n");
                return NULL;
            }
            if(SF_is_missing(prob->y[prob->l])) {
                sterror("svm cannot handle missing data\n");
                goto cleanup;
            }

            // put data into X[l]
            // (there are many values)
            prob->x[prob->l] = calloc(SF_nvars(), sizeof(struct svm_node));     //TODO: make these inner arrays also dynamically grow. for a sparse problem this will drastically overallocate. (though I suppose your real bottleneck will be Stata, which doesn't do sparse)
            //svm_node[] is like a C-string: its actual length is one more than it's stated length, since it needs a final finisher token; so (SF_nvars()-1)+1 is the upper limit that we might need: -1 to take out the y column, +1 for the finisher token
            if (prob->x[prob->l] == NULL) {
                goto cleanup;
            }
            // libsvm uses a sparse datastructure, a pairlist [{index, value}, ...
            // the length of each row is indicated by index=-1 on the last entry]
            // which we faithfully fill in 
            // and which connotes that missing values should not be allocated, but empirically that causes wrong values,
            //  so we deny it (e.g. rho = all 0, sv_coef = all {-1, 1}), which means that it is actually impossible to input an actually sparse data structure

            int c = 0;          //and the current position within the subarray is tracked here
            for (int j = 1; j < SF_nvars(); j++) {
                ST_double value = NAN;
                if ((err = SF_vdata(j + 1
                                    /*this +1 accounts for the y variable: variable 2 in the Stata dataset is x1 */
                                    , i, &value))) {
                    sterror("error reading Stata columns into libsvm\n");
                    goto cleanup;
                }
                if (SF_is_missing(value)) {
                    sterror("svm cannot handle missing data\n");
                    goto cleanup;
                }
                prob->x[prob->l][c].index = j;
                prob->x[prob->l][c].value = value;
                c++;
            }
            prob->x[prob->l][c].index = -1;     //mark end-of-row
            prob->x[prob->l][c].value = SV_missval;     //not necessary for libsvm, but it makes me feel good
            prob->l++;
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



ST_retcode _model2stata(int argc, char *argv[])
{
    ST_retcode err = 0;

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

        /* take a break from this C routine (think of this as a coroutine, sort of) to communicate to the Stata routine what needs to be Stata-allocated */
        /* these macros have underscores because, according to the official docs, Stata actually only has a single global namespace for macros and just prefixes locals with _ */
        if (model->sv_indices != NULL) {
            err = SF_macro_save("_have_sv_indices", "1");
            if (err) {
                sterror("error writing to have_sv_indices\n");
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
        if (model->probA != NULL) {
            SF_macro_save("_have_probA", "1");
            if (err) {
                sterror("error writing to have_probA\n");
                return err;
            }
        }
        if (model->probB != NULL) {
            SF_macro_save("_have_probB", "1");
            if (err) {
                sterror("error writing to have_probB\n");
                return err;
            }
        }

    } else if (phase == '2') {
        
        char buf[20];
        char *strLabels = calloc(model->nr_class, sizeof(buf));
        if(strLabels == NULL) {
            sterror("unable to allocate memory for strLabels\n");
            return 1;
        }
        strLabels[0] = '\0';
        
        for (int i = 0; i < model->nr_class; i++) {
            /* copy out model->nSV */
            if (model->nSV) {
                err =
                    SF_mat_store("nSV", i + 1, 1,
                                 (ST_double) (model->nSV[i]));
                if (err) {
                    sterror("error writing to nSV\n");
                    return err;
                }
            }
            
            
            if (model->label) {
                /* copy out model->label */
                err = SF_mat_store("labels", i + 1, 1, (ST_double) (model->label[i]));  /* the name has been intentionally changed for readability */
                if (err) {
                    sterror("error writing to labels\n");
                    //XXX memory leak
                    return err;
                }
                
                /* copy out model->label *as a string of space separated tokens; this is a shortcut for 'matrix rownames' */
                snprintf(buf, sizeof(buf), " %d", model->label[i]);
                strncat(strLabels, buf, sizeof(buf));
                stdebug("strLabels now = |%s|\n", strLabels);
            }
        }
        err = SF_macro_save("_strLabels", strLabels);
        if(err) {
            sterror("error writing to strLabels\n");
            // XXX memory leak
            return err;
        }
        free(strLabels);

        /* copy out model->sv_coef */
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


        /* from the libsvm README:

           rho is the bias term (-b). probA and probB are parameters used in
           probability outputs. If there are k classes, there are k*(k-1)/2
           binary problems as well as rho, probA, and probB values. They are
           aligned in the order of binary problems:
           1 vs 2, 1 vs 3, ..., 1 vs k, 2 vs 3, ..., 2 vs k, ..., k-1 vs k. 

           in other words: upper triangularly.

           Rather than try to work out a fragile (and probably slow, requiring of the % operator)
           formula to map the array index to matrix indecies or vice versa, this loop simply
           walks *three* variables together: i,j are the matrix index, c is the array index.
         */
        int c = 0;
        for (int i = 0; i < model->nr_class; i++) {
            for (int j = i + 1; j < model->nr_class; j++) {
                /* copy out model->rho */
                if (model->rho) {
                    //printf("rho[%d][%d] == rho[%d] = %lf\n", i, j, c, model->rho[c]);
                    err =
                        SF_mat_store("rho", i + 1, j + 1,
                                     (ST_double) (model->rho[c]));
                    if (err) {
                        sterror("error writing to rho\n");
                        return err;
                    }
                }

                /* copy out model->probA */
                if (model->probA) {
                    //printf("probA[%d][%d] == probA[%d] = %lf\n", i, j, c, model->probA[c]);
                    err =
                        SF_mat_store("probA", i + 1, j + 1,
                                     (ST_double) (model->probA[c]));
                    if (err) {
                        sterror("error writing to probA\n");
                        return err;
                    }
                }


                /* copy out model->rho */
                if (model->probB) {
                    //printf("probB[%d][%d] == probB[%d] = %lf\n", i, j, c, model->probB[c]);
                    err =
                        SF_mat_store("probB", i + 1, j + 1,
                                     (ST_double) (model->probB[c]));
                    if (err) {
                        sterror("error writing to probB\n");
                        return err;
                    }
                }


                c++;            //step the array.
            }

        }
      
    
    } else if(phase == '3') {
        /* copy out model->sv_indices */
        /* see comments in _svm_model2stata.ado for why this is only a stop-gap */
    
        if (model->sv_indices) {
            for (int i = 0; i < model->l; i++) {
                printf("SVs[%d] = %d\n", i, model->sv_indices[i]);
                err = SF_vstore(1, (model->sv_indices[i]), (ST_double) 1);        /* I *believe* libsvm's sv_indices is 1-based, like Stata */
                if (err) {
                    sterror("error writing SVs: [1,%d]=1\n", model->sv_indices[i]);
                    return err;
                }
            }
        }
    }

    return 0;
}






struct {
    const char *name;
     ST_retcode(*func) (int argc, char *argv[]);
} subcommands[] = {
    {"train", train},
    {"predict", predict},
    {"export", export},
    {"import", import},
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
    if(strncmp(argv[0], "C_SVC", 10)==0) {
        param.svm_type = C_SVC;
    } else if(strncmp(argv[0], "NU_SVC", 10)==0) {
        param.svm_type = NU_SVC;
    } else if(strncmp(argv[0], "ONE_CLASS", 10)==0) {
        param.svm_type = ONE_CLASS;
    } else if(strncmp(argv[0], "EPSILON_SVR", 10)==0) {
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
    
    
    struct svm_problem *prob = stata2libsvm();
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

    if (model != NULL) {
        // we have a singleton struct svm_model, so we need to clean up the old one before allocating a new one
        svm_free_and_destroy_model(&model);     //_and_destroy() means set pointer to NULL
    }
    model = svm_train(prob, &param);    //a 'model' in libsvm is what I would call a 'fit' (I would call the structure being fitted to---svm---the model), but beggars can't be choosers

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
    
    // svm_predict.ado signals that we are in svm_predict_probability() mode by passing an order list of levels
    // corresponding to a trailing set of variables where writeback goes
    int no_levels = svm_get_nr_class(model);                 //the number of levels
    int no_vars = SF_nvars(); //the number of variables, i.e. n+1 in [y; x1; x2; ... ; xn]
    double *probabilities = NULL;
    if(argc > 0 && strcmp(argv[0],"probability")==0) {
        if(!svm_check_probability_model(model)) {
          sterror("svm_predict: active model cannot produce probabilities.\n");
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
          probabilities[k] = NAN;
        }
    }
    
    stdebug("svm_predict: no_levels = %d, no_vars = %d, probability mode = %s\n", no_levels, no_vars, probabilities ? "on" : "off");
    
    // TODO: error if probabilites is set but the svm_model is not a classification one
    // (svm_predict_probabilities should do this, but instead it just silently falls back
    
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
    
    //TODO: C doesn't have a real break outer, but if I factor out the svm_node[] generating loop I can use error returns to fake exceptions
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
                X[c].index = c+1; //hilarious: if index *doesn't* start from 1, instead of warning or crashing libsvm gives the same results for all predictions
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
              y = svm_predict(model, X);
            } else {
              y = svm_predict_probability(model, X, probabilities);
              
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
            err = SF_vstore(1 /*stata counts from 1 */ , i, y);
            if (err) {
                sterror("unable to store prediction\n");
                return err;
            }

        }
    }

cleanup:
    if(X) { free(X); }
    if(probabilities) { free(probabilities); }
    
    return err;
}


ST_retcode export(int argc, char *argv[])
{

    if (argc != 1) {
        sterror("Wrong number of arguments\n");
        return 1;
    }

    char *fname = argv[0];

    if (model == NULL) {
        sterror("svm_export: no trained model available to export\n");
        return 0;
    }

    if (svm_save_model(fname, model)) {
        sterror("svm_export: unable to export fitted model\n");
        return 1;
    }

    return 0;
}



ST_retcode import(int argc, char *argv[])
{

    if (argc != 1) {
        sterror("Wrong number of arguments\n");
        return 1;
    }

    if (model != NULL) {
        svm_free_and_destroy_model(&model);
    }

    char *fname = argv[0];
    if ((model = svm_load_model(fname)) == NULL) {
        sterror("unable to import fitted model\n");
        return 1;
    }

    return 0;
}






int stata_init() {
    svm_set_print_string_function(libsvm_display);
#ifdef HAVE_SVM_PRINT_ERROR
    svm_set_error_string_function(libsvm_error);
#endif
    return 0;
}

// stata_call is not here. it is in sttrampoline.c
