#!/bin/env tclsh
apply {{} {
	set app	[zipfs mount [info script] app]
	lappend ::auto_path $app

	uplevel #0 source [file join $app main.tcl]
}}
