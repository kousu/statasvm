/*
    stplugin.c, version 2.0
    copyright (c) 2003, 2006        			StataCorp
    modified 2015        			        Nick Guenther
    
    This provides the entry point that is called when Stata loads an extension module from a DLL.
*/

#include "stplugin.h"

ST_plugin *_stata_ ;

STDLL pginit(ST_plugin *p)
{
	_stata_ = p ;
	if(stata_init()) {
            return 0; // XXX does this correctly signal to Stata that an error occurred?
        }
	return(SD_PLUGINVER) ;
}
