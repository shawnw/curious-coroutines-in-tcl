#!/usr/bin/env tclsh
package require Tcl 8.6
package require generator

# A generator that follows a log file like Unix `tail -f`

# Note: To see this example work, you need to apply to an active
# server log file.  Run the program "logsim.py" in the background to
# simulate such a file.  This program will write entries to a file
# "access-log".

generator define follow {thefile} {
    seek $thefile 0 end
    while 1 {
        set len [gets $thefile line]
        if {$len < 0} {
            after 1000
            continue
        }
        generator yield $line
    }
}

if {[info exists ::argv0]
    && [string equal $::argv0 [info script]]} {
    # Example use
    set logfile [open access-log]
    generator foreach line [follow $logfile] {
        puts $line
    }
}
