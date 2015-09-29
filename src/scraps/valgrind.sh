valgrind --log-file=gridsearch_leak.log -v --leak-check=full --show-leak-kinds=all --track-origins=yes --trace-children=yes time stata do tests/gridsearch.do
