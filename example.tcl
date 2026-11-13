# arguments: lat lon planet
# default location is where the CERL Music Group and PLATO project
# were located on the University of Illinois Campus
#
package require solar


apply {{{lat	+40.11206925115134}
	{lon	-88.22634304261705}
	{time now}
	{planet earth}} {

	variable p

	set-init-loc $lat $lon [clock scan $time] $planet

	puts $p(version)
	puts [clock format $p(epoch) -timezone UTC]

	array set t [time-info $p(epoch)]
	array set s [sun-info]

	puts [format {%-6s %s} $t(planet) $t(loc)]

	puts [format {orbit: %3.9f  SSL: %3.9f}\
		[expr {deg(radian([orbit-position 0]))}]\
		[expr {[sun-position 0] * 360}]
	]

	puts [format {current solar day: %s}\
		[show-time $t(rate)]
	]

	puts [format {solar day ratio: %1.8f} [expr {$t(rate) / $t(msd)}]]

	puts "current solar time   $t(date) $t(time)"
	puts "local solar noon    [clock format $t(noon)]"
	puts "sunrise/sunset      $s(suntimes)"

	set sunrise	[get-utc [expr {$t(day) + $s(sunrise)}]]
	set sunset	[get-utc [expr {$t(day) + $s(sunset)}]]
	set daylight	[expr {($s(sunset) - $s(sunrise)) * $t(seconds)}]

	puts "sunrise             [clock format [expr {round($sunrise)}]]"
	puts "sunset              [clock format [expr {round($sunset)}]]"
	puts "daylight (solar)    [show-time $daylight]"
	puts "daylight (utc)      [show-time $s(sunlight)]"

	puts "noon (solar mean)  \
		[clock format $t(noon) -timezone $t(tz)]"

	puts "current local time \
		[clock format $p(epoch)]"

	puts "current  UTC  time \
		[clock format $p(epoch) -timezone UTC]"
} ::solar} {*}$::argv
