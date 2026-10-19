namespace eval ::solar {

# JD 0 is January 1, 4713 BC, 12:00:00.000 (Julian Date)
# J2000.0 epoch is defined as Julian Day 2451545.0
# or January 1, 2000, 12:00:00.000 TT
# or January 1, 2000, 11:59:27.816 TAI (-32.184 seconds)
# or January 1, 2000, 11:58:55.816 UTC (-64.184 seconds)
#
# there have been 5 leap seconds in UTC between then and now (2026/2027)
#
# Unix clock 0 is Jan 1 1970 00:00:00.00 UTC
#
# TT = ET at JD 2443144.5, January 1, 1977 00:00:00 TT
#
#
# TAI = UTC + 32.0 (in 2000)
# TT = TAI + 32.184 (always)
# TT = UTC + 64.184 (in 2000)
# UTC = TAI - 32.0 (in 2000)
# UTC = TAI - 37.0 (in 2026)
#
# day		seconds per day
# J2000.0	base epoch in tables
# TAI		convert UTC to TAI
# TT		convert TAI to TT (2026)
# Julian	Julian day of TT clock 0
# JCentury	days per Julian Century

	const day	86400.0
	const TT	+32.184
	const TAI	+37.0
	const J2000.0	946728000.0
	const Julian	2451545.0
	const JCentury	36525.0

proc	set-init-time {
		{time now}
		{planet earth}
		{loc {+40.11206925115134 -88.22634304261705}}
	}\
{
	variable p

	lassign $loc	lat lon

	array unset p
	array set p	[params $planet [clock scan $time]]

	set p(lat)	[expr {degree($lat)}]
	set p(lon)	[expr {degree($lon)}]

	lassign	[get-time $p(lon) [sun-position 0] 0 $p(solar)] p(noon) p(rate)
	set-time 0
}

#
# enter with time = UTC time
#
proc params {planet time} {
	variable PARAMS
	variable day
	variable TT
	variable TAI
	variable JCentury

# time scale constants
# in TT seconds, just there for documentation
# UTC is offset from TAI to UTC, TT is offset from TAI to TT


	array set p	$PARAMS($planet)
	set p(version)	$PARAMS(version)

# get offset from table epoch in TT from UTC seconds

	set epoch	[expr {$p(epoch) - ($TAI + $TT)}]
	set days	[expr {($time - $epoch) / $day}]
	set Tc		[expr {$days / $JCentury}]

# Update epoch and planet

	set p(planet)	$planet
	set p(epoch)	$time

# calculate sidereal time from solar and orbit times
# if sidereal already provided calculate solar from that
# this allows setting Earth "mean solar day" to exactly 86400 second
# since UTC adjustments are based on that being exact

	if {[info exists p(sidereal)]} {
		# calculate solar from sidereal
		set p(solar) [expr {$p(sidereal) * $p(orbit)\
			/ ($p(orbit) - $p(sidereal))}]
	} else {
		# else calculate sidereal from solar
		set p(sidereal) [expr {$p(solar) * $p(orbit)\
			/ ($p(solar) + $p(orbit))}]
	}

# 3. Apply time transformation polynomials

	poly p(e)	$Tc
	poly p(obl)	$Tc
	poly p(peri)	$Tc
	poly p(M0)	$Tc
	poly p(W)	$Tc

# clean up M0, W (not strictly necessary)

	set p(M0)	[expr {wrap($p(M0))}]
	set p(W)	[expr {wrap($p(W))}]

# return the completed array

	array get p
}

# calculate a polynomial with given x
# replace the polynomial list with the result

proc poly {param x} {
	upvar $param p

	set v 0.0

	foreach c [lreverse $p] {
		set v [expr {$v * $x + $c}]
	}
	set p $v
}}

#
# add cycle functions to simplify the calculations
#
namespace eval ::tcl::mathfunc {

# convert angles to cycles
#
const 2pi	[expr 8 * atan(1)]
const deg	360.0

proc degree d {
	variable deg

	expr {$d / $deg}
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
