//This file sets up zlevels
/datum/scene/aeneas
	// Nikov 12/4/19
	//------------------
	name = "MSV Aeneas" 	//The name of the location. This may be shown in interfaces and should be human-readable
	id = "msv_aeneas"	//ID must be unique, landmarks will use it to link levels to this scene datum

//Base type of level, this one won't be instantiated but subtypes will
/datum/level/aeneas
	//Authortime
	//----------------
	name = "Deck 0" //Name of the level. This should NOT include the name of the scene, as that will be automatically prepended in most cases
	id	=	"aeneas_deck0" //ID of the level, this must be unique, so do include the scene name in this case. this will be used for a landmark to find this level
	scene_id = "msv_aeneas"	//ID of the scene, must be unique, used to link this level to the scene datum
	base_type	= /datum/level/aeneas //The parent/base type of this level. It will be excluded from the all_level_datums list


// Hub levels.


/datum/level/aeneas/bow
	// Nikov 12/4/19
	//----------------
	name = "D0 Bow"
	id	=	"aeneas_deck0"
	connections = list(DOWN_S =  "aeneas_deck1")

/obj/effect/landmark/map_data/aeneas/bow
	level_id	=	"aeneas_deck0"

/datum/level/aeneas/quarterdeck
	// Nikov 12/4/19
	//----------------
	name = "D1 Quarterdeck"
	id	=	"aeneas_deck1"
	connections = list(UP_S = "aeneas_deck0",
	DOWN_S =  "aeneas_deck2")

/obj/effect/landmark/map_data/aeneas/quarterdeck
	level_id	=	"aeneas_deck1"


/datum/level/aeneas/citadel
	// Nikov 12/4/19
	//----------------
	name = "D2 Citadel"
	id	=	"aeneas_deck2"
	connections = list(UP_S = "aeneas_deck1",
	DOWN_S =  "aeneas_deck3")

/obj/effect/landmark/map_data/aeneas/citadel
	level_id	=	"aeneas_deck2"


/datum/level/aeneas/midships
	// Nikov 12/4/19
	//----------------
	name = "D3 Midships"
	id	=	"aeneas_deck3"

	connections = list(UP_S = "aeneas_deck2",
	DOWN_S =  "aeneas_deck4")

/obj/effect/landmark/map_data/aeneas/midships
	level_id	=	"aeneas_deck3"


/datum/level/aeneas/machinery
	// Nikov 12/4/19
	//----------------
	name = "D4 Machinery"
	id	=	"aeneas_deck4"

	connections = list(UP_S = "aeneas_deck3",
	DOWN_S =  "aeneas_deck5")


/obj/effect/landmark/map_data/aeneas/machinery
	level_id	=	"aeneas_deck4"

/datum/level/aeneas/engine
	// Nikov 12/4/19
	//----------------
	name = "D5 Engine"
	id	=	"aeneas_deck5"
	connections = list(UP_S = "aeneas_deck4",
	DOWN_S =  "aeneas_deck6")

/obj/effect/landmark/map_data/aeneas/engine
	level_id	=	"aeneas_deck5"


/datum/level/aeneas/upperkeel
	// Nikov 12/4/19
	//----------------
	name = "D6 Upper Keel"
	id	=	"aeneas_deck6"
	connections = list(UP_S = "aeneas_deck5",
	DOWN_S =  "aeneas_deck7")

/obj/effect/landmark/map_data/aeneas/upperkeel
	level_id	=	"aeneas_deck6"


/datum/level/aeneas/lowerkeel
	// Nikov 12/4/19
	//----------------
	name = "D6 Lower Keel"
	id	=	"aeneas_deck7"
	connections = list(UP_S = "aeneas_deck6",
	DOWN_S =  "aeneas_deck8")

/obj/effect/landmark/map_data/aeneas/lowerkeel
	level_id	=	"aeneas_deck7"


/datum/level/aeneas/reactor
	// Nikov 12/4/19
	//----------------
	name = "D8 Reactor"
	id	=	"aeneas_deck8"
	connections = list(UP_S = "aeneas_deck7",
	DOWN_S =  "aeneas_overboard")

/obj/effect/landmark/map_data/aeneas/reactor
	level_id	=	"aeneas_deck8"


// Overboard level. Placeholder.


/datum/level/aeneas/overboard
	// Nikov 12/4/19
	//----------------
	name = "Overboard"
	id	=	"aeneas_overboard"

/obj/effect/landmark/map_data/aeneas/overboard
	level_id	=	"aeneas_overboard"


// Torus Levels


/datum/level/aeneas/innerring
	// Nikov 12/4/19
	//----------------
	name = "L0 Inner Ring"
	id	=	"aeneas_level0"
	connections = list(DOWN_S =  "aeneas_level1")

/obj/effect/landmark/map_data/aeneas/innerring
	level_id	=	"aeneas_level0"

/datum/level/aeneas/promenade
	// Nikov 12/4/19
	//----------------
	name = "L1 Promenade"
	id	=	"aeneas_level1"
	connections = list(UP_S = "aeneas_level0",
	DOWN_S =  "aeneas_level2")

/obj/effect/landmark/map_data/aeneas/promenade
	level_id	=	"aeneas_level1"


/datum/level/aeneas/mezzanine
	// Nikov 12/4/19
	//----------------
	name = "L2 Mezzanine"
	id	=	"aeneas_level2"
	connections = list(UP_S = "aeneas_level1",
	DOWN_S =  "aeneas_level3")

/obj/effect/landmark/map_data/aeneas/mezzanine
	level_id	=	"aeneas_level2"


/datum/level/aeneas/avenue
	// Nikov 12/4/19
	//----------------
	name = "L3 Avenue"
	id	=	"aeneas_level3"

	connections = list(UP_S = "aeneas_level2",
	DOWN_S =  "aeneas_level4")

/obj/effect/landmark/map_data/aeneas/avenue
	level_id	=	"aeneas_level3"


/datum/level/aeneas/outerring
	// Nikov 12/4/19
	//----------------
	name = "L4 Outer Ring"
	id	=	"aeneas_level4"

	connections = list(UP_S = "aeneas_level3",
	DOWN_S =  "aeneas_overboard")


/obj/effect/landmark/map_data/aeneas/outerring
	level_id	=	"aeneas_level4"