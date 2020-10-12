#!/usr/bin/env tclsh
package require Tcl 8.6
package require coroutine
package require Tclx

proc sendto {f} {
    coroutine::util create apply {{f} {
        try {
            for {set item [yield [info coroutine]]} {1} {set item [yield]} {
                puts $f $item
                chan flush $f
            }
        } trap {TCL LOOKUP COMMAND} {} {}
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

    lassign [chan pipe] tosub_reader tosub_writer
    set pid [exec tclsh busproc.tcl <@ $tosub_reader &]
    chan close $tosub_reader
    set target [buses_to_dicts [sendto $tosub_writer]]
    BusParser parsefile allroutes.xml
    chan close $tosub_writer
    wait $pid
}
