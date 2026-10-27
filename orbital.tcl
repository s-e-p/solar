# most time values are offset from the table epoch
#
# invariant: lon == [sun-position noon]
# rate	number of seconds in the current solar day

namespace eval ::solar {
# solve for T: sun-position(T) == S
# set S to wrap($time - $lon) to find the time when
# the solar time at longitude $lon is $time [-0.5 .. +0.5]

proc get-time {S noon lon rate} {
	for {set i 0} {$i < 10} {incr i} {
		set T		[expr {$noon + $S * $rate}]
		set ssl		[sun-position $T]
		set delta	[expr {wrap($S + $lon - $ssl)}]

		if {abs($delta * $rate) < 1e-2} break

		set rate	[expr {($T - $noon) / ($S - $delta)}]
		set S		$delta
		set noon	$T
		set lon		$ssl
	}

	list	$T $rate
}

# calculate the sun's relative location at UTC delta (from epoch)
# return the Sub-Solar Location
#
# calculate the sun's location at UTC delta (from epoch)
# return the Sub-Solar Location in cycles
#

proc sun-position T {
	variable p

	expr {wrap(($p(W) + $T / $p(sidereal)) - [tilt $T])}
}

# factor in the tilt to adjust the orbital position
# return the result in cycles
#
proc tilt T {
	variable p

	set angle	[expr {[orbit-position $T] + rad($p(peri))}]
	set eps		[expr {rad($p(obl))}]

	expr {radian(atan2(cos(rad($p(obl))) * sin($angle), cos($angle)))}
}

# calculate orbital position at time T
# return result in radians from the sun
#
proc orbit-position T {
	variable p

# calculate current Mean Anomaly

	set M		[expr {rad(wrap($p(M0) + ($T / $p(orbit))))}]

# Kepler Equation Solver (Mean Anomaly -> Eccentric Anomaly)

	set e	$p(e)
	set E	[expr {$M + $e * sin($M)}]

	for {set i 0} {$i < 10} {incr i} {
		set dM [expr {$M - ($E - $e * sin($E))}]
		set dE	[expr {$dM / (1 - $e * cos($E))}]
		set E	[expr {$E + $dE}]
		if {abs($dE) < 1e-10} break
	}

# Return True Anomaly

	expr {2.0 * atan2(\
			sqrt(1.0 + $e) * sin($E / 2.0),\
			sqrt(1.0 - $e) * cos($E / 2.0))}

}}
