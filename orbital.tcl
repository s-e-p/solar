# most time values are offset from the table epoch
#
# invariant: $p(lon) == [sun-position $p(noon)]
# rate	number of seconds in the current solar day

namespace eval ::solar {

# solve for T: sun-position(T) == target

proc get-time {target lon noon rate} {
	for {set i 0} {$i < 10} {incr i} {
		set S		[expr {wrap($target - $lon)}]
		set T		[expr {$noon + $S * $rate}]
		set ssl		[sun-position $T]

		if {abs($rate * wrap($ssl - $lon)) < 1e-2} break

		set rate	[expr {($T - $noon) / ($ssl - $lon)}]
		set noon	$T
		set lon		$ssl
	}

	list $T $rate
}

# calculate the sun's relative location at UTC delta (from epoch)
# return the Sub-Solar Location
#
# calculate the sun's location at UTC delta (from epoch)
# return the Sub-Solar Location
#

proc sun-position T {
	variable p

# calculate planet rotation

	set position	[expr {wrap($p(W) + ($T / $p(sidereal)))}]
	set orbit	[orbit-position $T]
	expr {wrap(0.5 + $position - $orbit)}
}

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

	expr {wrap(radian(2.0 * atan2(\
			sqrt(1.0 + $e) * sin($E / 2.0),\
			sqrt(1.0 - $e) * cos($E / 2.0))) + $p(peri))}

}}
