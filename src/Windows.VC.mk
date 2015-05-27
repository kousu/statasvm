
OBJEXT:=obj

# VC++ reference:
# from http://stackoverflow.com/questions/1130479/how-to-build-a-dll-from-the-command-line-in-windows-using-msvccl tells how to build a DLL
# http://blog.nuclex-games.com/2012/03/how-to-consume-dlls-in-visual-cxx/ tells how to link against other libraries
# in the worst case, the proper command line is listed in the Visual Studio C/C++ configuration pane if you go to the verrrry last page in a DLL project, but that means you need to construct such a project with the GUI first.
CFLAGS+=/GL /EHsc  #..I don't know what these are
CFLAGS+=/D _CRT_SECURE_NO_DEPRECATE #TEMPORARY: this tells VC to ignore that 'strtok' and friends are inherently unsafe, code which is used liberally through svm-train.c

# stplugin.h *defaults* to Windows if not given, and this is exactly what happens under the official instructions which tell you to use Visual Studio in its default configuration
# this also means that we *don't* bother to pass /DSYSTEM to the compiler.
CFLAGS+=/D_USRDLL /D_WINDLL #defines; TODO: factor
CFLAGS+=/O2 #optimizations
CFLAGS+=/W3 /WX #turn up warnings, and make them crash the compile
  
LDFLAGS+=/DLL    #build a DLL instead of an EXE
LDFLAGS+=/LTCG   #causes whole-DLL optimization 

# /nologo 
CC:=cl /nologo

# Windows doesn't have uname; instead we have to check the variable set by vcvarsall.bat to figure out what arch we're building for
# the *output* here *is* in posix uname -m format, though.
ifeq ($(Platform),X64)
  ARCH:=x86_64
else
  ARCH:=i386
endif

%.dll:
#see Windows_NT.mk for why "FIXED_LIBS"
	$(CC) $^ $(foreach L,$(FIXED_LIBS),$L.lib) /link $(LDFLAGS) /OUT:$@

# this rule compiles a single .c file to a single .obj file
%.obj: %.c
	$(CC) $(CFLAGS) /c $< /Fo$@
	
.PHONY: printdeps
printdeps:
	dumpbin /dependents $^
