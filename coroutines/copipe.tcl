#!/usr/bin/env tclsh
package require Tcl 8.6
package require coroutine

# A simple example showing how to hook up a pipeline with coroutines.
# To run this, you will need a log file. Run the program logsim.py in
# the background to get a data source.

# A data source. This is not a coroutine, but it sends data into one
# (target)

proc follow {thefile target} {
    seek $thefile 0 end
    while 1 {
        set len [gets $thefile line]
        if {$len < 0} {
            after 100
            continue
        }
        $target $line
    }
}

# A filter

# proc that returns a new coroutine name instead of using a hardcoded name
proc grep {pattern target} {
    variable counter
    coroutine grep[incr counter] apply {{pattern target} {
        # The first yield returns the name of the coroutine, which is
        # then returned by the enclosing `grep` proc.
        for {set line [yield [info coroutine]]} {1} {set line [yield]} {
            if {[string match $pattern $line]} {
                $target $line
            }
        }
    }} $pattern $target
}

# A sink.  A coroutine that receives data.

# Compare to the `printer` coroutine in cofollow.tcl
# This time, use `coroutine::util create` to generate a name
proc printer {} {
    coroutine::util create apply {{} {
        for {set line [yield [info coroutine]]} {1} {set line [yield]} {
            puts $line
        }
    }}
}

set f [open access-log]
follow $f [grep *python* [printer]]
