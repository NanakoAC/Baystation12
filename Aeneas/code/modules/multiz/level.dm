
/*
	A level datum represents one flat zlevel in game memory.
	They are created at authortime and should be placed in the map folder, same file as scene and landmarks will do fine.
	All levels must be unique, never reuse the same one twice

	This is a big file. Contents:
	1. Definitions
	2. Subtypes and generic levels
	3. Helper procs
	4. Core code (biggest section)
*/
/datum/level
	//Authortime
	//----------------

	var/name = "Space" //Name of the level. This should NOT include the name of the scene, as that will be automatically prepended in most cases
	var/id	=	"unknown_space" //ID of the level, this must be unique, so do include the scene name in this case. this will be used for a landmark to find this level
	var/scene_id = "unknown_location"	//ID of the scene, must be unique, used to link this level to the scene datum
	var/base_type	= /datum/level //The parent/base type of this level. It will be excluded from the all_level_datums list



	var/list/connections = list()
	/*
	This list is crucial, it explains how this level connects to others.
	It is an associative list
	Using the six direction defines in string form as key, and the id of another level as value.
	UP_S = unknown_deck2
	DOWN_S = unknown_deck0
	WEST_S = something
	EAST_S = something
	NORTH_S = something
	SOUTH_S = something

	Only one connection per direction, but its perfectly fine to connect to the same level in multiple directions, there are applications for that.

	At runtime, this list is converted from ids to datum references as the value. key remains unchanged
	*/




	//If false, players will end up floating in space when they fall of the edge
	//If true, players can't walk off the edge of this map unless theres a specific connection.
	var/sealed = FALSE


	//Loop types, see turf/loop/readme.dm
	//Sort of overrides sealed var above. Players should bever be able to reach a map edge on a looping side
	var/loop = LOOP_NONE


	//If true, this is a place for admins and antags,not for normal players. Certain things may be restricted here
	var/admin_level = FALSE

	//Runtime
	//----------------
	var/z = 0	//Holds the z value associated with this level
	var/datum/scene/scene	//Pointer to the scene datum, this is populated at runtime

	//Bounds. The tile coordinates of the lowerleft and upper right corners of the play area
	//This is primarily used for looping
	var/vector2/bounds_lower
	var/vector2/bounds_upper


/*--------------------------------------------------------------------------------------------------------------

	Generic levels: Useable on multiple maps, so long as only one of those maps is loaded, which it will be

--------------------------------------------------------------------------------------------------------------*/
//Levels for your map should not go here. They should be defined in a <mapname>_scene.dm file, inside that map's own folder

//extra transit and admin levels can be added if needed by incrementing the number on the end of id
/datum/level/admin
	//Authortime
	//----------------
	name = "" //Name of the level. This should NOT include the name of the scene, as that will be automatically prepended in most cases
	id	=	"admin_level_1" //ID of the level, this must be unique, so do include the scene name in this case. this will be used for a landmark to find this level
	scene_id = "admin_space"	//ID of the scene, must be unique, used to link this level to the scene datum
	admin_level = TRUE

/datum/level/transit
	//Authortime
	//------------------
	name = "" //The name of the location. This may be shown in interfaces and should be human-readable
	id = "transit_level_1"	  //ID must be unique, landmarks will use it to link levels to this scene datum
	scene_id = "transit_space"

/datum/level/overmap
	name = "Overmap"
	id = "overmap"
	scene_id = "overmap"
	admin_level = TRUE
	sealed = TRUE


//Subtype which adds itself to the empty levels list. Don't use this as is, make subtypes
/datum/level/empty
	base_type	= /datum/level/empty

/datum/level/empty/Initialize()
	.=..()
	SSmapping.empty_levels |= src

//Used for an empty zlevel which is loaded along with all the other maps as an included dmm
//This is done to reduce in-round lag
/datum/level/empty/precached
	id = "empty_precached"
	scene_id = "space"


/*--------------------------------------------------------------------------------------------------------------

	Helper Procs:

--------------------------------------------------------------------------------------------------------------*/
/atom/proc/get_level()
	if (z)
		return SSmapping.zlevels["[z]"]
	return null

/proc/get_level_from_z(var/z)
	return SSmapping.zlevels["[z]"]

/proc/get_level_by_id(var/_id)
	var/datum/level/L = SSmapping.all_level_datums[_id]
	return L

