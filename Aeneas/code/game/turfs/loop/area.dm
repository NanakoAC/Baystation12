/area/loop

//Loop areas should contain only mirror turfs. Mapping them in is most efficient but just in case
//On initialize, we'll make every turf in the area a mirror if it isnt already
/area/loop/Initialize()
	for (var/turf/T in contents)
		if (!T.is_mirror())
			T.ChangeTurf(/turf/mirror)

	SSmapping.all_loop_areas |= src
	.=..()

/*
	Called from level datum once its completed its initialization. This tells all the turfs to setup their reflections
*/
/area/loop/proc/find_reflections()
	for (var/turf/mirror/TM in contents)
		TM.find_reflection()
/*
Even though the mover is supposed to only be atom/movable, the change area proc passes in a turf when it calls Entered on an area.
This is not how its supposed to work, but its useful.
Whenever a turf is added to this area, lets turn it into a mirror if it isn't already
*/
/area/loop/Entered(var/mover,var/oldloc)
	if (istype(mover, /turf))
		var/turf/T = mover
		if (!T.is_mirror())
			T.ChangeTurf(/turf/mirror)
			return
	.=..()


/area/loop/north
	icon_state = "loop_north"

/area/loop/south
	icon_state = "loop_south"

/area/loop/east
	icon_state = "loop_east"

/area/loop/west
	icon_state = "loop_west"

/area/loop/northwest
	icon_state = "loop_northwest"

/area/loop/northeast
	icon_state = "loop_northeast"

/area/loop/southwest
	icon_state = "loop_southwest"

/area/loop/southeast
	icon_state = "loop_southeast"