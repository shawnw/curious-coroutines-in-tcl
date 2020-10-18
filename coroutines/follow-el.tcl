#!/usr/bin/env tclsh
package require Tcl 8.6
package require coroutine

# Version of follow.tcl/cofollow.tcl that uses coroutines with the
# event loop.

proc follow {thefile} {
    seek $thefile 0 end
    coroutine::util create apply {{thefile} {
        yield [info coroutine]
        while 1 {
            set len [coroutine::util gets $thefile line]
            if {$len == -1} {
                # No new data; wait a bit and try again
                coroutine::util after 1000
                continue
            }
            puts $line
        }
    }} $thefile
}

set logfile [open access-log]
after idle [follow $logfile]
vwait forever
