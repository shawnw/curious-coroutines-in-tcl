#!/usr/bin/env tclsh
package require Tcl 8.6

# An example that shows how the initial scheduler doesn't handle
# task termination correctly.

source tclos2.tcl

coroutine foo apply {{} {
    set i 0
    while {[incr i] <= 10} {
        yield
        puts "I'm foo"
    }
}}

coroutine bar apply {{} {
    while 1 {
        yield
        puts "I'm bar"
    }
}}

Scheduler create sched
sched add foo
sched add bar
sched mainloop
