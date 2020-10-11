#!/usr/bin/env tclsh
package require tdom

# A very simple example illustrating the tDOM SAX XML parsing interface

proc strtrans {text} {
    string map {\n \\n \t \\t} $text
}

proc startElement {name attlist} {
    puts "startElement $name"
}

proc endElement {name} {
    puts "endElement $name"
}

proc characters {text} {
    set output [strtrans [string range $text 0 40]]
    puts "characters '$output'"
}

xml::parser BusParser \
    -final 1 \
    -elementstartcommand startElement \
    -elementendcommand endElement \
    -characterdatacommand characters

BusParser parsefile allroutes.xml
