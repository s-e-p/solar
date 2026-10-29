# additional display routines
#
namespace eval ::solar {

# dump display routines
# just display the string
proc show-string s {
	format {%s} $s
}

# value is a UTC Unix time value, display as a UTC date/time
proc show-date v {
	clock format [expr {round($v)}]\
		-format {%Y-%m-%d %H:%M:%S} -gmt true
}

#value is a UTC offset from epoch - display as YYYY/MM/DD HH:MM:SS +zzzz
proc show-date-time v {
	variable p

	clock format [expr {round($p(epoch) + $v)}]\
		-timezone [get-tz] -format {%Y-%m-%d %H:%M:%S %z}
}

#value is a UTC time, display as solar time
proc show-solar v {
	variable day

	clock format [expr {round([solar-time $v] * $day)}]\
		-format {%Y-%m-%d %H:%M:%S}\
		-timezone +0000
}

# value is a UTC offset from epoch, display as UTC date/time
proc show-delta delta {
	variable p

	show-date [expr {$p(epoch) + $delta}]
}

# value is a UTC interval, display as HH:MM:SS.SSS
proc show-time v {
	set sign [expr {($v < 0) ? "-" : "+"}]
	set v [expr {abs($v)}]
	set seconds [expr {fmod($v, 60)}]
	set v [expr {int(($v - $seconds) / 60)}]
	set minutes [expr {int(fmod($v, 60))}]
	set hours [expr {int(($v - $minutes) / 60)}]

	format {%s%.2d:%.2d:%06.3f} $sign $hours $minutes $seconds
}

# show HH:MM:SS difference from local noon
proc show-offset v {
	variable p

	show-time [expr {$v - $p(noon)}]
}

# value is a UTC interval, display as solar days
# display as standard 24-hour days as well if different
proc show-days v {
	variable p
	variable day

	if {$p(solar) != $day} {
		format {%.3f (%.3f)} [expr {$v / $p(solar)}] [expr {$v / $day}]
	} {
		format {%.3f} [expr {$v / $p(solar)}]
	}
}

# display lat/lon pair in standard format
proc show-loc {lat lon} {
	const round	[expr {60.0 * 60.0 * 100.0}]

	set ddd	[expr {round(abs($lat * $round * 360.0)) / $round}]
	set mm	[expr {fmod($ddd, 1.0) * 60.0}]
	set ss	[expr {fmod($mm,  1.0) * 60.0}]
	set dir	[expr {$ddd == 0 ? " " : $lat < 0 ? "S" : "N"}]
	set ddd	[expr {int($ddd)}]
	set mm	[expr {int($mm)}]
	set lat	[format {%3d° %02d' %05.2f" %s} $ddd $mm $ss $dir]

	set ddd	[expr {round(abs($lon * $round * 360.0)) / $round}]
	set mm	[expr {fmod($ddd, 1.0) * 60.0}]
	set ss	[expr {fmod($mm,  1.0) * 60.0}]
	set dir	[expr {$ddd == 0 ? " " : $lon > 0 ? "W" : "E"}]
	set ddd	[expr {int($ddd)}]
	set mm	[expr {int($mm)}]
	set lon	[format {%3d° %02d' %05.2f" %s} $ddd $mm $ss $dir]

	format {%s  %s} $lat $lon
}

# just a number
proc show-number v {
	format {%f} $v
}

# value is in cycles, convert to degrees in range [0 ..360)
proc show-degree v {
	format {%f} [expr {deg($v)}]
}

# value is in cycles, convert to degrees in range [-180 .. 180]
proc show-cycle v {
	format {%f} [expr {wrap($v) * 360.0}]
}

# value is in cycles, normalize and display
proc show-frac v {
	format {%f} [expr {wrap($v)}]
}

proc dump {} {
	variable p

	foreach {name conv} {
		version	string
		epoch	date
		planet	string
		day	time
		orbit	days
		solar	time
		sidereal time
		e	number

		obl	degree
		peri	degree
		M0	cycle
		W	frac

		hor	cycle

		prev	offset
		noon	delta
		next	offset
		rate	time
		lat	cycle
		lon	cycle
	} {
		if {[info exists p($name)]} {
			set display [show-$conv $p($name)]
		} {
			set display -----
		}
		puts [format {%-10s%s} $name $display]
	}
}}
