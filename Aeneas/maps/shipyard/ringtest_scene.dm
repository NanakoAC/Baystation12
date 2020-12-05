//This file sets up zlevels
/datum/scene/ringtest
	//Authortime
	//------------------
	name = "Ring Test" //The name of the location. This may be shown in interfaces and should be human-readable
	id = "ringtest"	  //ID must be unique, landmarks will use it to link levels to this scene datum

//Base type of level, this one won't be instantiated but subtypes will
/datum/level/ringtest
	//Authortime
	//----------------
	name = "Ringtest Main Deck" //Name of the level. This should NOT include the name of the scene, as that will be automatically prepended in most cases
	id	=	"ringtest_main" //ID of the level, this must be unique, so do include the scene name in this case. this will be used for a landmark to find this level
	scene_id = "ringtest"	//ID of the scene, must be unique, used to link this level to the scene datum
	base_type	= /datum/level/ringtest //The parent/base type of this level. It will be excluded from the all_level_datums list




/datum/level/ringtest/lower
	//Authortime
	//----------------
	name = "Lower Deck"
	id	=	"ringtest_lower"
	connections = list(UP_S = "ringtest_upper")

/obj/effect/landmark/map_data/ringtest/lower
	level_id	=	"ringtest_lower"



/datum/level/ringtest/upper
	//Authortime
	//----------------
	name = "Upper Deck"
	id	=	"ringtest_upper"
	connections = list(DOWN_S =  "ringtest_lower")
	loop = LOOP_CYLINDRICAL_HORIZONTAL

/obj/effect/landmark/map_data/ringtest/upper
	level_id	=	"ringtest_upper"

