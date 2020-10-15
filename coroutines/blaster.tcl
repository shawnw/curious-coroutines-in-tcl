#!/usr/bin/env tclsh
package require generator

# Open up a large number of socket connections with a server and then
# just start blasting it with messages.

# Differences from blaster.py:
#
# Uses the tcl event loop to send a grand total of $MAXCOUNT messages
# to connections based on their ablity to write without blocking,
# instead of picking them at random from a list.
#
# Reads replies asynchronously.
#
# A lot more output about what it's doing. You probably want to
# redirect output to /dev/null

set NCONNECTIONS 300 ;# Number of connections to make
set MSGSIZE 1024 ;# Message size
set SERVER {localhost 45000} ;# Server address
set MSG [string repeat x $MSGSIZE] ;# The message
set MAXCOUNT 1000000 ;# The number of messages to send

generator define range {n m} {
    for {set i $n} {$i <= $m} {incr i} { generator yield $i }
}

proc shutdown {s} {
    global connections
    global forever
    puts "Shutting down socket $s"
    # Read and discard any pending data
    try {
        set r [chan read $s 65536]
    } trap error {} {}
    chan close $s
    dict unset connections $s
    if {[dict size $connections] == 0} {
        set forever done
    }
}

proc send_message {s} {
    global MSG
    global MAXCOUNT
    global count
    global forever
    incr count
    puts "Sending message $count to socket $s"
    try {
        chan puts $s $MSG
    } trap error {msg} {
        puts stderr "Socket $s error on writing: $msg"
        shutdown $s
    } finally {
        if {$count == $MAXCOUNT} {
            set forever done
        }
    }
}

proc read_replies {s} {
    try {
        set r [chan read $s 65536]
        set len [string length $r]
        puts "Reading $len bytes from socket $s"
        if {$len == 0} {
            shutdown $s
        }
    } trap error {msg} {
        puts stderr "Socket $s error on reading: $msg"
        shutdown $s
    }
}

# Open up connections
generator foreach i [range 1 $NCONNECTIONS] {
    set s [socket {*}$SERVER]
    dict incr connections $s
    # Install handlers
    chan configure $s -blocking 0
    chan event $s writable [list send_message $s]
    chan event $s readable [list read_replies $s]
}

# And run till done.
vwait forever
# Clean up any remaining open sockets
dict for {s _} $connections {
    shutdown $s
}