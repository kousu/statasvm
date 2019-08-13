/* svmacines_example: download and run the requested sample code from the svmachines package */
/*                                                                                           */
/*                    To use this with a different package, just replace every "svmachines". */

program define svmachines_example
  version 13
  example svmachines `0'
end

/* example: runs example in safe isolation, downloading them from your package as needed
 *
 * Nick Guenther <nguenthe@uwaterloo.ca>, June 2015.
 * BSD License.
 * 
 * Your examples must be in .do files named `example'_example.do
 * and should be listed in your package's ancillary files (with "f").
 *  
 * For example, if you have invented "triple dog dare"
 * regression in a package "tddr", you might make a
 *   triple_dog_dare_regression_79_example.do.
 * In your tddr.pkg file list
 *   f triple_dog_dare_regression_79_example.do
 * which will cause it to be an ancillary file and not get installed with the rest of the package.
 * In your .sthlp file, after a manually-made copy of the code, put
 *   {it:({stata "example tddr triple_dog_dare_regression_79":click to run})}
 * (you can use 'example' anywhere you like, of course, but it's most obvious use is
 *  in glue for helpfiles, which can only run one command at a time).
 *
 * When the user clicks that link, it will download to their working directory, run
 * and then clean up after itself as if it never did, except that the file will be handy
 * for the user to inspect and play with.
 * 
 * TODO:
 * [ ] consider making the convention `pkg'_`example'_example.do
 */
program define example
  version 13
  // parse arguments
  gettoken pkg 0 : 0
  gettoken example 0 : 0
  
  capture findfile `example'_example.do
  if(_rc != 0) {
    // download ancillaries, which should include the examples
    di as txt "Downloading `pkg' ancillary files"
    ado_from `pkg'
    capture noisily net get `pkg', from(`r(from)')
    capture findfile `example'_example.do
    if(_rc != 0) {
      di as error "Unable to find `example' example."
      exit 3
    }
  }

  
  // save the user's dataset
  // if the user actually wants to run the example into their current session they can just "do" it a second time
  qui snapshot save  // this is faster(?) than preserve, and seems to be just as effective, although it requires manual restoration at the end
  local snapshot = `r(snapshot)'
  //preserve
  qui clear
  
  // run example
  capture noisily do `example'_example.do, nostop
  
  qui snapshot restore `snapshot'
  //restore // this is unneeded, because this runs automatically at scope end
  
end

/* ado_from: return the URL or path that a package was installed from.
 *  This is to glue over that 'net get' doesn't do this already.
 *
 */
program define ado_from, rclass
  version 13
  
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
  file open `fd' using "`r(fn)'", read text
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
