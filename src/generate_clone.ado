
/* generate a new variable, cloning the attributes (type, labels, etc) of an old */
program define generate_clone
  quietly {
  // the syntax is "generate_clone source target" where source is an existing variable and target is not
  // but the 'syntax' command doesn't (as far as I can see) support this: either it's all new or all old variables
  gettoken source 0 : 0
  syntax newvarname
  local target = "`varlist'"
  
  // save attributes
  local T : type `source' //the data type
  local N : variable label `source' //the human readable description
  local V : value label `source' // the name of the label map in use, if there is one
                                 // Stata maintains a dictionary of dictionaries, each of which
                                 // maps integers to strings. Multiple variables can share a dictionary,
                                 //though it is rare.
  
  // make new variable
  generate `T' `target' = .
  
  // clone attributes if they exist
  // (except for type, which always exists and cannot be reassigned without another 'generate' doing an appropriate malloc())
  if("`N'"!="") {
    label variable `target' "`N'"  //Yes, the setters and getters are
  }
  if("`V'"!="") {
    label value `target' "`V'"     //in fact reverses of each other
  }
  }
end
