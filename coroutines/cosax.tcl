#!/usr/bin/env tclsh
package require Tcl 8.6
package require tdom

# An example showing how to push SAX events into a coroutine target

proc strtrans {text} {
    string map {\n \\n \t \\t} $text
}

# Use lambdas instead of standalone procs
xml::parser BusParser \
    -final true \
    -elementstartcommand {apply {{target name attrs} {
        $target [list start $name $attrs]
    }} printer} \
    -elementendcommand {apply {{target name} {
        $target [list end $name]
    }} printer} \
    -characterdatacommand {apply {{target text} {
        $target [list text [strtrans $text]]
    }} printer}

coroutine printer apply {{} {
    while 1 {
        set event [yield]
        puts $event
    }
}}

BusParser parsefile allroutes.xml
