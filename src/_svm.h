/* header file for Stata-SVM extension module _svm.plugin */

#include <svm.h>
#include "stplugin.h"

#if _WIN32
// MS is not standard C, of course:
// https://msdn.microsoft.com/en-us/library/2ts7cx93.aspx
#define snprintf _snprintf
#endif


extern struct svm_model* model;

struct svm_problem* stata2libsvm();
ST_retcode train(int argc, char* argv[]);
ST_retcode predict(int argc, char* argv[]);
ST_retcode export(int argc, char* argv[]);
ST_retcode import(int argc, char* argv[]);

