// usage: stata do stata_wrap.do $SCRIPT $LOG $RC
//
// Wraps $SCRIPT so that its output goes to $LOG and error code to $RC,
// and it ensures Stata comes down at the end even if there was an error.
// - it's an imperfect wrapper: $LOG ends up with header and footer cruft from 'log'

args script log rc_log
//di as err "script = `script', log = `log', rc = `rc_log'"
log using "`log'", text replace
capture noisily do "`script'"
log close
//di as err "rc = `=_rc'"
tempname fd
file open `fd' using "`rc_log'", write text replace
file write `fd' "`=_rc'" _n
file close `fd'
// force-quit Stata
exit, clear STATA
