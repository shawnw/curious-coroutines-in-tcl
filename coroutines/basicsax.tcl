#!/usr/bin/env tclsh
package require tdom

# A very simple example illustrating the tDOM SAX XML parsing interface

proc startElement {name attlist} {
    puts "startElement $name"
}

proc endElement {name} {
    puts "endElement $name"
}

proc characters {text} {
    set output [string map {\n \\n \t \\t} [string range $text 0 40]]
    puts "characters '$output'"
}

xml::parser BusParser \
    -final true \
    -elementstartcommand startElement \
    -elementendcommand endElement \
    -characterdatacommand characters

BusParser parsefile allroutes.xml
