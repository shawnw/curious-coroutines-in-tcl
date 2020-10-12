#!/usr/bin/env tclsh
package require Tcl 8.6

source buses.tcl
source coprocess.tcl

recvfrom stdin [filter_on_field route 22 \
                    [filter_on_field direction "North Bound" bus_locations]]
