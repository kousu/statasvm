#ifndef NOMANGLE_H
#define NOMANGLE_H

/* define the 'nomangle' keyword for functions tells C++ not to name-mangle it (this is important for linking C and C++ code together) */
// unfortunately C is picky: 'extern "C"' is not a part of the C language, so we need to switch on which language we're in 
#undef nomangle
#if __cplusplus
#define nomangle extern "C"
#else
#define nomangle
#endif

#endif //NOMANGLE_H