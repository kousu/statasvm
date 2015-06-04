
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
	printf("struct svm_parameter @ %p:\n", param);

	printf("\tsvm_type: %d\n", param->svm_type); //TODO: map to enum names
	printf("\tkernel_type: %d\n", param->kernel_type); //TODO: ditto
	printf("\n");

	printf("\tgamma: %lf\n", param->gamma);
	printf("\tcoef0: %lf \n", param->coef0);
	printf("\tdegree: %d\n", param->degree);
	printf("\n");

	printf("\tC: %lf\n", param->C);
	printf("\tp: %lf\n", param->p);
	printf("\tnu: %lf\n", param->nu);
	printf("\n");

	printf("\teps: %lf \n", param->eps);
	printf("\tshrinking: %s\n", param->shrinking ? "true" : "false" );
	printf("\n");

	printf("\tprobability: %s\n", param->probability ? "true" : "false");
	printf("\tcache_size: %lf\n", param->cache_size);
	printf("\n");

	printf("\tnr_weight: %d\n", param->nr_weight);
	printf("\tweight_label @ %p: [svm_parameter_pprint TODO] \n", param->weight_label/*[i] for i in range smethingsomething*/);
	printf("\tweight @ %p: [svm_parameter_pprint TODO] \n", param->weight); //
}

/* 
 * free an svm_problem structure.
 * DANGER: this assumes that entries in prob.x[] have been individually allocated
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
