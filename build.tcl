apply {{outfile infile main dir args} {

	set files [list $main main.tcl]

	foreach file $args {
		lappend files $file [file join solar $file]
	}

	zipfs lmkimg $outfile $files "" $infile
}} solar.tkapp run.app tk.tcl solar pkgIndex.tcl solar.tcl\
	functions.tcl params.tcl iers-2006.tcl\
	orbital.tcl bracket.tcl dump.tcl
