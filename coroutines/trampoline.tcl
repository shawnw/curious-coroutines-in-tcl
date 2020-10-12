#!/usr/bin/env tclsh
package require Tcl 8.6
package require coroutine

# A simple example of trampolining between coroutines

# A subroutine
proc add {x y} {
    coroutine::util create apply {{x y} {
        yield [info coroutine]
        expr {$x + $y}
    }} $x $y
}

# A function that calls a subroutine
proc main {} {
    yield [info coroutine]
    set r [yieldto add 2 2]
    puts $r
}

proc run {} {
    set m [coroutine::util create main]
    set sub [$m]
    set result [$sub]
    $m $result
}
run
