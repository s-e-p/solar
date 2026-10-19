# ---------------------------------------------------------------------------
# Earth/Mars orbital parameter - IERS-2006
# ---------------------------------------------------------------------------
namespace eval ::solar {

# convert from CIO frame to Equinox - this is getting silly
# W from ERA polynomial which uses a different frame

	const CIO	[expr degree(7.6884588)]

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
				[expr arcsec(-46.83676)]
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
				[expr 0.7790572732640 + $CIO]\
				[expr 1.00273781191135448 * $JCentury]\
				[expr arcsec(-0.014506)]\
				[expr arcsec(-461215.71764)]\
				[expr arcsec(-139.31422)]\
				[expr arcsec(0.04414)]\
				[expr arcsec(-0.000101)]\
				[expr arcsec(-0.00000003)]
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
