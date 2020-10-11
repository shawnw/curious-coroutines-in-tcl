#!/usr/bin/env tclsh
package require Tcl 8.6
package require TclOO
package require coroutine

# ------------------------------------------------------------
# tclos5.tcl  -  The TCL Operating System
#
# Step 5: Added system calls for simple task management
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
oo::class create Scheduler {
    variable ready taskmap
    constructor {} {
        set ready [list]
        set taskmap [dict create]
    }
    
    method add {target} { ;# Called new in pyos5.py
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
        $task destroy
    }
    
    method schedule {task} {
        lappend ready $task
    }
    
    method mainloop {} {
        while {[dict size $taskmap] > 0} {
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

# ------------------------------------------------------------
#                      === Example ===
# ------------------------------------------------------------

proc foo {} {
    coroutine::util create apply {{} {
        yield [info coroutine]
        set mytid [yield [GetTid new]]
        while 1 {
            puts "I'm foo $mytid"
            yield
        }
    }}
}

coroutine main apply {{} {
    yield
    set child [yield [NewTask new [foo]]]
    for {set i 1} {$i <= 5} {incr i} {
        yield
    }
    yield [KillTask new $child]
    puts "main done"
}}

Scheduler create sched
sched add main
sched mainloop