/proc/can_move_between_levels(var/atom/mover = null, var/direction = null,  var/method = ZMOVE_PHASE, var/datum/level/origin, var/datum/level/destination)
	if (origin.can_leave_level(mover, direction, method, destination) && destination.can_enter_level(mover, direction, method, origin))
		return TRUE
	return FALSE

/proc/get_empty_level()
	if(!SSmapping.empty_levels.len)
		create_empty_level()
	if(SSmapping.empty_levels.len)
		return pick(SSmapping.empty_levels)

	return null

/proc/create_empty_level()
	world.maxz++ //This adds a new level onto the end of the list
	SSmapping.map_index++ //Increment the index
	var/datum/level/newlevel = new()
	newlevel.z = world.maxz
	newlevel.id = "[newlevel.id]_[SSmapping.map_index]" //The new level uses the default values, but with the map index appended onto the end of the ID
	//This ensures that the id is unique and prevents namespace collisions.
	//All the empty levels will be in the same scene, but not directly connected to each other
	newlevel.Initialize()
	SSmapping.empty_levels += newlevel

//This creates and initializes a new level datum. z and _id are the only mandatory parameter
//It can also be used to repurpose and re-initialize an existing level
/proc/create_level(var/_z, var/_id, var/_scene_id, var/_name, var/_type = /datum/level)
	if (!_z || !_id)
		return

	//If a level already exists for this z, we wipe it and replace it with our new one
	var/datum/level/L = SSmapping.zlevels["[_z]"]
	if (istype(L))
		qdel(L)
		SSmapping.zlevels["[_z]"] = null

	//Check if a predefined datum exists for this id.
	L = get_level_by_id(_id)
	if (!istype(L))
		L = new _type
		L.id = _id
		if (_scene_id)
			L.scene_id = _scene_id
		if (_name)
			L.name = _name

	if (L)
		L.z = _z
		L.Initialize()
		return L


/*--------------------------------------------------------------------------------------------------------------

	Level Core Code

--------------------------------------------------------------------------------------------------------------*/

//This is called when a landmark for this level does its thing, and AFTER we've been assigned a z number
/datum/level/proc/Initialize()

	//Add it to the global list of all zlevels
	SSmapping.zlevels["[z]"] = src

	//Lets replace the strings in our connections list with datums
	for (var/direction in connections)
		var/name = connections[direction]
		var/datum/level/L = SSmapping.all_level_datums[name]
		connections[direction] = L


	//And add it to the list in the parent scene datum
	scene.levels["[z]"] = src
	scene.level_numbers |= z //There should never be two of these landmarks on the same level, but lets use |= anyway in case someone screwed up


	measure_bounds()


