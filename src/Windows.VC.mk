
# The

# VC++ reference:
# from http://stackoverflow.com/questions/1130479/how-to-build-a-dll-from-the-command-line-in-windows-using-msvccl tells how to build a DLL
# http://blog.nuclex-games.com/2012/03/how-to-consume-dlls-in-visual-cxx/ tells how to link against other libraries
# in the worst case, the proper command line is listed in the Visual Studio C/C++ configuration pane if you go to the verrrry last page in a DLL project, but that means you need to construct such a project with the GUI first.
CFLAGS+=/GL /EHsc  #..I don't know what these are

# stplugin.h *defaults* to Windows if not given, and this is exactly what happens under the official instructions which tell you to use Visual Studio in its default configuration
# this also means that we *don't* bother to pass /DSYSTEM to the compiler.
CFLAGS+=/D_USRDLL /D_WINDLL #defines
CFLAGS+=/O2 #optimizations
CFLAGS+=/W3 /WX #turn up warnings, and make them crash the compile

LDFLAGS+=/DLL    #build a DLL instead of an EXE
LDFLAGS+=/LTCG   #causes whole-DLL optimization 

ifeq ($(Platform),X64)
  ARCH:=x86_64
else
  ARCH:=i386
endif

%.dll:
	cl /nologo $^  $(foreach L,$(LIBS),$L.lib) /link $(LDFLAGS) /OUT:$@

# this rule compiles a single .c file to a single .obj file
%.obj: %.c
	cl /nologo $(CFLAGS) /c $< /Fo$@
	
.PHONY: printdeps
printdeps:
	dumpbin /dependents $^