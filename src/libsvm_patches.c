
#include <stdlib.h>
#include <stdio.h>
#include "libsvm_patches.h"

void svm_problem_pprint(struct svm_problem* prob) {
  for(int i=0; i<prob->l; i++) {
    printf("y:%lf,", prob->y[i]);
    for(int j=0; prob->x[i][j].index != -1; j++) {
      printf(" %d:%lf", prob->x[i][j].index, prob->x[i][j].value);
    }
    printf("\n");
  }
}


void svm_parameter_pprint(struct svm_parameter* param) {
	printf("svm_parameter %p:\n", param);
	
	printf("\tsvm_type: %d\n", param->svm_type); //TODO: map to enum names
	printf("\tkernel_type: %d\n", param->kernel_type);
	printf("\tdegree: %d\n", param->degree);
	
	printf("\tgamma: %lf\n", param->gamma);
	printf("\tcoef0: %lf \n", param->coef0);
	
	printf("\tcache_size: %lf\n", param->cache_size);
	printf("\teps: %lf \n", param->eps);
	printf("\tC: %lf\n", param->C);
	
	printf("\tnr_weight: %d\n", param->nr_weight);
	printf("\tweight_label @ %p: TODO \n", param->weight_label/*[i] for i in range smethingsomething*/);
	printf("\tweight @ %p: TODO \n", param->weight); //
	
	printf("\tnu: %lf\n", param->nu);
	printf("\tp: %lf\n", param->p);
	
	printf("\tshrinking: %d\n", param->shrinking); //TODO: these are booleans, not ints
	printf("\tprobability: %d\n", param->probability);
}

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