/datum/level/proc/measure_bounds()
	//Now lets measure the level and set bounds
	//First of all, sane defaults that will apply to 99% of cases
	bounds_lower = new /vector2(1,1)
	bounds_upper = new /vector2(world.maxx, world.maxy)

	//If we're not using any looping, we don't need to do anything else
	if (loop == LOOP_NONE )
		return

	/*
		The problem. Loop zones can be any thickness, and theoretically might not even be the same on all sides.
		Assumptions we can make:
			1. The playable area is rectangular in shape
			2. If a side has loop tiles, the opposing side does too
			3. If a side has loop tiles, they will span that entire side's length, and will have no gaps in their thickness
				If this is not the case, it is an error by a mapper, we will not excuse that.
			4. Regardless of configuration (except LOOP_NONE), the bottomleft corner is always a loop tile
				Note: Does not apply to other corners. Because its possible for a map to be loaded which is smaller than world maxX/Y sizes.
				In which case it would be placed in the lowerleft corner of a zlevel, with empty (space) tiles filling the top and right edges

		Ok, here's the most efficient way I could figure out
		1. Start at the bottom left corner (southwest). If there's ANY looping going on, then that tile will always be a loop tile
			Moving diagonally up and right (northeast), check each tile as we go to see if its a loop tile
		2. Once we find our first non-loop tile, we know that we have found the inner boundary of either the west or the south loopzone
			2a: Check the tile to the left. If its a loopzone, we have found our X boundary
			2b: If its not a loopzone, then we've found our Y boundary
		3. Now keep moving backwards (subtract 1) from the axis we're missing and keep checking til we find a loopzone, thus we get our bottomleft bound
		4. From there its a simple manner to check straight up and straight right
	*/

	var/turf/T

	//Step 1: Search diagonally starting from lowerleft
	var/index = 1
	var/done = FALSE
	while (!done)
		T = locate(index, index, z)
		if (!T)
			log_world("Fatal error while measuring bounds of level [z] at coords [index],[index]")
			return


		if (!T.is_mirror())
			done = TRUE
			break
		index++


	//Step 2: We have found a non loop tile
	//Check one to the left
	T = locate(index-1, index, z)
	if (!T)
		log_world("Fatal error while measuring bounds of level [z] at coords [index-1],[index]")
		return

	//Set both X and Y to where we are now, even though only one of the two is correct. This helps simplify the code logic
	bounds_lower.x = index
	bounds_lower.y = index
	//Then we figure out which one is the correct one, and set the direction to search for the other
	var/vector2/direction = new /vector2(0,0) //Indicates what direction we'll search in to find the other boundary
	if (T.is_mirror())
		//2a: We have found the X boundary
		direction.y = -1 //Set the delta's y axis
	else
		//2b: We have found the Y boundary
		direction.x = -1 //Set the delta's x axis

	//Step 3: Now lets get the axis we're missing
	done = FALSE
	var/length = 1
	//now lets search for the missing bound
	while (!done)
		T = locate(bounds_lower.x+(direction.x*length), bounds_lower.y+(direction.y*length), z)
		if (!T || T.is_mirror())
			//We found it!
			bounds_lower.x += (direction.x*(length-1))
			bounds_lower.y += (direction.y*(length-1))
			done = TRUE
		length++


	//We have now successfully located the lowerleft corner of the play area
	//Step 4: We're not going to repeat the above to find the upper right. We can do the simpler method. Two loops
	length = 1
	done = FALSE
	//X First
	while (!done)
		T = locate(bounds_lower.x+(length), bounds_lower.y, z)
		if (!T || T.is_mirror())
			bounds_upper.x = bounds_lower.x+(length-1)
			done = TRUE
		length++

	//Then Y
	length = 1
	done = FALSE
	while (!done)
		T = locate(bounds_lower.x, bounds_lower.y+(length), z)
		if (!T || T.is_mirror())
			bounds_upper.y = bounds_lower.y+(length-1)
			done = TRUE
		length++

	return

//Called on the origin level when attempting to transition to a different one. Should return true or false only.
//When calling, supply any vars you have data for, an override can use them to figure out what to do
/datum/level/proc/can_leave_level(var/atom/mover = null, var/direction = null,  var/method = ZMOVE_PHASE, var/datum/level/destination = null)
	return TRUE


//Called on the origin level when attempting to transition to a different one. Should return true or false only
//When calling, supply any vars you have data for, an override can use them to figure out what to do
/datum/level/proc/can_enter_level(var/atom/mover = null, var/direction = null,  var/method = ZMOVE_PHASE, var/datum/level/origin = null)
	return TRUE


//Origin is not used in this base class, but it could be used in an override to direct people to a different level based on their exact position
/datum/level/proc/get_connected_level(var/direction, var/atom/origin = null)
	if (direction)
		if (connections["[direction]"])
			return connections["[direction]"]

	if (sealed)
		return null //You're not walking off the edge

	else
		//We are not sealed, but there's no connection, lets send them to empty space
		return get_empty_level()



//Called on the recieving zlevel when someone moves between levels.  Mover cannot be null
/datum/level/proc/get_landing_coords(var/atom/mover, var/direction = null,  var/method = ZMOVE_PHASE, var/datum/level/origin = null)
	var/vector2/destination = new /vector2(mover.x, mover.y)
	if (!mover)
		return null
	if (direction == UP || direction == DOWN)

		return destination
	else
		if (direction == NORTH)
			destination.y = (TRANSITIONEDGE +1)
		else if (direction == SOUTH)
			destination.y = world.maxy - (TRANSITIONEDGE +1)
		else if (direction == EAST)
			destination.x = (TRANSITIONEDGE +1)
		else if (direction == WEST)
			destination.x = world.maxx - (TRANSITIONEDGE +1)
		else
			return null //Should not happen

	return destination


//Wrapper for the above that returns a turf
/datum/level/proc/get_landing_point(var/atom/mover, var/direction = null,  var/method = ZMOVE_PHASE, var/datum/level/origin = null)
	var/vector2/coords = get_landing_coords(mover, direction, method, origin)
	return locate(coords.x, coords.y, z)




