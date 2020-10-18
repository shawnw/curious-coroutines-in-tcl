#!/usr/bin/env tclsh
package require Tcl 8.6
package require coroutine

# An example of broadcasting a data stream onto multiple coroutine
# targets.

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
proc grep {pattern target} {
    coroutine::util create apply {{pattern target} {
        for {set line [yield [info coroutine]]} {1} {set line [yield]} {
            if {[string match $pattern $line]} {
                $target $line
            }
        }
    }} $pattern $target
}

# A sink.  A coroutine that receives data.
proc printer {} {
    coroutine::util create apply {{} {
        for {set line [yield [info coroutine]]} {1} {set line [yield]} {
            puts $line
        }
    }}
}

# Broasdcast a stream onto multiple targets
proc broadcast {targets} {
    coroutine::util create apply {{targets} {
        for {set item [yield [info coroutine]]} {1} {set item [yield]} {
            foreach target $targets {
                $target $item
            }
        }
    }} $targets
}

set f [open access-log]
# Three different instances of grep coroutines, one single printer
set p [printer]
follow $f [broadcast [list \
                          [grep *python* $p] \
                          [grep *ply* $p] \
                          [grep *swig* $p]]]
