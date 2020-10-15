#!/usr/bin/env tclsh
package require Tcl 8.6
package require coroutine

proc sendto {f} {
    coroutine::util create apply {{f} {
        for {set item [yield [info coroutine]]} {1} {set item [yield]} {
            puts $f $item
            chan flush $f
        }
    }} $f
}

proc recvfrom {f target} {
    while {[gets $f item] >= 0} {
        $target $item
    }
}

if {[info exists ::argv0] &&
    [string equal $::argv0 [info script]]} {
    source buses.tcl

    set writer [open "| tclsh busproc.tcl" w]
    set target [buses_to_dicts [sendto $writer]]
    BusParser parsefile allroutes.xml
    chan close $writer
}
