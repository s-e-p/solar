apply {args {
	set dir [file dirname [info script]]
	foreach source $args {
		source [file join $dir $source.tcl]
	}
}} orbital bracket dump functions params iers-2006

namespace eval ::solar {
	namespace export set-init-loc set-loc dump
	namespace export get-utc get-solar
	namespace export day-info sun-info time-info
}

package provide solar 1.0
