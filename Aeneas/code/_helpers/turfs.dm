// Returns the atom sitting on the turf.
// For example, using this on a disk, which is in a bag, on a mob, will return the mob because it's on the turf.
/proc/get_atom_on_turf(var/atom/movable/M)
	var/atom/mloc = M
	while(mloc && mloc.loc && !istype(mloc.loc, /turf/))
		mloc = mloc.loc
	return mloc

/proc/turf_clear(turf/T)
	for(var/atom/A in T)
		if(A.simulated)
			return 0
	return 1

// Picks a turf without a mob from the given list of turfs, if one exists.
// If no such turf exists, picks any random turf from the given list of turfs.
/proc/pick_mobless_turf_if_exists(var/list/start_turfs)
	if(!start_turfs.len)
		return null

	var/list/available_turfs = list()
	for(var/start_turf in start_turfs)
		var/mob/M = locate() in start_turf
		if(!M)
			available_turfs += start_turf
	if(!available_turfs.len)
		available_turfs = start_turfs
	return pick(available_turfs)

/proc/get_random_turf_in_range(var/atom/origin, var/outer_range, var/inner_range)
	origin = get_turf(origin)
	if(!origin)
		return
	var/list/turfs = list()
	for(var/turf/T in physical_orange(outer_range, origin))
		if(!(T.z in GLOB.using_map.sealed_levels)) // Picking a turf outside the map edge isn't recommended
			if(T.x >= world.maxx-TRANSITIONEDGE || T.x <= TRANSITIONEDGE)	continue
			if(T.y >= world.maxy-TRANSITIONEDGE || T.y <= TRANSITIONEDGE)	continue
		if(!inner_range || get_physical_dist(origin, T) >= inner_range)
			turfs += T
	if(turfs.len)
		return pick(turfs)

/proc/screen_loc2turf(text, turf/origin)
	if(!origin)
		return null
	var/tZ = splittext(text, ",")
	var/tX = splittext(tZ[1], "-")
	var/tY = text2num(tX[2])
	tX = splittext(tZ[2], "-")
	tX = text2num(tX[2])
	tZ = origin.z
	tX = max(1, min(origin.x + 7 - tX, world.maxx))
	tY = max(1, min(origin.y + 7 - tY, world.maxy))
	return locate(tX, tY, tZ)

/*
	Predicate helpers
*/

/proc/is_space_turf(var/turf/T)
	return istype(T, /turf/space)

/proc/is_not_space_turf(var/turf/T)
	return !is_space_turf(T)

/proc/is_holy_turf(var/turf/T)
	return T && T.holy

/proc/is_not_holy_turf(var/turf/T)
	return !is_holy_turf(T)

/proc/turf_contains_dense_objects(var/turf/T)
	return T.contains_dense_objects()

/proc/not_turf_contains_dense_objects(var/turf/T)
	return !turf_contains_dense_objects(T)

/proc/is_station_turf(var/turf/T)
	return T && is_main_level(T.z)

/proc/has_air(var/turf/T)
	return !!T.return_air()

/proc/IsTurfAtmosUnsafe(var/turf/T)
	if(istype(T, /turf/space)) // Space tiles
		return "Spawn location is open to space."
	var/datum/gas_mixture/air = T.return_air()
	if(!air)
		return "Spawn location lacks atmosphere."
	return get_atmosphere_issues(air, 1)

/proc/IsTurfAtmosSafe(var/turf/T)
	return !IsTurfAtmosUnsafe(T)

/proc/is_below_sound_pressure(var/turf/T)
	var/datum/gas_mixture/environment = T ? T.return_air() : null
	var/pressure =  environment ? environment.return_pressure() : 0
	if(pressure < SOUND_MINIMUM_PRESSURE)
		return TRUE
	return FALSE

/*
	Turf manipulation
*/

//Returns an assoc list that describes how turfs would be changed if the
//turfs in turfs_src were translated by shifting the src_origin to the dst_origin
/proc/get_turf_translation(turf/src_origin, turf/dst_origin, list/turfs_src)
	var/list/turf_map = list()
	for(var/turf/source in turfs_src)
		var/x_pos = (source.x - src_origin.x)
		var/y_pos = (source.y - src_origin.y)
		var/z_pos = (source.z - src_origin.z)

		var/turf/target = locate(dst_origin.x + x_pos, dst_origin.y + y_pos, dst_origin.z + z_pos)
		if(!target)
			error("Null turf in translation @ ([dst_origin.x + x_pos], [dst_origin.y + y_pos], [dst_origin.z + z_pos])")
		turf_map[source] = target //if target is null, preserve that information in the turf map

	return turf_map


/proc/translate_turfs(var/list/translation, var/area/base_area = null, var/turf/base_turf)
	for(var/turf/source in translation)

		var/turf/target = translation[source]

		if(target)
			if(base_area)
				ChangeArea(target, get_area(source))
				ChangeArea(source, base_area)
			transport_turf_contents(source, target)

	//change the old turfs
	for(var/turf/source in translation)
		source.ChangeTurf(base_turf ? base_turf : get_base_turf_by_area(source), 1, 1)

