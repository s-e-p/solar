# most time values are offset from the table epoch
# exceptions: p(epoch) set-time get-solar get-utc use UTC
#
# invariant: $p(lon) == [sun-position $p(noon)]
# rate	number of seconds in the current solar day

namespace eval ::solar {

# get the solar time and day: solar days * 86400 + solar time (0..86399)
#
proc solar-time U {
	variable p

	set L	[expr {wrap(0.5 - $p(lon))}]
	set T	[expr {round((0.5 + [get-solar $U]) * $p(day))}]
	set D	[expr {round([get-utc $L] / $p(solar))}]

	expr {round($D * $p(day) + $T)}
}

# set the bracket for the current time and location
#
proc set-time T {
	variable p

	# establish the invariant

	set lon		[sun-position $T]

	# find noon and the previous and next midnight

	lassign [get-time $p(lon) $lon $T $p(solar)] p(noon) p(rate)

	set target	[expr {$p(lon) - 0.5}]
	lassign [get-time $target $p(lon) $p(noon) $p(rate)] p(prev)

	set target	[expr {$p(lon) + 0.5}]
	lassign [get-time $target $p(lon) $p(noon) $p(rate)] p(next)
}

# convert solar cycle C to UTC based on current bracket
#
proc get-utc S {
	variable p

	if {abs($S) > 0.5} {
		set days	[expr {int($S)}]
		set T		[expr {$days * $p(solar) + $p(noon)}]
		set S		[expr {$S - $days}]

		set-time $T
	}

	if {$S < 0} {
		set rate	[expr {$p(noon) - $p(prev)}]
	} {
		set rate	[expr {$p(next) - $p(noon)}]
	}
	expr {round($p(epoch) + $p(noon) + ($S * $rate * 2.0))}
}

# convert UTC U to solar cycle based on current bracket
#
proc get-solar U {
	variable p

	set T	[expr {$U - $p(epoch)}]

	if {$T < $p(prev) || $T > $p(next)} {
		set-time $T
	}

	if {$T < $p(noon)} {
		set rate	[expr {$p(noon) - $p(prev)}]
	} {
		set rate	[expr {$p(next) - $p(noon)}]
	}

	expr {($T - $p(noon)) / ($rate * 2.0)}
}}
