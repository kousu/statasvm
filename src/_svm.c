
#include <stdlib.h>
#include <stdio.h>

#include "stata/stplugin.h"
#include <svm.h>

// #include "svm-train.h" (which doesn't actually exist:)
void exit_with_help(void);
void read_problem(const char *filename);
extern struct svm_parameter param;
extern struct svm_problem prob;
extern struct svm_model *model;
extern struct svm_node *x_space;
// end "svm-train.h"

#if _WIN32
// MS is not standard C, of course:
// https://msdn.microsoft.com/en-us/library/2ts7cx93.aspx
#define snprintf _snprintf

#endif

void print_stata(const char* s) {
  SF_display((char*)s);
}

#if HAVE_SVM_PRINT_ERROR
// TODO: libsvm doesn't have a svm_set_error_string_function, but if I get it added this is the stub
void error_stata(const char* s) {
  SF_error((char*)s);
}
#endif


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
	for(int i=0; i<argc; i++)
	{
		printf("argv[%d]=%s\n",i,argv[i]);
	}
	
	printf("Total dataset size: %dx%d. We only want [%d:%d,%d] args, though.\n", SF_nobs(), SF_nvar(), SF_in1(), SF_in2(), SF_nvars());
#endif
	if(argc < 1) {
		return(102) ;  	    /* not enough variables specified */
	}

	print_stata("Stata-SVM v0.0.1\n") ;
	
	// libsvm
	svm_set_print_string_function(print_stata);
#if HAVE_SVM_PRINT_ERROR
	svm_set_error_string_function(error_stata);
#endif

	// default values
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


	for(ST_int j = SF_in1(); j <= SF_in2(); j++) {
		if(SF_ifobs(j)) {
		  //TODO
		}
	}
	
	char* dataset_file_name = argv[0];
	
	read_problem(dataset_file_name);

	const char *error_msg = NULL;
	error_msg = svm_check_parameter(&prob,&param);
	if(error_msg) {
		SF_error((char*)error_msg);
		return(1);
	}
	model = svm_train(&prob,&param);
	char model_file_name[256];
	snprintf(model_file_name, 256, "%s.svmfit", dataset_file_name);
	if(svm_save_model(model_file_name, model)) {
		SF_error("unable to export fitted model\n");
	}

	svm_free_and_destroy_model(&model);
	svm_destroy_param(&param);
	free(prob.y);
	free(prob.x);
	free(x_space);
	return(0) ;
}

