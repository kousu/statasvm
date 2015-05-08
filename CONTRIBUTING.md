Stata-SVM Contribution Guidelines
=================================


Licensing
---------

TODO


Git workflow
------------


We use the [tip](https://www.backblaze.com/blog/10-rules-for-how-to-write-cross-platform-code/) from BackBlaze that source control is our cross-platform sync method.

Whenever you make a change, you need to make sure it is cross-compatible.
In principle, the best way to do this is to use a testing branch that won't impinge on the main branch, perhaps `cross`. For example:
```
# ..make changes...
make test
git checkout [-b] cross
git add -u ... && git commit 
git push

ssh OSX
cd statasvm
git checkout [-b] cross
git pull 
make test
exit

ssh Windows #or maybe rdesktop, or VNC
cd statasvm
git checkout [-b] cross
git pull
make test
exit

# back on the original machine
git checkout master
git merge cross
```

If you don't have access to the range of platforms we're supporting, you need to get someone else to do this step

In practice, you can probably just push to master, like Brian BackBlaze suggests. It'll mean there might be awkward one-liner nit commits that end up on master,
but since we're using the decentralized Github workflow, your master is your own so so long as you immediately complete all the testing, this won't be a problem.
If you used `cross` these would end up there anyway (and you can always commit-squash them away if you are pedantic).
