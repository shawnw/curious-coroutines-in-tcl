#!/usr/bin/env tclsh
package require Tcl 8.6

# A very simple coroutine

proc grep {pattern} {
    while {1} {
        set line [yield]
        if {[string match $pattern $line]} {
            puts $line
        }
    }
}

# Note: tcl coroutines start running right away; python ones don't
# until the first time `.next()` is called, meaning the coroutine
# decorator used in the later python programs isn't needed.
coroutine g grep *tcl*
g "Yeah, but no, but yeah, but no"
g "A series of tubes"
g "tcl generators rock!"

