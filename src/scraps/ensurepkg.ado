/* ensurepkg: automagically install needed packages.
 *
 * syntax:
 * ensureado cmd, [pkg(package_name) from(url)]
 *
 * cmd:  to detect if the package is installed, look for either of "`cmd" and "`cmd'.ado" in the adopath.
 * pkg:  specify pkg explicitly if the command and package do not have the same name.
 * from: if needed, install pkg from this URL; if not given, attemps first StataCorp and then the ssc.
 *       if the package exists, *this is ignored*.
 * 
 * This is a rolling-release system: `pkg' will always be updated to the most recent version if it can.
 *   If the package does not declare a Distribution-Date it will never update.
 *   If the network is down, the old version will be used silently.
 *   These may or may not cause confusion and bugs for your users.
 *
 * 
 * ensurepkg is meant to glue over the lack of dependency tracking in Stata's .pkg format.
 * At the top of every piece of code which has dependencies, declare like them this:
 *
 * // example.ado
 * ensurepkg norm                                     // Ansari & Mussida normalization subroutine
 * ensurepkg psid, pkg(psidtools)                     // Kohler's panel income data API
 * ensurepkg boost, from("http://schonlau.net/stata") // Schonlau's machine learning boosting library
 * ensurepkg _getenv.plugin, pkg(env)                 // Guenther's environment accessors
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
program define ensurepkg
  // parse arguments
  syntax name, [pkg(string) from(string) noupdate]
  local ado = "`namelist'"
  
  if("`pkg'"=="") {
    local pkg = "`ado'"
  }
  
  // test if `ado' is installed
  // it would be nice if we could use instead 'ado dir'
  // but 'ado dir' doesn't offer a programmatic interface.
  // Maybe there's something in Mata...
  capture which `ado'
  if(_rc!=0) {
    // it's not, so install it
    if("`from'"!="") {
      net install `pkg', from(`from')
    }
    else {
      capture noisily net install `pkg'
      if(_rc!=0) {
        ssc install `pkg'
      }
    }
    
    // recurse, to double-check the installation worked
    // DoS WARNING: this will cause an infinite loop
    //              if the remote package exists but
    //              does not include the named command.
    //   (but Stata has bigger security problems in its package system than a DoS)
    quietly ensurepkg `ado'
  }
  else {
    // if already installed
    if("`update'"=="noupdate") {
      exit
    }
    
    // make sure package is at the latest version.
    capture adoupdate `pkg', update
    if(_rc==631 | _rc==677) {
      // special case: if the network is down, *succeed*
      // 631 - DNS failed
      // 677 - TCP failed
      exit
    }
    else {
      exit _rc
    }
  }
end
