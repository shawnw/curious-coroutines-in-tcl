#!/usr/bin/env tclsh
package require Tcl 8.6
package require TclOO

# An object
oo::class create GrepHandler {
    variable pattern target
    constructor {pattern_ target_} {
        set pattern $pattern_
        set target $target_
    }
    method send {line} {
        if {[string match $pattern $line]} {
            $target $line
        }
    }
}

# A coroutine
coroutine grep apply {{pattern target} {
    while 1 {
        set line [yield]
        if {[string match $pattern $line]} {
            $target $line
        }
    }
}} *tcl* null

# A null-sink to send data
coroutine null apply {{} {
    while 1 {
        set item [yield]
    }
}}

# A benchmark
set line "tcl is nice"
set p1 grep
set p2 [GrepHandler new *tcl* null]
puts "Coroutine: [time { $p1 $line } 1000000]"
puts "Object: [time { $p2 send $line } 1000000]"
