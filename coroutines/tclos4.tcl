#!/usr/bin/env tclsh
package require Tcl 8.6
package require TclOO
package require coroutine

# ------------------------------------------------------------
# tclos4.tcl  -  The TCL Operating System
#
# Step 4: Introduce the idea of a "System Call"
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

    method setsendval {sendval_} {
        set sendval $sendval_
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
            set ready [lassign $ready task]
            try {
                set result [$task run]
                if {[info object isa typeof $result SystemCall]} {
                    $result settask $task
                    $result setsched [self object]
                    $result handle
                    $result destroy
                } else {
                    my schedule $task
                }
            } trap {TCL LOOKUP COMMAND} {} {
                my exit $task
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
#                   === System Calls ===
# ------------------------------------------------------------
oo::class create SystemCall {
    variable sched task
    method handle {} {}
    method settask {task_} {
        set task $task_
    }
    method setsched {sched_} {
        set sched $sched_
    }
}

# Return a task's ID number
oo::class create GetTid {
    superclass SystemCall
    variable sched task
    method handle {} {
        $task setsendval [$task gettid]
        $sched schedule $task
    }
}

# ------------------------------------------------------------
#                      === Example ===
# ------------------------------------------------------------

coroutine foo apply {{} {
    yield
    set i 0
    set mytid [yield [GetTid new]]
    while {[incr i] <= 5} {
        puts "I'm foo $mytid"
        yield
    }
}}

coroutine bar apply {{} {
    yield
    set i 0
    set mytid [yield [GetTid new]]
    while {[incr i] <= 10} {
        puts "I'm bar $mytid"
        yield
    }
}}

Scheduler create sched
sched add foo
sched add bar
sched mainloop
sched destroy
