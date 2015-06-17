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
  capture noisily do `example'_example.do
  
  qui snapshot restore `snapshot'
  //restore // this is unneeded, because this runs automatically at scope end
  
end
