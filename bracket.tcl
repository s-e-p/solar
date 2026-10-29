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

	set S	[expr {wrap($lon - $p(lon))}]
	lassign	[get-time $S $p(noon) $p(lon) $p(solar)]	noon rate

	lassign	[get-time -0.5 $noon $lon $rate]		p(prev)
	lassign	[get-time +0.5 $noon $lon $rate]		p(next)

	set p(lat)	$lat
	set p(lon)	$lon
	set p(noon)	$noon
	set p(rate)	[expr {($p(next) - $p(prev))}]
}

# get the solar day value
# solar days + fractional solar time shifted to [0..1)
#
proc solar-time U {
	variable p

	set S	[expr {[get-solar $U] + 0.5}]
	set D	[expr {int([get-utc 0.0] / $p(solar))}]
	expr	{$D + $S}
}

# get the UTC time for a given solar day value
#
proc utc-time solar {
	variable p

	set-time	[expr {(int($solar) + 0.5) * $p(solar) - $p(epoch)}]
	get-utc		[expr {wrap($solar - 0.5)}]
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

	set rate [expr {2.0 * ($S < 0 ?\
		$p(noon) - $p(prev) : $p(next) - $p(noon))}]

	expr {round($p(epoch) + $p(noon) + $S * $rate)}
}

# convert UTC U to solar cycle - move bracket if necessary
#
proc get-solar U {
	variable p

	set T	[expr {$U - $p(epoch)}]

	if {$T < $p(prev) || $T > $p(next)} {
		set-time $T
	}

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
        set mm  	[expr {abs(int(fmod($hh, 1.0) * 60.0))}]
        set hh  	[expr {abs(int($hh))}]
	format {%s%.2d%.2d} $sign $hh $mm
}}
