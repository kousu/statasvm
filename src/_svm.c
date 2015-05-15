
#include <stdlib.h>
#include <string.h> //..yes.. there are two string headers
#include <strings.h>

#include <svm.h>
#include "stplugin.h"

#include <stdio.h>

#define PLUGIN_NAME "_svm"

#if _WIN32
// MS is not standard C, of course:
// https://msdn.microsoft.com/en-us/library/2ts7cx93.aspx
#define snprintf _snprintf
#endif

/* 
 * free an svm_problem structure.
 * this assumes that entries in prob.x[] have been individually allocated
 * which is not something currently guaranteed by libsvm
 * (just see their bundled svm-train.c's use of 'x_space' for a quick and therefore dirty approach).
 * it also assumes that the svm_problem itself is allocated on the heap,
 *   again is not guaranteed by libsvm.
 */
void svm_problem_free(struct svm_problem* prob) {
  for(int i=0; i<prob->l; i++) {
    free(prob->x[i]);
  }
	free(prob->y);
	free(prob->x);
	free(prob);
}


/* Stata doesn't let C plugins add new variables
 * but parsing is terribly slow in pure Stata, demonstrably slower than in pure C
 * This pair of routines is the best ugly marriage I can achieve:
 *
 * We adopt the libsvm people's solution: scan the data twice, once two find out the size (which is then passed back to pure Stata which has permission to edit the data table)
 * and twice to actually fill it in.
 *
 * The variables created will be 'y' and 'x%d' for %d=[1 through max(feature_id)].
 * Feature IDs are always positive integers, in svmlight format, according to its source code.
 *
 * Special case: the tag on an X variable (a 'feature') could also be the special words
 * "sid:" or "cost:" (slack and weighting tweaks, respectively), according to the svmlight source.
 * libsvm does not support these so for simplicity neither do we.
 *
 */

//TODO: document
//TODO: better errors (using an err buf)
/* preread: scan */
STDLL svmlight_preread(int argc, char* argv[]) {
  
  ST_retcode err = 0;
  
  if(argc != 1) {
    SF_error("Wrong number of arguments\n");
    return 1;
  }
  
  char* fname = argv[0];
  FILE* fd = fopen(fname, "r");
  if(fd == NULL) {
    SF_error("Unable to open file\n");
    return 1;
  }
  
  
  
  int M = 0, N = 0;
  
  // N is the number of lines
  // M is the *maximum* number of features in a single line
  	
	double y;
	
	long int id;
	double x;
	
  while(1) {
	  if(fscanf(fd, "%lf", &y) != 1) { //this should get the first 'y' value
	    // if it doesn't... we must be at the end of file... maybe
	    break;
	  }
	  
  	N+=1;
  	printf("at line %d; M=%d\n", N, M);
  	
  	while(fscanf(fd, "%ld:%lf", &id, &x) == 2) {
	    if(M < id) M = id;
  	}
  	
  }
  
  
  err = SF_scal_save("N", (ST_double)N);
  if(err) {
    SF_error("Unable to export scalar 'N' to Stata\n");
    return err;
  }
  
  err = SF_scal_save("M", (ST_double)M);
  if(err) {
    SF_error("Unable to export scalar 'N' to Stata\n");
    return err;
  }
  
  
  return 0;
}


/* 
 * convert the Stata varlist format to libsvm sparse format
 * takes no arguments because the varlist is an implicit global (from stplugin.c)
 * the result is a a "problem":
 *  two arrays of the same length, one of doubles (y) and one of pairs of 'index' and double (x)
 * in other words, it's the outcome vector Y and the design matrix X.
 *  (plus 'l', the length of the arrays)
 *
 * caller owns (i.e. is responsible for svm_free_problem()'ing) the result
 */
struct svm_problem* stata2libsvm() {
  struct svm_problem* prob = malloc(sizeof(struct svm_problem));
  bzero(prob, sizeof(struct svm_problem)); //zap the memory just in case
  
  prob->l = 0; //initialize the number of observations
  // we cannot simply malloc into mordor, because `if' and `in' cull what's available
  // so what we really need is a dynamic array
  // for now, in lieu of importing a datastructure to handle this, I'll do it with realloc
  int capacity = 1;
  prob->y = malloc(sizeof(*(prob->y))*capacity);
  if(prob->y == NULL) {
    //TODO: error
    goto cleanup;
  }
  prob->x = malloc(sizeof(*(prob->x))*capacity);
  if(prob->x == NULL) {
    //TODO: error
    goto cleanup;
  }
  
  //TODO: double-check this for off-by-one bugs
  
	for(ST_int i = SF_in1(); i <= SF_in2(); i++) { //respect `in' option
		if(SF_ifobs(i)) {			    									 //respect `if' option
			if(prob->l >= capacity) {	// amortized-resizing
				capacity<<=1; //double the capacity
				prob->y = realloc(prob->y, sizeof(*(prob->y))*capacity);
				prob->x = realloc(prob->x, sizeof(*(prob->x))*capacity);
			}
			
			// put data into Y[l]
			// (there is only one value)
			SF_vdata(0, prob->l, &(prob->y[prob->l]));
			
			// put data into X[l]
			// (there are many values)
			for(int j=1; j<SF_nvars(); j++) {
				ST_double value;
				SF_vdata(j, prob->l, &value);
				if(!SF_is_missing(value)) {
					// libsvm uses a sparse datastructure
					// that means that missing values should not be allocated
					prob->x[prob->l] = malloc(sizeof(struct svm_node));
					if(prob->x[prob->l] == NULL) {
						// TODO: error
						goto cleanup;
					}
					prob->x[prob->l]->index = j;
					prob->x[prob->l]->value = value;
				}
			}
			prob->l++;
		}
	}

