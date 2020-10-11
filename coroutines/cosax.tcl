#!/usr/bin/env tclsh
package require Tcl 8.6
package require tdom

# An example showing how to push SAX events into a coroutine target
proc strtrans {text} {
    string map {\n \\n \t \\t} $text
}

proc elementStart {name attrs} {
    printer [list start $name $attrs]
}

proc elementEnd {name} {
    printer [list end $name]
}

proc characters {text} {
    printer [list text [strtrans $text]]
}

xml::parser BusParser \
    -final 1 \
    -elementstartcommand elementStart \
    -elementendcommand elementEnd \
    -characterdatacommand characters

coroutine printer apply {{} {
    while 1 {
        set event [yield]
        puts $event
    }
}}

BusParser parsefile allroutes.xml
