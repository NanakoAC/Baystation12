/*
	This proc spawns a luminous overlay on the specified turf that deletes itself after a few seconds
*/
/obj/effect/debug_turf_marker
	alpha = 128
	plane = EFFECTS_ABOVE_LIGHTING_PLANE
	icon = 'icons/misc/debug_group.dmi'
	icon_state = "green"

/obj/effect/debug_turf_marker/New(var/loc, var/life = 20)
	.=..()
	QDEL_IN(src, life)

/proc/debug_mark_turf(var/turf/T, var/lifetime = 20)
	new /obj/effect/debug_turf_marker(T, lifetime)
