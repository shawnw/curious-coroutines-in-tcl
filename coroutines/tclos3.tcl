#!/usr/bin/env tclsh
package require Tcl 8.6
package require TclOO

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
    
    constructor {target_} {
        my variable target sendval tid
        my static taskid
        set tid [incr taskid]
        set target $target_
        set sendval ""
    }
    
    # Run a task until it hits the next yield statement
    method run {} {
        my variable target sendval
        $target $sendval
    }
    
    method gettid {} {
        my variable tid
        return $tid
    }
}

# ------------------------------------------------------------
#                      === Scheduler ===
# ------------------------------------------------------------
oo::class create Scheduler {
    constructor {} {
        my variable ready taskmap
        set ready [list]
        set taskmap [dict create]
    }
    
    method add {target} { ;# Called new in pyos3.py
        my variable taskmap
        set newtask [Task new $target]
        set tid [$newtask gettid]
        dict set taskmap $tid $newtask
        my schedule $newtask
        return $tid
    }

    method exit {task} {
        my variable taskmap
        set tid [$task gettid]
        puts "Task $tid terminated"
        dict unset taskmap $tid
        $task destroy
    }
    
    method schedule {task} {
        my variable ready
        lappend ready $task
    }
    
    method mainloop {} {
        my variable ready taskmap
        while {[dict size $taskmap] > 0} {
            set ready [lassign $ready task]
            try {
                set result [$task run]
                my schedule $task
            } trap {TCL LOOKUP COMMAND} {} {
                my exit $task
            }
        }
    }
}

# ------------------------------------------------------------
#                      === Example ===
# ------------------------------------------------------------

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


