#
# add cycle functions to simplify the calculations
# used in the parameter table, so load them first
#
namespace eval ::tcl::mathfunc {

# convert angles to cycles
#
const 2pi	[expr 8 * atan(1)]
const deg	360.0

proc degree {d {m 0} {s 0}} {
	variable deg

	expr {(($d + $m / 60) + $s / 60) / $deg}
}

# convert radians to cycles
#
proc radian r {
	variable 2pi

	expr {$r / $2pi}
}

proc arcsec a {
	variable deg

	expr {$a / ($deg * 3600.0)}
}

# convert cycle to degrees and normalize to [0 .. 360)
# used to display a value
# add 0.0 to catch -0.0 (which is *not* less than 0.0)
#
proc deg c {
	variable deg

	set d [expr {fmod(($c * $deg), $deg)}]
	if {$d < 0} {
		expr {$d + $deg}
	} {
		expr {$d + 0.0}
	}
}

# convert cycle to degrees within range of -180 to +180
#
proc cyc c {
	variable deg

	expr {wrap($c) * $deg}
}

# convert cycle to radians with no adjustments
# used to do trig with a value; suitable for rates as well as angles
#
proc rad c {
	variable 2pi

	expr {$c * $2pi}
}

# reduce cycle t to range [-0.5 .. +0.5]
# used to normalize after incrementing
# note: both -0.5 and +0.5 are within range
#
proc wrap c {
	set c [expr {fmod($c, 1.0)}]
	if {$c > 0.5} {
		expr {$c - 1.0}
	} elseif {$c < -0.5} {
		expr {$c + 1.0}
	} else {
		expr {$c + 0.0}
	}
}}

apply {args {
	set dir [file dirname [info script]]
	foreach source $args {
		source [file join $dir $source.tcl]
	}
}} orbital bracket params iers-2006

package provide solar 1.0
