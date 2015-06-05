
* TODO: rename to 'clone'
/* generate a perfect copy of a variable, (type, labels, etc) of an variable

 syntax:
  clone newvar oldvar [if] [in]
 
 You can use 'if' and 'in' to control what values; values that don't match will be set to missing.
 If you want to clone a variable's metadata but not values use the idiom ". clone new old if 0".

 The reason the syntax is not "clone newvar = oldvar" is because but =/exp insists on numeric expressions,
 so string variables wouldn't be cloneable.
 */
 

program define clone
  // parse once to extract the basic pieces of syntax
  syntax namelist [if] [in]
  local _if = "`if'" //save these for later; the other syntax commands will smash them
  local _in = "`in'"
  
  gettoken target source : namelist
  
  // enforce types
  
  // newvar
  local 0 = "`target'"
  syntax newvarname
  
  // oldvar
  local 0 = "`source'"
  syntax varname
  
  // save attributes
  local T : type `source' //the data type
  local N : variable label `source' //the human readable description
  local V : value label `source' // the name of the label map in use, if there is one
                                 // Stata maintains a dictionary of dictionaries, each of which
                                 // maps integers to strings. Multiple variables can share a dictionary,
                                 // though it is rare except for e.g. "boolean"
  
  // make new variable
  generate `T' `target' = `source' `_if' `_in'
  
  // clone attributes if they exist
  // (except for type, which always exists and cannot be reassigned without
  //  another 'generate' doing a whole new malloc())
  if("`N'"!="") {
    label variable `target' "`N'"  //Yes, the setters and getters are...
  }
  if("`V'"!="") {
    label value `target' "`V'"     //...in fact reverses of each other
  }
end
