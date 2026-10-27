# ---------------------------------------------------------------------------
# Earth/Mars orbital parameter - IERS-2006
# ---------------------------------------------------------------------------
namespace eval ::solar {

	variable PARAMS
	array set PARAMS [dict create\
	version	{2024-03-15 IERS-2006}\
	earth	[dict create\
		epoch	${J2000.0}\
		day	$day\
		solar	$day\
		orbit	31556925.2\
		e	[list\
				 0.01670863\
				-0.000042037
			]\
		obl	[list\
				[expr degree(23.4392911)]\
				[expr degree(0, 0, -46.83676)]
			]\
		M0	[list\
				[expr degree(357.52911)]\
				[expr degree(35999.05029)]
		]\
		peri	[list\
				[expr degree(282.93735)]\
				[expr degree(1.71946)]
			]\
		W	[list\
				[expr 0.7790572732640]\
				[expr 1.00273781191135448 * $JCentury]\
				[expr -degree(0, 0, 0.014506)]\
				[expr -degree(128, 0, 55.71764)]\
				[expr -degree(0, 0, 139.31422)]\
				[expr  degree(0, 0, 0.04414)]\
				[expr -degree(0, 0, 0.000101)]\
				[expr -degree(0, 0, 0.00000003)]
			]\
		hor	[expr degree(-0.8333)]
	]\
	mars	[dict create\
			epoch	${J2000.0}\
			day	$day\
			sidereal 88642.69\
			orbit	59355072.0\
			e	[list\
					0.09340552\
					0.00090181
				]\
			obl	[list\
					[expr degree(25.191825)]
				]\
			M0	[list\
					[expr degree(19.388166)]\
					[expr degree(19140.29934)]
				]\
			peri	[list\
					[expr degree(336.06084)]\
					[expr degree(0.44388)]
				]\
			W	[list\
					[expr degree(280.46061837)]
				]\
			hor	[expr degree(0.0)]
		]
	]
}
