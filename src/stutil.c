/* helpers and other sundry code for dealing with Stata
 * which is cross-plugin
 */


#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include "stutil.h"
#include "stplugin.h"

#define BUF_MAX 1024

/****************************/
/* Define better print routines,
  and support format strings
   which dual print to standard streams
   and to the Stata logfile,
  so that you can see their output as it happens and inline with where it happened relative to the other Stata output
(if Stata was designed today it would have a CLI printing to stdout that the GUI ran in a subprocess; maybe they think there is some sort of DRM protection by forcing people to only run overnight batch jobs?

 * TODO:
 * [ ] when Stata is run in console mode (which I think you can only do in the Unix build??) the dual print to std{out,err} and Stata
       duplicates the prints one after the other, but not in GUI mode where you only see the SF_{display,error}() calls.
       But it is sometimes very very useful to have the unbuffered output in case of crashes.
       so, if there could be some way to detect console vs GUI, from C, and disable the extra prints in that case, that would be good?
       c(console) == "console" when in console mode, "" when not. However, SF_scal_use("c(console)", ....) gives an error. Maybe the Stata forums will know.
 */

nomangle void stdisplay(const char *fmt, ...)
{
    va_list args;
    
    // print to Stata
    va_start(args, fmt);
    char buf[BUF_MAX];
    vsnprintf(buf, sizeof(buf), fmt, args);
    SF_display(buf);
    va_end(args);
}

nomangle void sterror(const char *fmt, ...)
{
    va_list args;
    
    // print to Stata
    va_start(args, fmt);
    char buf[BUF_MAX];
    vsnprintf(buf, sizeof(buf), fmt, args);
    SF_error(buf);
    va_end(args);
}

nomangle void stdebug(const char *fmt, ...)
{
    if(getenv("DEBUG") == NULL) { return; }

    va_list args;

    // print to the standard stream
    //va_start(args, fmt);
    //vfprintf(stderr, fmt, args);
    //va_end(args);    

    // print to Stata
    va_start(args, fmt);
    char buf[BUF_MAX];
    vsnprintf(buf, sizeof(buf), fmt, args);
    SF_display(buf);    
    va_end(args);
}


