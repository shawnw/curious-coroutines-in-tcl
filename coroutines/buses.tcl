#!/usr/bin/env tclsh
package require Tcl 8.6
package require tdom
package require coroutine

proc buses_to_dicts {target} {
    coroutine::util create apply {{target} {
        for {lassign [yield [info coroutine]] event value} \
            {1} \
            {lassign [yield] event value} {
                if {$event eq "start" && $value eq "bus"} {
                    set busdict [dict create]
                    set fragments [list]
                    set done false
                    while {!$done} {
                        lassign [yield] event value
                        if {$event eq "start"} {
                            set fragments [list]
                        } elseif {$event eq "text"} {
                            lappend fragments $value
                        } elseif {$event eq "end"} {
                            if {$value ne "bus"} {
                                dict set busdict $value [join $fragments]
                            } else {
                                $target $busdict
                                set done true
                            }
                        }
                    }
                }
            }
    }} $target
}

proc filter_on_field {fieldname value target} {
    coroutine::util create apply {{fieldname value target} {
        for {set d [yield [info coroutine]]} {1} {set d [yield]} {
            if {[dict get $d $fieldname] eq $value} {
                $target $d
            }
        }
    }} $fieldname $value $target
}

coroutine bus_locations apply {{} {
    while 1 {
        set bus [yield]
        dict with bus {
            puts "$route,$id,\"$direction\",$latitude,$longitude"
        }
    }
}}

# Using procs is much faster than using lambdas, so we'll stick with them.
proc startElement {name attrs} {
    variable target
    $target [list start $name]
}
proc endElement {name} {
    variable target
    $target [list end $name]
}
proc characters {text} {
    variable target
    $target [list text [string map {\n \\n \t \\t} $text]]
}

xml::parser BusParser \
    -final 1 \
    -elementstartcommand startElement \
    -elementendcommand endElement \
    -characterdatacommand characters

if {[info exists ::argv0] &&
    [string equal $::argv0 [info script]]} {
    set target [buses_to_dicts \
                    [filter_on_field route 22 \
                         [filter_on_field direction "North Bound" bus_locations]]]
    BusParser parsefile allroutes.xml
}
