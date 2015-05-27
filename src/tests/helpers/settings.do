quietly {
* settings.do
set linesize 119
* make all platforms consistent in their batch output;
* NOTE: this is autoincluded to all tests via makefile magic
* tip buried in http://web.stanford.edu/group/ssds/cgi-bin/drupal/files/Guides/Stata_Unix__2011.pdf
* ALSO these comments are *after* the set, because it affects how stata prints out comments.

local TRACE : env TRACE /* you can't use env by itself, for some reason */
if("`TRACE'"!="") {
  set trace on
  set more off, perm
}

}
