
program define clockseed
  set seed `= mod(clock("$S_DATE $S_TIME","D M 20Y hms"),2^31)'
end
