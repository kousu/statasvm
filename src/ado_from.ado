/* ado_from: return the URL or path that a package was installed from.
 *  This is to glue over that 'net get' doesn't do this already.
 *
 */
program define ado_from, rclass
  
  // parse arguments
  gettoken pkg 0 : 0
  
  
  local from = ""
  local curpkg = ""
  
  tempname fd
  
  // scan stata.trk for the source
  // this is not a full stata.trk parser, it only implements what I need
  // a typical entry looks like
  // ...
  // e
  // S http://fmwww.bc.edu/repec/bocode/p
  // N psidtools.pkg
  // ...
  // the loop ends when we run off the end of the file or we have found
  // the matching package and its source

  qui findfile stata.trk
  file open `fd' using `r(fn)', read text
  while(!("`curpkg'"=="`pkg'.pkg" & "`from'"!="")) {
  
    file read `fd' line
    if(r(eof) != 0) {
      di as error "`pkg' not found in stata.trk"
      exit 9
    }
    
    // extract line type
    gettoken T line : line
    
    if("`T'"=="S") {
       // source line; record from
       gettoken from : line
    }
    else if("`T'"=="e") {
       // end of package; clear state
       local from = ""
       local curpkg = ""
    }
    else if("`T'"=="N") {
       // package file name
       gettoken curpkg : line
    }
    
  }
  
  // assumption: the stata.trk file should have defined an S line in each pkg block
  // if not, something bad happened
  assert "`from'"!=""
  
  return clear
  return local from = "`from'"

end
