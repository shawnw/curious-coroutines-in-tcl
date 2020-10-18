#!/usr/bin/env tclsh
package require Tcl 8.6
package require generator

# An example of setting up a processing pipeline with generators

# Maybe set up actual packages later, but be lazy for now for code
# reuse.
source follow.tcl

# Adapt a generator into one that only returns elements that match
# pattern
proc grep {pattern linesgenerator} {
    generator filter [list string match $pattern] $linesgenerator
}

# Set up a processing pipeline : tail -f | grep python
set logfile [open access-log]
generator foreach line [grep *python* [follow $logfile]] {
    puts $line
}
