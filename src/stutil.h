#ifndef STUTIL_H
#define STUTIL_H

#include "stplugin.h"
#include "nomangle.h"

nomangle void stdisplay(const char *fmt, ...);
nomangle void sterror(const char *fmt, ...);
nomangle void stdebug(const char *fmt, ...);

#endif //STUTIL_H
