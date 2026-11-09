package require solar
package require Tk

namespace eval display {
	namespace path ::solar

proc suntimes {rise set sunrise sunset sunlight} {
	if {[string is integer $sunrise]} {
		set sunrise	[clock format $sunrise -format {%I:%M:%S %P}]
	}

	if {[string is integer $sunset]} {
		set sunset	[clock format $sunset -format {%I:%M:%S %P}]
	}

	format "Solar: %11s   %-18s\nLocal: %11s   %-18s\nDaylight: %s"\
		$rise $set $sunrise $sunset [hours $sunlight]
}

proc hours seconds {
	set hh [expr {$seconds / 3600.0}]
	set mm [expr {fmod($hh, 1.0) * 60.0}]
	set ss [expr {int(fmod($mm, 1.0) * 60.0)}]
	set mm [expr {int($mm)}]
	set hh [expr {int($hh)}]

	format {%d:%.2d:%.2d} $hh $mm $ss
}

proc set-time {} {
	variable t
	variable time
	variable local
	variable utc
	variable day
	variable lat
	variable lon

	set time $t(time)
	set local [format {%-35s} [clock format $t(utc)\
		-format {%a %D %I:%M:%S %P %Z}
	]]

	set utc [format {%-35s} [clock format $t(utc) -timezone UTC\
		-format {%Z %Y-%m-%d %H:%M:%S}
	]]

	if {$day != $t(day) || $lat != $t(lat) || $lon != $t(lon)} {
		set-day
	}
}

proc set-day {} {
	variable t
	variable date
	variable loc
	variable sun
	variable noon
	variable day
	variable lat
	variable lon

	array set s [sun-info]

	set day $t(noon)
	set lat $t(lat)
	set date $t(date)
	set noon\
	"[clock format $t(noon)\
		-format {Local %H:%M:%S %P %Z}
	]\n[clock format $t(noon) -timezone $t(tz)\
		-format {Mean  %H:%M:%S %P %Z}
	]\nHours [hours $t(rate)]"
	set sun [suntimes {*}$s(suntimes) $s(utc-rise) $s(utc-set)\
		$s(sunlight)
	]
	set loc $t(loc)
}

proc scale {window w h} {
	variable width
	variable height
	variable scale
	variable size

	if {$window ne "."} return
	if {$w == $width && $h == $height} return
	set width $w
	set height $h

	set rw [winfo reqwidth .]
	set rh [winfo reqheight .]

	set scalew [expr {$scale * $w / $rw}]
	set scaleh [expr {$scale * $h / $rh}]
	set scale [expr {min($scalew, $scaleh)}]
	set new [expr {int(36 * $scale)}]
	if {$new != $size} {
		set size $new
		set lsize [expr {int(38 * $scale)}]
		font configure Solar -size $size
		font configure Label -size $lsize
	}
}

proc tick {} {
	variable t

	set time [expr {[clock milliseconds] / 1000.0}]
	array set t [::solar::time-info $time]
	set-time

	set solar [expr {$t(solar) * $t(rate)}]
	set tick [expr {1.5 - fmod($time, 1.0)}]
	set tock [expr {1.5 - fmod($solar, 1.0)}]
	set msec [expr {int(1000.0 *\
		min($tick, $tock))}]
	after $msec ::display::tick
}}

apply {{{lat +40.11206925115134} {lon -88.22634304261705}} {
	variable t
	variable scale	1.0
	variable size	36
	variable width
	variable height

	set-init-loc $lat $lon
	array set t [time-info [clock seconds]]

	set-day
	set-time

	font create Solar -family monospace -size $size
	font create Label -family monospace -size [expr {$size + 2}]\
		-weight bold

	label .date -textvariable ::display::date\
		-font Solar -justify left
	label .time -textvariable ::display::time\
		-font Solar -justify left
	label .sun -textvariable ::display::sun\
		-font Solar -justify left
	label .loc -textvariable ::display::loc\
		-font Solar -justify left
	label .local -textvariable ::display::local\
		-font Solar -justify left
	label .utc -textvariable ::display::utc\
		-font Solar -justify left
	label .noon -textvariable ::display::noon\
		-font Solar -justify left

	label .ltime -text "Solar time" -font Label
	label .lnoon -text "\nSolar noon" -font Label
	label .lsun -text "\nSunrise    |   Sunset  " -font Label
	label .llocal -text "\nStandard time" -font Label

	pack .ltime .date .time -side top
	pack .lnoon .noon -side top
	pack .lsun .sun -side top
	pack .llocal -side top
	pack .local .utc -side top
	pack .loc

	tk appname solar
	wm title . {Solar Time}

	update

	set width [winfo reqwidth .]
	set height [winfo reqheight .]

	bind . <Configure> {::display::scale %W %w %h}
	tick
} ::display} {*}$::argv
