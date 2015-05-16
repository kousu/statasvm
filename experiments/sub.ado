* experimenting with building subcommands
* I want to the equivalent of python's "def wrap(a, *rest): if a == 1: one(*rest)", where the arguments are
* Unfortunately, the Stata quoting rules are more arcane than even bash's
* references: poor amounts of googling, Nick Cox, and cluster.ado and duplicates.ado in the base library (neither of which 
program sub
  di "1: 0=`0'"
  gettoken subcmd 0 : 0
  di "2a: subcmd=`subcmd'"
  
  * wtf: this version works
  di "2b: 0=`0'"
  * while this version, the that's even more quoted, tries to evaluate the contents of the macro (and so dies with e.g. "using not found" because it thinks "using" is a Stata variable)
  *di "2b: 0="`0'""
  
  di "3: doing svm_`subcmd' `0'"
  sub_`subcmd' "`0'" /*<-- this doesn't do what you think: it passes a *single* argument to the the subcommand*/
  di "4"
end

program sub_x
  di "I am sub_x and 0=`0'"
  syntax , [o(int 2)]
  di "o = `o'"
end

program sub_y
  di "I am sub_y and 0=`0'"
end
