#!/usr/bin/env tclsh
package require Tcl 8.6
package require coroutine

# An echo server using coroutines and the event loop.

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

# Like `coroutine::util read`, but only returns what's available
# instead of waiting for all the requested bytes.
proc ::coroutine::util::recv {ch maxlen} {
    set blocking [::chan configure $ch -blocking]
    try {
        ::chan configure $ch -blocking 0
        if {[::chan pending input $ch] > 0} {
            return [::chan read $ch $maxlen]
        }
        ::chan event $ch readable [info coroutine]
        yield
        ::chan read $ch $maxlen
    } on error {msg opts} {
        return -options $opts $msg
    } finally {
        ::chan event $ch readable {}
        ::chan configure $ch -blocking $blocking
    }
}

set cmds [namespace eval ::coroutine::util {namespace export}]
lappend cmds puts recv
namespace ensemble configure ::coroutine::util -subcommands $cmds

proc handle_client {ch} {
    coroutine::util create apply {{ch} {
        yield [info coroutine]
        try {
            while 1 {
                set data [coroutine::util recv $ch 65536]
                if {[eof $ch]} {
                    puts "Connection $ch closed"
                    return
                }
                coroutine::util puts -nonewline $ch $data
                after idle [info coroutine]
                yield
            }
        } on error {msg} {
            puts "error on socket $ch: $msg"
        } finally {
            chan close $ch
        }
    }} $ch
}

proc accept {ch addr port} {
    puts "Connection from $addr"
    chan configure $ch -buffering none -blocking 0
    after idle [handle_client $ch]
}

socket -server accept 45000
puts "Starting server"
vwait forever
