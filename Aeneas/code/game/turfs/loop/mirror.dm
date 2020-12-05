/*
	A mirror turf is a visual-only turf which completely reflects the state of another real turf somewhere.
	Every interaction with a mirror turf is passed to the real one. This includes:
		Any atom entering it is instantly moved to the real
		Any attempt to fetch its contents, gets the real contents
		Any attempt to get a turf a its coordinates, gets the real turf
*/
/turf/mirror
	var/turf/reflection	//The real turf that we're reflecting
	var/vector2/reflection_coords
	dynamic_lighting = FALSE
	permit_ao = FALSE

//Slightly hacky prototype for mirror movement
/turf/mirror/Entered(var/atom/movable/mover, var/atom/old_loc)
	if (reflection && !ismirror(old_loc))
		mover.loc = reflection
		.= reflection.Entered(mover, old_loc)
		mover.crossed_seam()
		return

	.=..()

//Returns true if this is a mirror turf
/turf/proc/is_mirror()
	return FALSE

/turf/mirror/is_mirror()
	return TRUE


/turf/mirror/proc/find_reflection()
	var/datum/level/L = get_level_from_z(z)
	if (!L)
		log_world("Error: Turf located at [jumplink(src)] failed to find associated level")
		return

	//Here we use wrap to place the reflection within the play area. Its a cool math thing that i'm not sure how to explain
	//We pass in +1 to the upper bounds because for some reason wrap is inclusive at lower end but exclusive at upper end
	reflection_coords = new /vector2(Wrap(x, L.bounds_lower.x, L.bounds_upper.x+1), Wrap(y, L.bounds_lower.y, L.bounds_upper.y+1))
	reflection = locate(reflection_coords.x, reflection_coords.y, z)

	if (istype(reflection))
		LAZYADD(reflection.mirrors, src)

	//We need to sync our opacity
	GLOB.opacity_set_event.register(reflection, src, /turf/mirror/proc/synchronise)

	update_icon()
	synchronise()

/turf/mirror/update_icon()
	vis_contents |= reflection
	icon_state = "transparent"
	update_adjacent_turfs(src)

//Critical proc, returns the reflection where other turfs would return themselves
/turf/mirror/get_self()
	return reflection

/turf/mirror/get_contents(var/includeself)
	if (reflection)
		return reflection.get_contents(includeself)
	return list() //It never includes itself in the return value

//Mirror turfs don't do atmos. Calls to update it are passed to the reflection if applicable
/turf/mirror/update_air_properties()
	if (reflection)
		reflection.update_air_properties()

//Copies over certain properties from the reflection
/turf/mirror/proc/synchronise()
	if (!reflection) //This should never happen
		find_reflection()

	if (!reflection)
		return

	opacity = reflection.opacity