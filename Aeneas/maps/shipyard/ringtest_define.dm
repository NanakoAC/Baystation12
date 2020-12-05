/datum/map/ringtest
	name = "Bearcat"
	full_name = "Bearcat"
	path = "overmap_example"

	station_name  = "FTV Bearcat"
	station_short = "Bearcat"

	dock_name     = "FTS Capitalist's Rest"
	boss_name     = "FTU Merchant Navy"
	boss_short    = "Merchant Admiral"
	company_name  = "Legit Cargo Ltd."
	company_short = "LC"

/datum/map/ringtest/get_map_info()
	return "You're aboard the <b>[station_name],</b> an independent vessel affiliated with Free Trade Union, on a SPACE FRONTIER. \
	No major corporation or government has laid claim on the planets in this sector, so their exploitation is entirely up to you - mine, poach and deforest all you want."

/datum/map/ringtest/setup_map()
	..()
	SStrade.traders += new /datum/trader/xeno_shop
	SStrade.traders += new /datum/trader/medical
	SStrade.traders += new /datum/trader/mining