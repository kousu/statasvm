/* export_svmlight: export the Stata dataset to a .svmlight format file. See _svmlight.c */

program _svmlight, plugin /*load the C extension if not already loaded*/

program define export_svmlight
  version 13
  syntax varlist(numeric) [if] [in] using/

   quietly {

    capture plugin call _svmlight `varlist' `if' `in', "export" "`using'"
    
  }
end

