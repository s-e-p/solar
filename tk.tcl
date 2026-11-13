package require solar
package require Tk

namespace eval ::display {
	namespace path ::solar

	const label	38
	const text	32
	variable scale	1.0

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

proc show-time {} {
	variable t
	variable time
	variable local
	variable mean
	variable utc
	variable day
	variable lat
	variable lon

	set time $t(time)
	set local [format {%-35s} [clock format $t(utc)\
		-format {%a %D %I:%M:%S %P %Z}
	]]

	set mean [format {%-35s} [clock format $t(utc) -timezone $t(tz)\
		-format {SMT %D %I:%M:%S %P %Z}
	]]

	set utc [format {%-35s} [clock format $t(utc) -timezone UTC\
		-format {%Z %Y-%m-%d %H:%M:%S}
	]]

	if {$day != $t(day) || $lat != $t(lat) || $lon != $t(lon)} {
		show-day
	}
}

proc show-day {} {
	variable t
	variable date
	variable loc
	variable sun
	variable noon
	variable day
	variable lat
	variable lon

	array set s [sun-info]

	set day $t(day)
	set lat $t(lat)
	set lon $t(lon)
	set date $t(date)
	set noon\
	"[clock format $t(noon)\
		-format {Local %H:%M:%S %P %Z}
	]\n[clock format $t(noon) -timezone $t(tz)\
		-format {SMT   %H:%M:%S %P %Z}
	]\nHours [hours $t(rate)]"
	set sun [suntimes {*}$s(suntimes) $s(utc-rise) $s(utc-set)\
		$s(sunlight)
	]
	set loc $t(loc)
}

proc scale {w h} {
	variable label
	variable text
	variable width
	variable height
	variable scale

	if {$w == $width && $h == $height} return

	set width	$w
	set height	$h

	set rw		[expr {[winfo reqwidth .main] / $scale}]
	set rh		[expr {[winfo reqheight .main] / $scale}]

	set size	[expr {min($w / $rw, $h / $rh)}]

	set tsize	[expr {int($size * $text)}]
	set lsize	[expr {int($size * $label)}]

	if {$lsize < 10 || $lsize > 100} return

	if {$lsize == int($scale * $label) ||
		$tsize == int($scale * $text)} return

	set scale	$size

	font configure Solar -size $tsize
	font configure Label -size $lsize
}

proc tick {} {
	variable t

	set time [clock milliseconds]
	array set t [time-info [expr {$time / 1000.0}]]
	show-time

	# calculate next utc second offset
	set tick	[expr {1500 - ($time % 1000)}]

	# calculate next solar second offset
	set solar	[expr {fmod($t(solar), 1.0)}]
	set seconds	[expr {1.5 - fmod($solar * $t(seconds), 1.0)}]
	set next	[solar-seconds $solar $seconds]
	set tock	[expr {int($next * 1000.0)}]

	# delay until whichever is next
	set msec	[expr {min($tick, $tock)}]
	after $msec ::display::tick

	puts [format "u: %6.5f %s.%03d\ns: %6.5f %s.%05d\nm:\
			%4d %4d %4d\n"\
		[expr {fmod($time / 1000.0, 60.0)}]\
		[clock format $t(utc) -format {%H:%M:%S}]\
		[expr {$time % 1000}]\
		[expr {fmod($solar * $t(seconds), 60.0)}]\
		[clock format [expr {int($t(solar) * $t(seconds))}]\
			-format {%H:%M:%S} -timezone +0000]\
		[expr {int(fmod($t(solar) * $t(seconds), 1.0) * 100000.0)}]\
		$tick $tock $msec
	]
}}

apply {{{lat +40.11206925115134} {lon -88.22634304261705}} {
	variable t
	variable text
	variable label
	variable width
	variable height

	set-init-loc $lat $lon
	array set t [time-info [clock seconds]]

	show-day
	show-time

	font create Solar {*}[font configure TkFixedFont]\
		-size $text
	font create Label {*}[font configure TkHeadingFont]\
		-size $label -weight bold

	frame .main
	label .main.date -textvariable ::display::date\
		-font Solar -justify left
	label .main.time -textvariable ::display::time\
		-font Solar -justify left
	label .main.sun -textvariable ::display::sun\
		-font Solar -justify left
	label .main.loc -textvariable ::display::loc\
		-font Solar -justify left
	label .main.local -textvariable ::display::local\
		-font Solar -justify left
	label .main.mean -textvariable ::display::mean\
		-font Solar -justify left
	label .main.utc -textvariable ::display::utc\
		-font Solar -justify left
	label .main.noon -textvariable ::display::noon\
		-font Solar -justify left

	label .main.ltime -text "Solar time" -font Label
	label .main.lnoon -text "\nSolar noon" -font Label
	label .main.lsun -text "\nSunrise    |   Sunset  " -font Label
	label .main.llocal -text "\nStandard time" -font Label

	pack .main.ltime .main.date .main.time -side top
	pack .main.lnoon .main.noon -side top
	pack .main.lsun .main.sun -side top
	pack .main.llocal -side top
	pack .main.local .main.mean .main.utc -side top
	pack .main.loc

	pack .main -fill both -expand true

	tk appname solar
	wm title . {Solar Time}

	update

	set width	[winfo width .main]
	set height	[winfo height .main]

	set w		[winfo screenwidth .]
	set h		[winfo screenheight .]

	if {$w > $h} {
		set w	[expr {int($w / 3.0)}]
		set h	[expr {int($h * 2.0 / 3.0)}]
	} {
		set w	[expr {int($w * 2.0 / 3.0)}]
		set h	[expr {int($h * 2.0 / 3.0)}]
	}

	wm geometry . ${w}x${h}

	bind .main <Configure> {::display::scale %w %h}
	tick
	tkwait window .
	puts "main window closed"
	foreach task [after info] {after cancel $task}
} ::display} {*}$::argv

