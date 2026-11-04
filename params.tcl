namespace eval ::solar {

# JD 0 is January 1, 4713 BC, 12:00:00.000 (Julian Date)
# J2000.0 epoch is defined as Julian Day 2451545.0
# or January 1, 2000, 12:00:00.000 TT
# or January 1, 2000, 11:59:27.816 TAI (-32.184 seconds)
# or January 1, 2000, 11:58:55.816 UTC (-64.184 seconds)
#
# there have been 5 leap seconds in UTC between then and now (2026/2027)
# it is likely there will be no leap seconds after 2026, however a similar
# mechanism will be needed to track DUT1 in order to keep the calculation of
# W correct (which is based on ERA which is defined on UT1, so using UTC as
# an approximatation of UT1 for now).
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

# load the parameter array
# set location and initial bracket
# default "now" to use the current time
#
proc set-init-loc {
		{lat 0.0}
		{lon 0.0}
		{utc now}
		{planet earth}
	} {
	variable p

	if {$utc eq "now"} {
		set utc	[clock seconds]
	}

	reset-time $utc $planet
	set-bracket 0 [expr {degree($lat)}] [expr {-degree($lon)}]
}

#
# recalculate parameters and reset the parameter array
#
proc reset-time {utc planet} {
	variable p

	array unset p
	array set p	[params $utc $planet]
}

#
# calculate tables to specified time
# set epoch to the valid time
# M and W can be linearly advanced with reasonable accuracy
# other parameters change so slowly they can be ignored for
# shorter times.  bracket code recalculates tables whenever
# the time is more than 10 days different from the table
#
proc params {time {planet earth}} {
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
# Tc is Julian centuries (based on TT)
# TUc is Julian centuries (based on UT1 - approximated by UTC - used for W)

	set epoch	[expr {$p(epoch) - ($TAI + $TT)}]
	set Tc		[expr {($time - $epoch) / ($day * $JCentury)}]
	set TUc		[expr {($time - $p(epoch)) / ($day * $JCentury)}]

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

	poly p(e)	$Tc
	poly p(obl)	$Tc
	poly p(peri)	$Tc
	poly p(M0)	$Tc
	poly p(W)	$TUc

# clean up M0, W (not strictly necessary)

	set p(M0)	[expr {wrap($p(M0))}]
	set p(W)	[expr {wrap($p(W))}]

	array get p
}

# calculate a polynomial with given x
# replace the polynomial list with the result
# polynomial coefficients specified lower order first
# so reverse list to efficiently calculate the result
#
proc poly {param x} {
	upvar $param p

	set v 0.0

	foreach c [lreverse $p] {
		set v [expr {$v * $x + $c}]
	}
	set p $v
}}
