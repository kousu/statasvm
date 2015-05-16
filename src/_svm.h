/* header file for Stata-SVM extension module _svm.plugin */

#include <svm.h>
#include "stplugin.h"

#define PLUGIN_NAME "_svm"

#if _WIN32
// MS is not standard C, of course:
// https://msdn.microsoft.com/en-us/library/2ts7cx93.aspx
#define snprintf _snprintf
#endif


#define SUBCOMMAND_MAX 12 //this is good to have symbolically even if it doesn't actually enforce storage limits because reasons
                          // (if we say 'const char name[COMMAND_MAX]' then it is impossible to mark the last one with name = NULL, which is a bother)

struct svm_problem* stata2libsvm();
STDLL svmlight_read(int argc, char* argv[]);
STDLL train(int argc, char* argv[]);

//
STDLL stata_call(int argc, char *argv[]);
STDLL pginit(ST_plugin *p);
