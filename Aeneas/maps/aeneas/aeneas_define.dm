/datum/map/aeneas
	name = "Aeneas"
	full_name = "Aeneas"
	path = "aeneas"

	station_name  = "MSV Aeneas"
	station_short = "Aeneas"

	dock_name     = "Hektor Consolidated Claimants"
	boss_name     = "HCC Board of Directors"
	boss_short    = "The Board"
	company_name  = "Andromache Habitat Holdings, Ltd."
	company_short = "AH2 Ltd."

	lobby_screens = list('maps/aeneas/lobby/retro1.gif','maps/aeneas/lobby/neon1.jpg')

/datum/map/aeneas/get_map_info()
	return "Terra is burning. \ By your own will or the mercy of the stars, you found yourself aboard the <b>[station_name],</b> a habitat station formerly orbiting the asteroid Hektor. \
	Converted into a jump-capable ship, the <b>[station_short]</b> has only one imperative; ensure the survival of those within by escaping those from without."

/datum/map/aeneas/setup_map()
	..()
	SStrade.traders += new /datum/trader/xeno_shop
	SStrade.traders += new /datum/trader/medical
	SStrade.traders += new /datum/trader/mining