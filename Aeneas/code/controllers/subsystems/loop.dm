//Initializes relatively late in subsystem init order.
SUBSYSTEM_DEF(loop)
	name = "Looping"
	init_order = SS_INIT_LOOP
	flags = SS_NO_FIRE

/datum/controller/subsystem/loop/Initialize()
	//Initializing loop areas. This has to be done after both mapping and atoms, here fits.
	for (var/area/loop/L in SSmapping.all_loop_areas)
		L.find_reflections()
	. = ..()