#!/usr/bin/env tclsh
package require Tcl 8.6
package require TclOO
package require coroutine

# ------------------------------------------------------------
# tclos7.tcl  -  The TCL Operating System
#
# Step 6 : I/O Waiting Support added
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

# Thin wrapper over the event loop
oo::class create Scheduler {
    variable exit_waiting ready sockets_listening taskmap

    constructor {} {
        set exit_waiting [dict create]
        set sockets_listening 0
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

    method listening {yesno} {
        if {$yesno} {
            incr sockets_listening
        } else {
            incr sockets_listening -1
        }
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

    # I/O waiting

    # Instead of adding file descriptors to lists and periodically
    # using select (Which tcl doesn't have), we instead add the
    # relevant readable or writable event callback to the event loop.

    method ioread {task ch} {
        # Channel's become readable; queue the task
        chan event $ch readable {}
        incr sockets_listening -1
        my schedule $task
    }

    method waitforread {task ch} {
        # Add readable event.
        chan event $ch readable [list [self object] ioread $task $ch]
        incr sockets_listening
    }

    method iowrite {task ch} {
        # Channel's become writeable; queue the task
        chan event $ch writable {}
        incr sockets_listening -1
        my schedule $task
    }

    method waitforwrite {task ch} {
        # Add writable event.
        chan event $ch writable [list [self object] iowrite $task $ch]
        incr sockets_listening
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
        if {[llength $ready] > 0} {
            # Work to be done!
            after idle [self object] runtask
        } elseif {[dict size $taskmap] > 0 || $sockets_listening > 0} {
            # Registered tasks but nothing currently pending. Sleep a bit.
            after 50 [self object] runtask
        } else {
            # No tasks registered, no sockets waiting for events. Exit.
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

# Wait for reading
oo::class create ReadWait {
    superclass SystemCall
    variable sched task ch
    constructor {ch_} {
        set ch $ch_
    }
    method handle {} {
        $sched waitforread $task $ch
    }
}

# Wait for writing
oo::class create WriteWait {
    superclass SystemCall
    variable sched task ch
    constructor {ch_} {
        set ch $ch_
    }
    method handle {} {
        $sched waitforwrite $task $ch
    }
}

# ------------------------------------------------------------
#                      === Example ===
# ------------------------------------------------------------

# Run the script echogood.tcl to see this work
