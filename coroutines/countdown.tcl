#!/usr/bin/env tclsh
package require Tcl 8.6
package require generator

# A simple generator function
generator define countdown {n} {
    puts "Counting down from $n"
    while {$n > 0} {
        generator yield $n
        incr n -1
    }
    puts "Done counting down"
}

# Example use
generator foreach i [countdown 10] {
    puts $i
}
