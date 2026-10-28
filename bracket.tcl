# U is UTC seconds
# T is UTC seconds offset from p(epoch)
# S is a solar cycle (noon = 0.0)
#
# invariant: $p(lon) == [sun-position $p(noon)]
# rate	number of seconds in the current solar day

namespace eval ::solar {

# set the bracket
#
proc set-time T {
	variable p

	# establish the invariant

	set lon		[sun-position $T]
	set S		[expr {$p(lon) - $lon}]

	# find noon and the previous and next midnight
	lassign [get-time $S $T $lon $p(solar)]		noon rate
	lassign [get-time -0.5 $noon $p(lon) $rate]	p(prev)
	lassign [get-time +0.5 $noon $p(lon) $rate]	p(next)

	set p(noon)	$noon
	set p(rate)	[expr {($p(next) - $p(prev))}]
}

# set up the same bracket at a new location
#
proc set-loc {lat lon} {
	variable p

	set lon	[expr {0 - $lon}]
	set S	[expr {wrap($lon - $p(lon))}]
	lassign	[get-time $S $p(noon) $p(lon) $p(solar)]	noon rate

	lassign	[get-time -0.5 $noon $lon $rate]		p(prev)
	lassign	[get-time +0.5 $noon $lon $rate]		p(next)

	set p(lat)	$lat
	set p(lon)	$lon
	set p(noon)	$noon
	set p(rate)	[expr {($p(next) - $p(prev))}]
}

# get the solar time and day: solar days * 86400 + solar time (0..86399)
#
proc solar-time U {
	variable p

	set S	[expr {[get-solar $U] + 0.5}]
	set D	[get-utc 0.0]
	expr	{round((int($D / $p(solar)) + $S) * $p(day))}
}

# get the UTC time for a given solar time
#
proc utc-time solar {
	variable p

	set D	[expr {int($solar) / $p(day))}]
	set S	[expr {wrap(fmod($solar, 1) - 0.5)}]

	set D	[expr {int(($solar + $p(lon)) / $p(solar))}]
	set S	[get-solar [{$D * $day}]]
	expr	{round(($D + $S) * $p(day))}
}

# convert solar cycle C to UTC based on current bracket
# 0.0 = noon of current bracket
# if past midnight either way, estimate new noon and reset bracket
#
proc get-utc S {
	variable p

	if {abs($S) > 0.5} {
		set days	[expr {round($S)}]
		set S		[expr {wrap($S)}]

		set-time	[expr {$p(noon) + ($days * $p(solar))}]

	}

	set rate [expr {$S < 0 ?\
		($p(noon) - $p(prev)) : ($p(next) - $p(noon))}]

	expr {round($p(epoch) + $p(noon) + $S * $rate * 2.0)}
}

# convert UTC U to solar cycle - move bracket if necessary
#
proc get-solar U {
	variable p

	set T	[expr {$U - $p(epoch)}]

	if {$T < $p(prev) || $T > $p(next)} {
		set-time $T
	}

	expr {($T - $p(noon)) / ($T < $p(noon) ? $p(prev) : $p(next))}
}

# get +hhmm style timezone based on current longitude
#
proc get-tz {} {
	variable p

	set hh		[expr {$p(lon) * 24.0}]
	set sign	[expr {$hh > 0 ? "-" : "+"}]
        set mm  	[expr {abs(int(fmod($hh, 1.0) * 60.0))}]
        set hh  	[expr {abs(int($hh))}]
	format {%s%.2d%.2d} $sign $hh $mm
}}
