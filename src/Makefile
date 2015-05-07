


svm.plugin: svm.so
	mv $< $@

# Note: the stata docs (http://www.stata.com/plugins/) do not mention -fPIC, but they probably haven't used a recent GCC lately
svm.so:	svm.c stata/stplugin.c
	gcc -shared -fPIC -DSYSTEM=OPUNIX $^ -o $@

.PHONY: test
test: svmtest.do svm.plugin 
	stata -e $<
	cat svmtest.log

.PHONY: clean
clean:
	-rm *plugin
	-rm *so
	-rm *dll
	-rm *log
