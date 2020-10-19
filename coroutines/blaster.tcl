#!/usr/bin/env tclsh
package require Tcl 8.6
package require generator
package require coroutine

# Open up a large number of socket connections with a server and then
# just start blasting it with messages.

# Differences from blaster.py:
#
# Uses the tcl event loop to send a grand total of $MAXCOUNT messages
# to connections based on their ablity to write without blocking,
# instead of picking them at random from a list.
#
# Reads replies cosynchronously using coroutines and the event loop.
#
# A lot more output about what it's doing. You probably want to
# redirect output to /dev/null

set NCONNECTIONS 30 ;# Number of connections to make
set MSGSIZE 1024 ;# Message size
set SERVER {localhost 45000} ;# Server address
set MSG [string repeat x $MSGSIZE] ;# The message
set MAXCOUNT 1000 ;# The number of messages to send

generator define range {n m} {
    for {set i $n} {$i <= $m} {incr i} { generator yield $i }
}

# TODO: Contribute these to the upstream coroutine package
# Coroutine aware puts that yields until the channel is writable
proc ::coroutine::util::puts {args} {
    switch [llength $args] {
        1 {
            set ch stdout
        }
        2 {
            set ch [lindex $args 0]
            if {[string match {-*} $ch]} {
                if {$ch ne "-nonewline"} {
                    # Force proper error message for bad call
                    tailcall ::chan puts {*}$args
                }
                set ch stdout
            }
        }
        3 {
            lassign $args opt ch
            if {$opt ne "-nonewline"} {
                # Force proper error message for bad call
                tailcall ::chan puts {*}$args
            }
        }
        default {
            # Force proper error message for bad call
            tailcall ::chan puts {*}$args
        }
    }
    set blocking [::chan configure $ch -blocking]
    try {
        ::chan configure $ch -blocking 0
        ::chan event $ch writable [info coroutine]
        yield
        ::chan puts {*}$args
    } on error {msg opts} {
        return -options $opts $msg
    } finally {
        ::chan event $ch writable {}
        ::chan configure $ch -blocking $blocking
    }
}

# Coroutine aware client socket connection
# Does a non-blocking connect in the background and yields until finished.
proc ::coroutine::util::connect {args} {
    if {[lsearch -exact $args -server] >= 0} {
        error "[namespace current] connect cannot be used for server sockets."
    }
    set s [::socket -async {*}$args]
    ::chan event $s writable [info coroutine]
    while {[::chan configure $s -connecting]} {
        yield
    }
    ::chan event $s writable {}
    set errmsg [::chan configure $s -error]
    if {$errmsg ne ""} {
        ::chan close $s
        error $errmsg
    }
    return $s
}

set cmds [namespace eval ::coroutine::util {namespace export}]
lappend cmds puts connect
namespace ensemble configure ::coroutine::util -subcommands $cmds

proc shutdown {s} {
    global connections
    global forever
    puts "Shutting down connection [dict get $connections $s]"
    chan close $s
    dict unset connections $s
    if {[dict size $connections] == 0} {
        set forever done
    }
}

proc blast_messages {host port} {
    coroutine::util create apply {{host port} {
        global MSG
        global MSGSIZE
        global MAXCOUNT
        global count
        global connections
        yield [info coroutine]
        set s [coroutine::util connect $host $port]
        chan configure $s -buffering none
        dict set connections $s [info coroutine]
        puts "Connection [info coroutine] opened socket $s"
        while {[incr count] <= $MAXCOUNT} {
            puts "Sending message $count to socket $s"
            try {
                coroutine::util puts -nonewline $s $MSG
                set response [coroutine::util read $s $MSGSIZE]
                puts "Got reply of [string length $response] back from socket $s"
            } on error {msg opts} {
                puts stderr "error on socket $s: $msg"
                break
            }
        }
        shutdown $s
    }} $host $port
}

# Open up connections
generator foreach i [range 1 $NCONNECTIONS] {
    after idle [blast_messages {*}$SERVER]
}

# And run till done.
vwait forever
