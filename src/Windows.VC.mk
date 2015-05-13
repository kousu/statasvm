
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

LDFLAGS+=/LTCG /DLL  #copied from VC

# these build recipes are 

#NB: this template rule doesn't have any dependencies specified, but is uses them ($^).
#    this means you need to give them, by saying, e.g. `mylib.dll: mymain.obj myutil.obj`
%.dll:
	cl /nologo $^ /link $(LDFLAGS) /OUT:$@

# this rule compiles a single .c file to a single .obj file
%.obj: %.c
	cl /nologo $(CFLAGS) /c $< /Fo$@