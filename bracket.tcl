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

	set p(lat)	$lat
	set p(lon)	$lon

	set p(noon)	$noon
	set p(next)	$next
	set p(prev)	$prev

	set p(rate)	[expr {$next - $prev}]
}

# set lat/lon in degrees
#
proc set-loc {lat lon} {
	variable p

	set-bracket $p(noon) [expr {degree($lat)}] [expr {-degree($lon)}]
}

#
# convert utc time to solar
#
proc get-solar utc {
	variable p

	set T	[expr {$utc - $p(epoch)}]

	if {$T < $p(prev) || $T > $p(next)} {
		set-bracket $T $p(lat) $p(lon)
	}

	set S	[expr {[T-to-S $T] + 0.5}]
	set D	[expr {int(([S-to-T 0.0] + $p(epoch)) / $p(solar))}]

	expr {$D + $S}
}

# convert the solar time to utc
#
proc get-utc solar {
	variable p

	set T	[expr {$solar * $p(solar) - $p(epoch)}]

	if {$T < $p(prev) || $T > $p(next)} {
		set-bracket	$T $p(lat) $p(lon)
	}

	set S	[expr {wrap($solar - 0.5)}]

	expr {round([S-to-T $S] + $p(epoch))}
}

#
# return array of current bracket values
#
proc day-info {} {
	variable p
	variable day

	set t(planet)	$p(planet)
	set t(msd)	$p(solar)
	set t(lat)	[expr {deg($p(lat))}]
	set t(lon)	[expr {-deg($p(lon))}]
	set t(loc)	[show-loc $p(lat) $p(lon)]
	set t(tz)	[get-tz]
	set t(noon)	[expr {round($p(noon) + $p(epoch))}]
	set t(day)	[expr {int(($p(noon) + $p(epoch)) / $p(solar))}]
	set t(rate)	$p(rate)
	set t(seconds)	$day

	array get t
}

#
# find the sunrise/sunset from current bracket
#
proc sun-info {} {
	variable p
	variable day

	set Hn		[horizon $p(noon)]
	if {$Hn < 0.0} {
		set Hp		0.5
		set sunrise	"no sun"
		set riseT	$p(noon)
		set utcrise	"down"

		set Hn		0.5
		set sunset	"no sun"
		set setT	$p(noon)
		set utcset	"down"
	} else {
		if {$Hn < 0.25} {
			set Hp	$Hn
		} else {
			set Hp		[horizon $p(prev)]
			set Hn		[horizon $p(next)]
		}

		if {$Hp > 0.5} {
			set Hp		0.0
			set sunrise	"already up"
			set utcrise	"up"
			set riseT	$p(prev)
		} else {
			set riseT	[S-to-T [expr {-$Hp}]]
			set Hp		[expr {0.5 - $Hp}]
			set time	[expr {round($Hp * $day)}]
			set sunrise	[clock format $time\
						-format {%I:%M:%S}\
						-timezone +0000
					]
			set utcrise	[expr {round($p(epoch) + $riseT)}]
		}

		if {$Hn > 0.5} {
			set Hn		+1.0
			set sunset	"stays up"
			set utcset	"up"
			set setT	$p(next)
		} else {
			set setT	[S-to-T $Hn]
			set Hn		[expr {0.5 + $Hn}]
			set time	[expr {round($Hn * $day)}]
			set sunset	[clock format $time\
						-format {%I:%M:%S}\
						-timezone +0000
					]
			set utcset	[expr {round($p(epoch) + $setT)}]
		}
	}

	set s(sunrise)	$Hp
	set s(sunset)	$Hn
	set s(sunsolar)	[expr {($Hn - $Hp) * $day}]
	set s(sunlight)	[expr {$setT - $riseT}]
	set s(suntimes)	[list $sunrise $sunset]
	set s(utc-rise)	$utcrise
	set s(utc-set)	$utcset

	array get s
}

#
# return an array of values for the specified utc time
#
proc time-info utc {
	set solar	[get-solar $utc]

	array set t	[day-info]

	set t(solar)	$solar
	set t(utc)	$utc
	set time	[expr {round($solar * $t(seconds))}]

	set t(date)	[clock format $time\
				-format {%Y-%m-%d}\
				-timezone +0000
			]
	set t(time)	[clock format $time\
				-format {%I:%M:%S %p}\
				-timezone +0000
			]
	array get t
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
