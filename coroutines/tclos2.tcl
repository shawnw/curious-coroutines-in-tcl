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

    destructor {
        if {[llength [info commands $target]]} {
            rename $target ""
        }
    }

    # Run a task until it hits the next yield statement
    method run {} {
        $target $sendval
    }

    method gettid {} {
        return $tid
    }
}

# ------------------------------------------------------------
#                      === Scheduler ===
# ------------------------------------------------------------

# Thin wrapper over the event loop
oo::class create Scheduler {
    variable ready taskmap

    constructor {} {
        set ready [list]
        set taskmap [dict create]
    }

    destructor {
        dict for {tid task} $taskmap {
            $task destroy
        }
    }

    method add {target} { ;# Called new in pyos2.py
        set newtask [Task new $target]
        set tid [$newtask gettid]
        dict set taskmap $tid $newtask
        my schedule $newtask
        return $tid
    }

    # Add a task to the list of ones queued to run
    method schedule {task} {
        lappend ready $task
    }

    # Run a single ready task in a loop
    method runtask {} {
        if {[llength $ready] > 0} {
            set ready [lassign $ready nexttask]
            $nexttask run
            my schedule $nexttask
        }
        if {[dict size $taskmap] > 0} {
            after idle [self object] runtask
        } else {
            global forever
            set forever done
        }
    }

    method mainloop {} {
        global forever
        after idle [self object] runtask
        vwait forever
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
    sched destroy
}
