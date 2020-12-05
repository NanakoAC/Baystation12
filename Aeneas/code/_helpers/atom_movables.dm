/proc/get_turf_pixel(atom/movable/AM)
	if(!istype(AM))
		return

	//Find AM's matrix so we can use it's X/Y pixel shifts
	var/matrix/M = matrix(AM.transform)

	var/pixel_x_offset = AM.pixel_x + M.get_x_shift()
	var/pixel_y_offset = AM.pixel_y + M.get_y_shift()

	//Irregular objects
	if(AM.bound_height != world.icon_size || AM.bound_width != world.icon_size)
		var/icon/AMicon = icon(AM.icon, AM.icon_state)
		pixel_x_offset += ((AMicon.Width()/world.icon_size)-1)*(world.icon_size*0.5)
		pixel_y_offset += ((AMicon.Height()/world.icon_size)-1)*(world.icon_size*0.5)
		qdel(AMicon)

	//DY and DX
	var/rough_x = round(round(pixel_x_offset,world.icon_size)/world.icon_size)
	var/rough_y = round(round(pixel_y_offset,world.icon_size)/world.icon_size)

	//Find coordinates
	var/turf/T = get_turf(AM) //use AM's turfs, as it's coords are the same as AM's AND AM's coords are lost if it is inside another atom
	var/final_x = T.x + rough_x
	var/final_y = T.y + rough_y

	if(final_x || final_y)
		return locate(final_x, final_y, T.z)

// Walks up the loc tree until it finds a holder of the given holder_type
/proc/get_holder_of_type(atom/A, holder_type)
	if(!istype(A)) return
	for(A, A && !istype(A, holder_type), A=A.loc);
	return A

/atom/movable/proc/throw_at_random(var/include_own_turf, var/maxrange, var/speed)
	var/list/turfs = trange(maxrange, src)
	if(!maxrange)
		maxrange = 1

	if(!include_own_turf)
		turfs -= get_turf(src)
	src.throw_at(pick(turfs), maxrange, speed, src)

/atom/movable/proc/do_simple_ranged_interaction(var/mob/user)
	return FALSE

/atom/movable/hitby(var/atom/movable/AM)
	..()
	if(density && prob(50))
		do_simple_ranged_interaction()

//Used to allow atoms to move seamlessly across map loop edges, a wrapper for step proc
/proc/seamless_step(var/atom/movable/mover, var/direction)
	//First of all, find out where we're actually going
	var/turf/destination = get_step(mover, direction)

	//If the destination turf isn't a mirror, we don't need to do anything special.
	//Not sure when we'd fail to get any turf, but in that case just let default behaviour handle it too
	if (!destination || !destination.is_mirror())
		return step(mover, direction)

	//Ok, we're trying to step into a mirror turf, this is where things get tricky.
	//First cache our old loc
	var/turf/old_location = get_turf(mover)

	//Rather than stepping into the mirror, what we will do is teleport the atom next to the real destination turf, and then step into it.
	var/reverse_direction = GLOB.reverse_dir[direction]
	var/turf/true_destination = destination.get_self() //Get self returns the real turf, when used on a mirror
	var/turf/step_from = get_step(true_destination, reverse_direction) //We find the appropriate turf next to our destination.
	//	This will usually be a mirror but not necessarily, it doesn't matter either way

	mover.loc = step_from //We teleport the atom by directly setting its loc. This ensures that no enter/exit procs are called
		//As far as most things are concerned, we haven't moved yet. The surroundings will look identical to where we left

	.=step(mover, direction)
	//.=mover.Move(true_destination, direction) //Then we take a step, this will handle all the events that come with a move as normal
	if (!.)
		//If we failed to move, quietly put us back where we started, as if it never happened
		mover.loc = old_location
		return
	else
		//We have successfully moved, we may now do an animation to make it appear seamless
		//But first, lets check if we even need to do an animation. We'll check the glide size
		var/_time = GLIDESIZE2DELAY(mover.glide_size)

		//First of all, record current pixel offsets of the mover
		var/vector2/pixels = new /vector2(mover.pixel_x, mover.pixel_y)
		var/vector2/client_pixels = new /vector2(mover.pixel_x, mover.pixel_y)


		//Fetch the client if possible, we need to animate that so that the camera tracks the mob as it walks.
		//If we don't animate the client too, the view jumps forward jarringly
		var/client/C  = mover.get_client() //We use get mob which will return players inside vehicles too

		if (istype(C))
			client_pixels.x = C.pixel_x
			client_pixels.y = C.pixel_y

		//Next we'll offset the mover's pixels visually into the tile they just came from
		mover.offset_dir(reverse_direction, world.icon_size)
		if (C)
			//We can offset client too
			C.offset_dir(reverse_direction, world.icon_size)

		//Then we'll animate them sliding into the new tile they've just entered, setting their pixel offsets back to what they were a second ago
		animate(mover, pixel_x = pixels.x, pixel_y = pixels.y, time = _time)
		if (C)
			//Also animate client for smooth camera
			animate(C, pixel_x = client_pixels.x, pixel_y = client_pixels.y, time = _time)