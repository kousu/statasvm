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
(if Stata was designed today it would have a CLI printing to stdout that the GUI ran in a subprocess; maybe they think there is some sort of DRM protection by forcing people to only run overnight batch jobs? */

void stdisplay(const char *fmt, ...)
{
    va_list args;

    // print to the standard stream
    va_start(args, fmt);
    vprintf(fmt, args);
    va_end(args);
    
    // print to Stata
    va_start(args, fmt);
    char buf[BUF_MAX];
    vsnprintf(buf, sizeof(buf), fmt, args);
    SF_display(buf);
    va_end(args);
}

void sterror(const char *fmt, ...)
{
    va_list args;
    
    // print to the standard stream
    va_start(args, fmt);
    vfprintf(stderr, fmt, args);
    va_end(args);
    
    // print to Stata
    va_start(args, fmt);
    char buf[BUF_MAX];
    vsnprintf(buf, sizeof(buf), fmt, args);
    SF_error(buf);
    va_end(args);
}

void stdebug(const char *fmt, ...)
{
    if(getenv("DEBUG") == NULL) { return; }

    va_list args;

    // print to the standard stream
    va_start(args, fmt);
    vfprintf(stderr, fmt, args);
    va_end(args);    

    // print to Stata
    va_start(args, fmt);
    char buf[BUF_MAX];
    vsnprintf(buf, sizeof(buf), fmt, args);
    SF_display(buf);    
    va_end(args);
}


