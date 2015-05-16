/* additions to libsvm */
/* this is much like libsvm_helper in sklearn's svm subproject; perhaps we can get our efforts rolled in upstream someday */
/* I haven't yet hit the point where I need to actually change libsvm itself, and C has no datastructure protections, so I can just add functions here to accomplish what I want */

#include <svm.h>

void svm_problem_pprint(struct svm_problem* prob);
void svm_parameter_pprint(struct svm_parameter* param);
void svm_problem_free(struct svm_problem* prob);