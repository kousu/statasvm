
/* ensurelib_aberrance: a variant of ensurelib which handles libraries whose names on Windows follow the "aberrant" "lib<name>.dll" format,
   usually because its authors were unix junkies who didn't put much effort into the Windows port */
program define ensurelib_aberrance
  version 13
  gettoken lib 0 : 0
  syntax /* deny further args */
  
  if("`c(os)'"=="Windows") {
    capture ensurelib "lib`lib'"
    if(_rc==0) {
      // success!
      exit
    }
  }
  
  capture ensurelib `lib'
end
