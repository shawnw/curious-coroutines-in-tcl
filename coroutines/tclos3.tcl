#!/usr/bin/env tclsh
package require Tcl 8.6
package require TclOO
package require coroutine

# ------------------------------------------------------------
# tclos3.tcl  -  The TCL Operating System
#
# Step 3: Added handling for task termination
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

    method exit {task} {
        set tid [$task gettid]
        puts "Task $tid terminated"
        dict unset taskmap $tid
        $task destroy
    }

    # Add a task to the list of ones queued to run
    method schedule {task} {
        lappend ready $task
    }

    # Run a single ready task in a loop
    method runtask {} {
        if {[llength $ready] > 0} {
            set ready [lassign $ready nexttask]
            try {
                $nexttask run
                my schedule $nexttask
            } trap {TCL LOOKUP COMMAND} {} {
                my exit $nexttask
            }
        }
        if {[dict size $taskmap] > 0} {
            after idle [self object] runtask
        } else {
            # Exit if there are no tasks running
            global done
            set done done
        }
    }

    method mainloop {} {
        global done
        after idle [self object] runtask
        vwait done
    }
}

# ------------------------------------------------------------
#                      === Example ===
# ------------------------------------------------------------

# Two tasks
coroutine foo apply {{} {
    set i 0
    while {[incr i] <= 10} {
        yield
        puts "I'm foo"
    }
}}

coroutine bar apply {{} {
    set i 0
    while {[incr i] <= 5} {
        yield
        puts "I'm bar"
    }
}}

Scheduler create sched
sched add foo
sched add bar
sched mainloop
sched destroy
