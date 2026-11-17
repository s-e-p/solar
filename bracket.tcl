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

	set p(lat)	$lat
	set p(lon)	$lon

	# establish the invariant
	set orbit	[orbit-position $T]
	set ssl		[sun-position $orbit $T]
	set S		[expr {wrap($lon - $ssl)}]

	# find noon and the previous and next midnight
	lassign [get-time $S $T $ssl $p(msd)]	p(noon) p(noond) rate
	lassign [get-time -0.5 $p(noon) $lon $rate]	p(prev) p(prevd)
	lassign [get-time +0.5 $p(noon) $lon $rate]	p(next) p(nextd)

	set p(rate)	[expr {$p(next) - $p(prev)}]
}

# set lat/lon in degrees
#
proc set-loc {lat lon} {
	variable p

	set-bracket $p(noon) [expr {rad(degree($lat))}] [expr {-degree($lon)}]
}

#
# convert utc time to solar
#
proc get-solar utc {
	variable p

	set T	[expr {$utc - $p(epoch)}]

	if {$T < $p(prev) || $T > $p(next)} {
		set-bracket $T $p(lat) $p(lon)
		set T	[expr {$utc - $p(epoch)}]
	}

	set S	[expr {[T-to-S $T] + 0.5}]
	set D	[expr {int(([S-to-T 0.0] + $p(epoch)) / $p(msd))}]

	expr {$D + $S}
}

# convert the solar time to utc
#
proc get-utc solar {
	variable p

	set T	[expr {$solar * $p(msd) - $p(epoch)}]

	if {$T < $p(prev) || $T > $p(next)} {
		set-bracket	$T $p(lat) $p(lon)
	}

	set S	[expr {wrap($solar - 0.5)}]

	expr {round([S-to-T $S] + $p(epoch))}
}

# calculate utc seconds for offset of solar seconds
# only works for relatively small number of seconds
# (i.e. stays mostly within the bracket)
# this will be approximately $seconds * $t(rate) / $t(msd)
#
proc solar-seconds {solar seconds} {
	variable day

	set S [expr {fmod($solar, 1.0) - 0.5}]
	expr {[S-to-T [expr {$S + $seconds / $day}]] - [S-to-T $S]}
}

#
# return array of current bracket values
#
proc day-info {} {
	variable p
	variable day

	dict create\
		planet	$p(planet)\
		msd	$p(msd)\
		lat	[expr {deg(radian($p(lat)))}]\
		lon	[expr {-deg($p(lon))}]\
		loc	[show-loc $p(lat) $p(lon)]\
		tz	[get-tz]\
		noon	[expr {round($p(noon) + $p(epoch))}]\
		day	[expr {int(($p(noon) + $p(epoch)) / $p(msd))}]\
		rate	$p(rate)\
		seconds	$day
}

#
# find the sunrise/sunset from current bracket
#
proc sun-info {} {
	variable p
	variable day

	set Hn		[horizon $p(noond)]
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
			set Hp		[horizon $p(prevd)]
			set Hn		[horizon $p(nextd)]
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
						-format {%I:%M:%S %P}\
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
						-format {%I:%M:%S %P}\
						-timezone +0000
					]
			set utcset	[expr {round($p(epoch) + $setT)}]
		}
	}

	dict create\
		sunrise		$Hp\
		sunset		$Hn\
		sunsolar	[expr {($Hn - $Hp) * $day}]\
		sunlight	[expr {$setT - $riseT}]\
		suntimes	[list $sunrise $sunset]\
		utc-rise	$utcrise\
		utc-set		$utcset
}

#
# return an array of values for the specified utc time
#
proc time-info utc {
	variable day

	set solar	[get-solar $utc]
	set time	[expr {int($solar * $day)}]

	dict create\
		solar	$solar\
		utc	[expr {int($utc)}]\
		date	[clock format $time\
				-format {%Y-%m-%d}\
				-timezone +0000
			]\
		time	[clock format $time\
				-format {%I:%M:%S %P}\
				-timezone +0000
			]
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
