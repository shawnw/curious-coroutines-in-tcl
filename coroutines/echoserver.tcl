#!/usr/bin/env tclsh
package require Tcl 8.6
package require coroutine

source tclos8.tcl

proc handle_client {ch} {
    coroutine::util create apply {{ch} {
        yield [info coroutine]
        while 1 {
            set data [tclos recv $ch 65536]
            if {[eof $ch]} {
                chan close $ch
                return
            }
            puts "Read [string length $data] bytes from $ch"
            tclos send $ch $data
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
