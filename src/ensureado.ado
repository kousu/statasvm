/* ensureado: automagically install missing commands.
 * 
 * This is meant to glue over the lack of dependency tracking in Stata's .pkg format.
 *
 * syntax:
 * ensureado cmd, [pkg(package_name) from(url)]
 *
 * cmd: Stata will look for "cmd.ado" in its adopath.
 * pkg: if not given, the command and package are assumed to have the same name.
 * from: if given, install from that URL; otherwise install from the ssc.
 *
 * At the top of every piece of Stata code which has non-stdlib dependencies,
 *  declare them like this:
 *
 * // example.ado
 * ensureado norm                                     // Ansari & Mussida normalization library
 * ensureado psid, pkg(psidtools)                     // Kohler's panel income data API
 * ensureado boost, from("http://schonlau.net/stata") // Schonlau's machine learning boosting library
 * program define example {
 *   ...
 *   norm x
 *   boost x y z
 *   ...
 * }
 *
 * Nick Guenther <nguenthe@uwaterloo.ca> 2015
 * BSD License
 */
program define ensureado
  // parse arguments
  syntax name, [pkg(string) from(string)]
  local ado = "`namelist'"
  
  if("`pkg'"=="") {
    local pkg = "`ado'"
  }
  
  // test if `ado' is installed
  capture which `ado'
  if(_rc!=0) {
    // it's not, so install it
    if("`from'"!="") {
      net install `pkg', from(`from')
    }
    else {
      ssc install `pkg'
    }
    
    // recurse, to double-check the installation worked
    // DoS WARNING: this will cause an infinite loop
    //              if the remote package exists but
    //              does not include the named command.
    //   (but Stata has bigger security problems in its package system than a DoS)
    ensureado `ado'
  }
end
