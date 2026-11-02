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
	variable day

	puts $p(version)
	puts [format {%-6s %s} $p(planet) [show-loc $p(lat) $p(lon)]]
	puts [clock format $p(epoch) -timezone UTC]

	set U	[clock seconds]
	set T	[expr {$U - $p(epoch)}]

	puts [format {orbit: %3.9f  SSL: %3.9f}\
		[expr {radian([orbit-position $T]) * 360}]\
		[expr {[sun-position $T] * 360}]
	]

	set time [solar-time $U]

	puts [format {current solar day: %s} [show-time $p(rate)]]

	puts [format {solar day ratio: %1.8f} [expr {$p(rate) / $p(solar)}]]


	set noon [expr {round($p(noon) + $p(epoch))}]

	puts [clock format [expr {round($time * $day)}]\
		-format {current solar time   %Y-%m-%d %I:%M:%S %P}\
		-timezone +0000
	]

	puts "local solar noon    [clock format $noon]"

	puts "noon (solar mean)  \
		[clock format $noon -timezone [get-tz]]"

	puts "current local time \
		[clock format $U]"

	puts "current  UTC  time \
		[clock format $U -timezone UTC]"
} ::solar}
