
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

STDLL stata_call(int argc, char *argv[])
{
		printf("%d\n", argc);
	for(int i=0; i<argc; i++)
	{
		printf("[%d] %s\n",i,argv[i]);
	}
	if(argc < 1) {
		return(102) ;  	    /* not enough variables specified */
	}

	print_stata("Stata-SVM v0.0.1\n") ;
	
	// libsvm
	svm_set_print_string_function(print_stata);


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

