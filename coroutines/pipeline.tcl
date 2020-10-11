#!/usr/bin/env tclsh
package require Tcl 8.6
package require generator

# An example of setting up a processing pipeline with generators

# Maybe set up actual packages later, but be lazy for now for code
# reuse.
source follow.tcl

generator define grep {pattern linesgenerator} {
    generator finally generator destroy $linesgenerator
    generator foreach line $linesgenerator {
        if {[string match $pattern $line]} {
            generator yield $line
        }
    }
}

# Set up a processing pipeline : tail -f | grep python
set logfile [open access-log]
generator foreach line [grep *python* [follow $logfile]] {
    puts $line
}
