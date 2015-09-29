/* libsvm_patches.c: helper methods that fit with libsvm but are not provided by it */

#include <stdlib.h>
#include <stdio.h>
#include "stutil.h"
#include "libsvm_patches.h"


/* On Pretty Printing and Streams
 *
 * I would like to have these pprint() functions use libsvm's print function,
 * settable with svm_set_print_string_function(), and internally
 *  static void (*svm_print_string) (const char *);
 *
 * However getting at it is tricky. In addition to accessing global variables being super platform-fiddly:
 *  http://stackoverflow.com/questions/19373061/what-happens-to-global-and-static-variables-in-a-shared-library-when-it-is-dynam
 * libsvm has explicitly disallowed this by marking it as "static" and only providing a setter.
 *
 * Here is a reasonably unterrible way around that: use indirection:
 *  define my own module-global svm_print_string (suitably prefixed),
 *  have all the functions below use it,
 *  and make my own svm_set_print_string_function() (suitably prefixed),
 *  which duplicates its input to libsvm's internal version
 *  and replace all calls to libsvm's with mine.
 *  that way both the libsvm prints and the prints here should go to the identical function,
 *  and except for the prefix, no one's the wiser.
 *
 * That is not what I have done. Instead I've pulled in stutil.c, because it supports format args and supports my use case.
 * When libsvm's print function supports format args and adds a getter for the print function I will redo this to integrate properly.
 * or maybe I'll just try to get these patches rolled into libsvm.
 */


void svm_problem_pprint(struct svm_problem* prob) {
  for(int i=0; i<prob->l; i++) {
    stdisplay("y:%lf,", prob->y[i]);
    for(int j=0; prob->x[i][j].index != -1; j++) {
      stdisplay(" %d:%lf", prob->x[i][j].index, prob->x[i][j].value);
    }
    stdisplay("\n");
  }
}


void svm_parameter_pprint(struct svm_parameter* param) {
	stdisplay("struct svm_parameter @ %p:\n", param);

	stdisplay("\tsvm_type: %d\n", param->svm_type); //TODO: map to enum names
	stdisplay("\tkernel_type: %d\n", param->kernel_type); //TODO: ditto
	stdisplay("\n");

	stdisplay("\tgamma: %lf\n", param->gamma);
	stdisplay("\tcoef0: %lf \n", param->coef0);
	stdisplay("\tdegree: %d\n", param->degree);
	stdisplay("\n");

	stdisplay("\tC: %lf\n", param->C);
	stdisplay("\tp: %lf\n", param->p);
	stdisplay("\tnu: %lf\n", param->nu);
	stdisplay("\n");

	stdisplay("\teps: %lf \n", param->eps);
	stdisplay("\tshrinking: %s\n", param->shrinking ? "true" : "false" );
	stdisplay("\n");

	stdisplay("\tprobability: %s\n", param->probability ? "true" : "false");
	stdisplay("\tcache_size: %lf\n", param->cache_size);
	stdisplay("\n");

	stdisplay("\tnr_weight: %d\n", param->nr_weight);
	stdisplay("\tweight_label @ %p: [svm_parameter_pprint TODO] \n", param->weight_label/*[i] for i in range smethingsomething*/);
	stdisplay("\tweight @ %p: [svm_parameter_pprint TODO] \n", param->weight); //
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
