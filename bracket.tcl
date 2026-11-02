# U is UTC seconds
# T is UTC seconds offset from p(epoch)
# S is a solar cycle (noon = 0.0)
#
# longitude is positive West, the reverse of standard usage
# this keeps rotation and orbital motion positive with respect
# to increasing time
#
# invariant: lon == [sun-position noon]
# rate is the number of seconds in the current solar day

namespace eval ::solar {

# set bracket for specified time and location
# recalculate table if more than 10 days from previous epoch
#
proc set-bracket {T lat lon} {
	variable p
	variable day

	if {abs($T) > 10 * $day} {
		set U [expr {$T + $p(epoch)}]
		reset-time $U $p(planet)
		set T 0.0
	}

	# establish the invariant
	set ssl		[sun-position $T]
	set S		[expr {wrap($lon - $ssl)}]

	# find noon and the previous and next midnight
	lassign [get-time $S $T $ssl $p(solar)]		noon rate
	lassign [get-time -0.5 $noon $lon $rate]	prev
	lassign [get-time +0.5 $noon $lon $rate]	next

	set p(rate)	[expr {$next - $prev}]

	set p(noon)	$noon
	set p(next)	$next
	set p(prev)	$prev

	set p(lat)	$lat
	set p(lon)	$lon
}

# get the solar day value as UTC
#
proc solar-time U {
	variable p

	set T	[expr {$U - $p(epoch)}]

	if {$T < $p(prev) || $T > $p(next)} {
		set-bracket $T $p(lat) $p(lon)
	}

	set S	[expr {[T-to-S $T] + 0.5}]
	set D	[expr {int(([S-to-T 0.0] + $p(epoch)) / $p(solar))}]
	expr	{$D + $S}
}

# get the UTC time as solar day value
#
proc utc-time solar {
	variable p

	set T	[expr {(int($solar) + 0.5) * $p(solar) - $p(epoch)}]

	if {$T < $p(prev) || $T > $p(next)} {
		set-bracket	$T $p(lat) $p(lon)
	}

	set S	[expr {wrap($solar - 0.5)}]

	expr {round([S-to-T $S] + $p(epoch))}
}

# convert solar cycle S to T based on current bracket
# 0.0 = noon of current bracket
# S should be in range [-0.5 .. +0.5]
#
proc S-to-T S {
	variable p

	set rate [expr {2.0 * ($S < 0 ?\
		$p(noon) - $p(prev) : $p(next) - $p(noon))}]

	expr {$p(noon) + $S * $rate}
}

# convert T to solar cycle
# T should be within current bracket
#
proc T-to-S T {
	variable p

	set rate [expr {2.0 * ($T < $p(noon) ?\
		$p(noon) - $p(prev) : $p(next) - $p(noon))}]

	expr {($T - $p(noon)) / $rate}
}

# get +hhmm style timezone based on current longitude
#
proc get-tz {} {
	variable p

	set hh		[expr {$p(lon) * 24.0}]
	set sign	[expr {$hh > 0 ? "-" : "+"}]
	set mm		[expr {abs(int(fmod($hh, 1.0) * 60.0))}]
	set hh		[expr {abs(int($hh))}]
	format {%s%.2d%.2d} $sign $hh $mm
}}
