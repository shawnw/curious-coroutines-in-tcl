#!/usr/bin/env tclsh
package require Tcl 8.6
package require TclOO
package require coroutine

# ------------------------------------------------------------
# tclos6.tcl  -  The TCL Operating System
#
# Added support for task waiting
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

    method gettarget {} {
        return $target
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
    variable exit_waiting ready taskmap

    constructor {} {
        set exit_waiting [dict create]
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

    method gettask {tid} {
        if {[dict exists $taskmap $tid]} {
            return [dict get $taskmap $tid]
        } else {
            return ""
        }
    }

    method exit {task} {
        set tid [$task gettid]
        puts "Task $tid terminated"
        dict unset taskmap $tid
        if {[dict exists $exit_waiting $tid]} {
            foreach watcher [dict get $exit_waiting $tid] {
                my schedule $watcher
            }
            dict unset exit_waiting $tid
        }
        $task destroy
    }

    method waitforexit {task waittid} {
        if {[dict exists $taskmap $waittid]} {
            dict lappend exit_waiting $waittid $task
            return true
        } else {
            return false
        }
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

# Create a new task
oo::class create NewTask {
    superclass SystemCall
    variable sched target task

    constructor {target_} {
        set target $target_
    }

    method handle {} {
        set tid [$sched add $target]
        $task setsendval $tid
        $sched schedule $task
    }
}

# Kill a task
oo::class create KillTask {
    superclass SystemCall
    variable sched task tid

    constructor {tid_} {
        set tid $tid_
    }

    method handle {} {
        set ktask [$sched gettask $tid]
        if {$ktask ne ""} {
            ::rename [$ktask gettarget] ""
            $task setsendval true
        } else {
            $task setsendval false
        }

        $sched schedule $task
    }
}

# Wait for a task to exit
oo::class create WaitTask {
    superclass SystemCall
    variable sched task tid

    constructor {tid_} {
        set tid $tid_
    }

    method handle {} {
        set result [$sched waitforexit $task $tid]
        $task setsendval $result
        if {!$result} {
            $sched schedule $task
        }
    }
}

# ------------------------------------------------------------
#                      === Example ===
# ------------------------------------------------------------

proc foo {} {
    coroutine::util create apply {{} {
        yield [info coroutine]
        for {set i 1} {$i <= 5} {incr i} {
            puts "I'm foo"
            yield
        }
    }}
}

coroutine main apply {{} {
    yield
    set childtask [NewTask new [foo]]
    set child [yield $childtask]
    puts "Waiting for child $child"
    yield [WaitTask new $child]
    puts "Child done"
}}

Scheduler create sched
sched add main
sched mainloop
sched destroy
