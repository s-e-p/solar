apply {args {
	set dir [file dirname [info script]]
	foreach source $args {
		source [file join $dir $source.tcl]
	}
}} orbital bracket dump functions params iers-2006

namespace eval ::solar {
	namespace export set-init-time set-loc set-utc set-solar get-tz dump
}

package provide solar 1.0
