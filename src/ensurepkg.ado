/* ensurepkg: automagically install needed packages.
 *
 * syntax:
 * ensureado cmd, [pkg(package_name) from(url)]
 *
 * cmd:  Stata will look for "cmd.ado" in its adopath to detect if pkg is installed.
 * pkg:  specify pkg explicitly if the command and package do not have the same name.
 * from: if needed, install pkg from this URL; if not given, installs come from the ssc.
 *       if the package exists, *this is ignored*.
 * 
 * This is a rolling-release system: `pkg' will always be updated to the most recent version.
 * (One gotcha: if the package does not declare a Distribution-Date
 *     *and* the user already has the package installed, the package
 *     will *not* update even if it has been changed)
 *
 * 
 * ensurepkg is meant to glue over the lack of dependency tracking in Stata's .pkg format.
 * At the top of every piece of code which has dependencies, declare like them this:
 *
 * // example.ado
 * ensurepkg norm                                     // Ansari & Mussida normalization subroutine
 * ensurepkg psid, pkg(psidtools)                     // Kohler's panel income data API
 * ensurepkg boost, from("http://schonlau.net/stata") // Schonlau's machine learning boosting library
 * program define example {
 *   ...
 *   norm x
 *   boost x y z
 *   ...
 * }
 * 
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
  // it would be nice if we could use 'ado dir' to find out if 'pkg' is installed,
  // but 'ado dir' doesn't seem to offer a programming interface, just stdout (which I can't even grep)
  // Maybe there's something in Mata...
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
    quietly ensureado `ado'
  }
  else {
    // if already installed
    // make sure package is at the latest version
    // This only works with packages that have properly
    // declared "d Distribution-date: "
    // This is qui'd because
    qui adoupdate `pkg', update
    // special case: if the network is down, adoupdate *succeeds* and assumes 
    return list
  }
end
