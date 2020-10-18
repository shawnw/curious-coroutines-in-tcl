#!/usr/bin/env tclsh
package require Tcl 8.6
package require coroutine

# An attempt to write an echo server. This one works because
# of the I/O waiting operations that suspend the tasks when there
# is no data available.

source tclos7.tcl

proc handle_client {ch} {
    coroutine::util create apply {{ch} {
        yield [info coroutine]
        while 1 {
            yield [ReadWait new $ch]
            set data [chan read $ch 65536]
            if {[eof $ch]} {
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
socket -server {accept sched} 45000
sched listening true
puts "Server starting"
sched mainloop
sched destroy
