/*
	This function is called whenever an object enters a mirror turf and is moved to the reflection. It is called AFTER the moving is done

	Its a datum proc to cover any odd special cases (like airflow?)
*/
/datum/proc/crossed_seam()
	return

//When projectiles cross a seam, their target turf may change, as a mirror (or more likely, the real thing) is now closer
/obj/item/projectile/crossed_seam()
	var/curloc = get_turf(src)
	var/turf/T = get_nearest_mirror(curloc, original)
	redirect(T.x, T.y, curloc, firer)