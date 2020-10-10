#!/usr/bin/env tclsh
package require Tcl 8.6

proc countdown {n} {
    yield
    puts "Counting down from $n"
    while {$n >= 0} {
        set newvalue [yield $n]
        # If a new value got send in, reset n with it
        if {$newvalue ne "" && [string is integer $newvalue]} {
            set n $newvalue
        } else {
            incr n -1
        }
    }
}

coroutine c countdown 5
try {
    while 1 {
        set x [c]
        puts $x
        if {$x == 5} {
            c 3
        }
    }
} trap {TCL LOOKUP COMMAND c} {} {}
