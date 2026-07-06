pactl list sources | awk '
/^Source / { check(); is_monitor=0; is_running=0 }
/Name: .*\.monitor/ { is_monitor=1 }
/State: RUNNING/ { is_running=1 }
END { check() }
function check() { if (is_running && !is_monitor) { print 1; exit } }
'
