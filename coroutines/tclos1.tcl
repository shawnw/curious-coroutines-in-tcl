#!/usr/bin/env tclsh
package require Tcl 8.6
package require TclOO

# ------------------------------------------------------------
# tclos1.tcl  -  The TCL Operating System
#
# Step 1: Tasks
# ------------------------------------------------------------

# From https://wiki.tcl-lang.org/page/TclOO+Tricks
oo::class create Static {
    method static {args} {
        if {![llength $args]} return
        set callclass [lindex [self caller] 0]
        oo::objdefine $callclass export varname
        foreach vname $args {
            lappend pairs [$callclass varname $vname] $vname
        }
        uplevel 1 upvar {*}$pairs
    }
}

# This object encapsulates a running task.
oo::class create Task {
    mixin Static
    variable sendval target

    constructor {target_} {
        my static taskid
        incr taskid
        set target $target_
        set sendval ""
    }

    # Run a task until it hits the next yield statement
    method run {} {
        $target $sendval
    }
}

set t1 [Task new [coroutine foo[incr counter] apply {{} {
    yield [info coroutine]
    puts "Part 1"
    yield
    puts "Part 2"
}}]]
puts "Running foo"
$t1 run
puts "Resuming foo"
$t1 run

# If you call `$t1 run` one more time you get an invalid command name
# error.  Uncomment the next statement to see that.

# $t1 run