  //return overallocated memory by downsizing
	prob->y = realloc(prob->y, sizeof(*(prob->y))*prob->l);
	prob->x = realloc(prob->x, sizeof(*(prob->x))*prob->l);
	
	return prob;
	
cleanup:
	//TODO: be careful to check the last entry for partially initialized
	return NULL;
}


STDLL train(int argc, char* argv[]) {
	
	struct svm_parameter param;
	// set up svm_paramet default values
	
	// TODO: pass (probably name=value pairs on the "command line")
	param.svm_type = C_SVC;
	param.kernel_type = RBF;
	param.degree = 3;
	param.gamma = 0;	// 1/num_features
	param.coef0 = 0;
	param.nu = 0.5;
	param.cache_size = 100;
	param.C = 1;
	param.eps = 1e-3;
	param.p = 0.1;
	param.shrinking = 1;
	param.probability = 0;
	param.nr_weight = 0;
	param.weight_label = NULL;
	param.weight = NULL;
	
	struct svm_problem* prob = stata2libsvm();
	const char *error_msg = NULL;
	error_msg = svm_check_parameter(prob,&param);
	if(error_msg) {
		char error_buf[256];
		snprintf(error_buf, 256, "Parameter error: %s", error_msg);
		SF_error((char*)error_buf);
		return(1);
	}
	
	struct svm_model* model = svm_train(prob,&param); //a 'model' in libsvm is what I would call a 'fit' (I would call the structure being fitted to---svm---the model), but beggars can't be choosers
	
#if DEBUG
	if(svm_save_model("svmfit", model)) {
		SF_error("DEBUG ERROR: unable to export fitted model\n");
	}
#endif
	svm_destroy_param(&param); //the model copies 'param' into itself, so we should free it here
	svm_problem_free(prob);
	
	//svm_free_and_destroy_model(&model); //XXX when should this happen? this should get stored so we can call predict() on it. does 'program drop _svm' autofree all memory too?
  // should 'model' be a global?????? that's so against my training, but it's also sort of how Stata rolls.
  
  return 0;
}





void print_stata(const char* s) {
  SF_display((char*)s);
}

#if HAVE_SVM_PRINT_ERROR
// TODO: libsvm doesn't have a svm_set_error_string_function, but if I get it added this is the stub
void error_stata(const char* s) {
  SF_error((char*)s);
}
#endif


/* Initialization code adapted from
    stplugin.c, version 2.0
    copyright (c) 2003, 2006        			StataCorp
 */ 
ST_plugin *_stata_ ;

STDLL pginit(ST_plugin *p)
{
	_stata_ = p ;
	
	svm_set_print_string_function(print_stata);
#if HAVE_SVM_PRINT_ERROR
	svm_set_error_string_function(error_stata);
#endif
	
	return(SD_PLUGINVER) ;
}



/* Stata only lets an extension module export a single function (which I guess is modelled after each .ado file being a single function, a tradition Matlab embraced as well)
 * to support multiple routines the proper way we would have to build multiple DLLs, and to pass variables between them we'd have to figure out
 * instead of fighting with that, I'm using a tried and true method: indirection:
 *  the single function we export is a trampoline, and the subcommands array the list of places it can go to
 */
#define COMMAND_MAX 12 //this isn't actually used to enforce storage limits in subcommands (if we say 'const char name[COMMAND_MAX]' then it is impossible to define the last one as NULL, which is a bother, subcommands should respect this
struct {
  const char* name;
  STDLL (*func)(int argc, char* argv[]);
} subcommands[] = {
	{ "preread", svmlight_preread },
  { "train", train },
  //{ "predict", predict },
  { NULL, NULL }
};

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
#if DEBUG
	print_stata("Stata-SVM v0.0.1\n") ;
	for(int i=0; i<argc; i++)
	{
		printf("argv[%d]=%s\n",i,argv[i]);
	}
	
	printf("Total dataset size: %dx%d. We only want [%d:%d,%d] args, though.\n", SF_nobs(), SF_nvar(), SF_in1(), SF_in2(), SF_nvars());
#endif
	if(argc < 1) {
		SF_error(PLUGIN_NAME ": no subcommand specified\n");
		return(1);
	}
	
	char* command = argv[0];
	argc--; argv++; //shift off the first arg before passing argv to the subcommand
	
	int i = 0;
	while(subcommands[i].name) {
		char err_buf[256];
		snprintf(err_buf, 256, PLUGIN_NAME ": comparing |%s| to |%s|; argc=%d\n", command, subcommands[i].name, argc);
		printf(err_buf);
		if(strncmp(command, subcommands[i].name, COMMAND_MAX) == 0) {
			return subcommands[i].func(argc, argv);
		}
		
		i++;
	}
	
	char err_buf[256];
	snprintf(err_buf, 256, PLUGIN_NAME ": unrecognized subcommand |%s|\n", command);
	SF_error(err_buf);
	
	return 1;
}

