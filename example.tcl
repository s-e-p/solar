# arguments:
# time to show (default "now")
# planet (mars or earth, default earth),
# lon (longitude in degrees, default the location where the CERL
# Music Group and PLATO project were located on the University of Illinois
# Campus)
#
package require solar

::solar::set-init-time {*}$::argv

apply {{} {
	variable p

	puts $p(version)
	puts [format {%-6s %4.2f} $p(planet) [expr {$p(lon) * 360}]]
	puts [clock format $p(epoch)]

	set U	[clock seconds]
	set T	[expr {$U - $p(epoch)}]

	puts [format {orbit: %3.9f  SSL: %3.9f}\
		[expr {[orbit-position $T] * 360}]\
		[expr {[sun-position $T] * 360}]
	]

	set time [solar-time $U]

	set hours	[expr {int($p(rate) / 3600)}]
	set minutes	[expr {int(fmod(($p(rate) / 60), 60))}]
	set seconds	[expr {fmod($p(rate), 60)}]

	puts [format {current solar day: %.2d:%.2d:%06.3f}\
		$hours\
		$minutes\
		$seconds
	]

	puts [format {solar day ratio: %1.8g}\
		[expr {$p(rate) / $p(solar)}]
	]

	puts "current  UTC  time\
		[clock format $U -timezone UTC]"

	puts "current local time\
		[clock format $U]"

	puts "local solar noon   [clock format [get-utc 0]]"

	puts "current solar time\
		[clock format $time -gmt true\
		-format {%Y-%m-%d %I:%M:%S %P}]"
} ::solar}
