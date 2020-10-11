#!/usr/bin/env tclsh
package require Tcl 8.6
package require TclOO

# ------------------------------------------------------------
# tclos2.tcl  -  The TCL Operating System
#
# Step 2: A Scheduler
# ------------------------------------------------------------


# ------------------------------------------------------------
#                       === Tasks ===
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
    variable sendval target tid
    
    constructor {target_} {
        my static taskid
        set tid [incr taskid]
        set target $target_
        set sendval ""
    }
    
    # Run a task until it hits the next yield statement
    method run {} {
        $target $sendval
    }
    
    method gettid {} {
        return $tid
    }
}

oo::class create Scheduler {
    variable ready taskmap

    constructor {} {
        set ready [list]
        set taskmap [dict create]
    }
    
    method add {target} { ;# Called new in pyos2.py
        set newtask [Task new $target]
        set tid [$newtask gettid]
        dict set taskmap $tid $newtask
        my schedule $newtask
        return $tid
    }
    
    method schedule {task} {
        lappend ready $task
    }
    
    method mainloop {} {
        while {[dict size $taskmap] > 0} {
            set ready [lassign $ready task]
            set result [$task run]
            my schedule $task
        }
    }
}

# ------------------------------------------------------------
#                      === Example ===
# ------------------------------------------------------------

if {[info exists ::argv0]
    && [string equal $::argv0 [info script]]} {
    # Two tasks
    coroutine foo apply {{} {
        while 1 {
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
}