//Transports a turf from a source turf to a target turf, moving all of the turf's contents and making the target a copy of the source.
/proc/transport_turf_contents(turf/source, turf/target)

	var/turf/new_turf = target.ChangeTurf(source.type, 1, 1)
	new_turf.transport_properties_from(source)

	for(var/obj/O in source)
		if(O.simulated)
			O.forceMove(new_turf)
		else if(istype(O,/obj/effect))
			var/obj/effect/E = O
			if(E.movable_flags & MOVABLE_FLAG_EFFECTMOVE)
				E.forceMove(new_turf)

	for(var/mob/M in source)
		if(isEye(M)) continue // If we need to check for more mobs, I'll add a variable
		M.forceMove(new_turf)

	return new_turf

//Figures out if we've crossed the transition zone and which direction we're about to leave this map in
//Cardinal only, no diagonals for now
/proc/get_crossed_world_edge(var/vector2/position)
	var/direction = null
	if(position.x <= TRANSITIONEDGE)
		direction = WEST

	else if (position.x >= (world.maxx - TRANSITIONEDGE + 1))
		direction = EAST

	else if (position.y <= TRANSITIONEDGE)
		direction = SOUTH

	else if (position.y >= (world.maxy - TRANSITIONEDGE + 1))
		direction = NORTH

	return direction


/*
	Wrapper for get_step which is used for anything that shouldn't notice loop boundaries.
*/
/proc/get_physical_step(Ref,Dir)
	var/turf/T = get_step(Ref, Dir)
	if (T)
		return T.get_self()


/*
	This does a physical orange call to find turfs adjacent to the origin which match the specified type.
	The resulting turfs are returned in an associative list, formatted like

	turf = direction

	This is used in floor/wall icons
*/
/proc/get_adjacent_turfs(var/atom/origin, var/required_type = /turf)
	var/list/turfs = list()
	for (var/direction in GLOB.alldirs)
		var/T = get_physical_step(origin, direction)
		if (istype(T, required_type))
			turfs[T] = direction

	return turfs


/*
	Updates all walls and floors around this turf
	This is lazy and a bit inefficient and a bit excessive, its not an ideal function for many cases.
	But it is thorough. The intention here is to hit every reasonable use case.
	Where possible, more precise/targeted updating should be done, but this is handy if you're unsure

	Origin doesnt need to be a turf
*/
/proc/update_adjacent_turfs(var/origin)
	var/turf/T = get_turf(origin)
	var/list/turfs = trange(1, T)
	turfs -= T
	for (var/turf/simulated/wall/W in turfs)
		W.update_connections(0)
		W.update_icon()

	for (var/turf/simulated/floor/F in turfs)
		F.update_icon()


/*
	Finds the physical distance between two turfs. It does this by comparing the distance from origin, to the target turf, AND to all mirrors of the target turf
	We will not check mirrors of origin, we assume origin is always a physical turf
*/
/proc/get_physical_dist(var/turf/origin, var/turf/target)
	if (!istype(origin))
		origin = get_turf(origin)
	if (!istype(target))
		target = get_turf(target)

	var/shortest = get_dist(origin, target)
	var/newdist
	if (!target) //If target is null, we'll just return whatever get_dist gave us
		return shortest
	for (var/turf/T in target.mirrors)
		newdist = get_dist(origin, T)
		if (newdist < shortest)
			shortest = newdist

	return shortest

/*
	As above, but returns a vector2 position delta instead of a length
*/
/proc/get_physical_vector_offset(var/turf/origin, var/turf/target)
	if (!istype(origin))
		origin = get_turf(origin)
	if (!istype(target))
		target = get_turf(target)

	var/shortest = get_dist(origin, target)
	var/vector2/shortest_vec = new /vector2(target.x - origin.x, target.y - origin.y)
	var/newdist
	for (var/turf/T in target.mirrors)
		newdist = get_dist(origin, T)
		if (newdist < shortest)
			shortest = newdist
			shortest_vec.x = T.x - origin.x
			shortest_vec.y = T.y - origin.y

	return shortest_vec

/*
	Similar to the above, this one returns the actual mirror turf which is closest
*/
/proc/get_nearest_mirror(var/turf/origin, var/turf/target)
	if (!istype(origin))
		origin = get_turf(origin)
	target = get_turf(target)
	target = target.get_self()
		//Get self will ensure that if the target was a mirror, we get its original
		//This helps for cases where this function is repeatedly called with a mirror as target, like with throwing


	var/shortest = get_dist(origin, target)
	var/nearest = target
	var/newdist
	for (var/turf/T in target.mirrors)
		newdist = get_dist(origin, T)
		if (newdist < shortest)
			shortest = newdist
			nearest = T

	return nearest

/*
	Takes a direction, and returns a vector with axes in the range -1 to 1
*/
/proc/direction_to_vector(var/direction)
	var/vector2/vecdir = new /vector2(0,0)

	if(direction & NORTH)
		vecdir.y = 1
	if(direction & SOUTH)
		vecdir.y = -1
	if(direction & EAST)
		vecdir.x = 1
	if(direction & WEST)
		vecdir.x = -1

