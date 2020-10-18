#!/usr/bin/env tclsh
package require Tcl 8.6
package require coroutine

# An attempt to write an echo server. This one works because
# of the I/O waiting operations that suspend the tasks when there
# is no data available.

source tclos7.tcl

coroutine alive apply {{} {
    while 1 {
        yield
        incr counter
        if {$counter % 10000 == 0} {
            puts "I'm alive!"
        }
    }
}}

proc handle_client {ch} {
    coroutine::util create apply {{ch} {
        yield [info coroutine]
        while 1 {
            yield [ReadWait new $ch]
            set data [chan read $ch 65536]
            if {[eof $ch]} {
                puts "Got EOF on $ch"
                chan close $ch
                return
            }
            yield [WriteWait new $ch]
            chan puts -nonewline $ch $data
        }
    }} $ch
}

proc accept {sched ch addr port} {
    puts "Connection from $addr"
    chan configure $ch -blocking 0 -buffering none
    $sched add [handle_client $ch]
}

Scheduler create sched
sched add alive
socket -server {accept sched} 45000
puts "Server starting"
sched mainloop
sched destroy
