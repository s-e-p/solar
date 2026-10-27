apply {args {
	set dir [file dirname [info script]]
	foreach source $args {
		source [file join $dir $source.tcl]
	}
}} orbital bracket dump functions params iers-2006

package provide solar 1.0
