#!/usr/bin/env tclsh
package require Tcl 8.6

# A simple example showing how to hook up a pipeline with
# coroutines. To run this, you will need a log file.  Run the program
# logsim.py in the background to get a data source.

# A data source.  This is not a coroutine, but it sends data into one
# (target)

proc follow {thefile target} {
    seek $thefile 0 end
    while 1 {
        if {[gets $thefile line] >= 0} {
            $target $line
        } elseif {[eof $thefile]} {
            after 100
            continue
        } else {
            error "gets returned an error"
        }
    }
}

# A sink. A coroutine that receives data

# Use a lambda expression instead of an existing proc for the
# coroutine
coroutine printer apply {{} {
    while 1 {
        set line [yield]
        puts $line
    }
}}

set f [open access-log]
follow $f printer
