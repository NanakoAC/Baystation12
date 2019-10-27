/datum/controller/subsystem/persistence/var/list/noticeboards = list() //A list on the persistence controller to host noticeboards

/datum/persistent/paper/noticeboard
	name = "pinned notices"


/datum/persistent/paper/noticeboard/GetValidTurf(var/list/tokens)
	var/obj/structure/noticeboard/N = LAZYACCESS(SSpersistence.noticeboards, tokens["board_id"])
	if (N)
		return get_turf(N)


/datum/persistent/paper/noticeboard/build_labels()
	..()
	LAZYADD(labels, "board_id")

/datum/persistent/paper/noticeboard/CreateEntryInstance(var/turf/creating, var/list/tokens)
	.=..()
	//Find our noticeboard
	var/obj/structure/noticeboard/N = locate() in creating

	//Now we need to get the toplevel.
	//This will be the paper itself if it's alone
	//Or it'll be a folder or bundle if it's inside one of those
	var/atom/holder = get_atom_on_turf(.)

	//Holder could also be ourselves if this is a second piece of paper added to a bundle or folder on this board
	if (holder != N)
		//And pin it to the noticeboard
		N.add_paper(holder)


/datum/persistent/paper/noticeboard/CompileEntry(var/atom/entry, var/write_file)
	. = ..()
	if (istype(entry,/obj/item/weapon/paper))
		var/obj/structure/noticeboard/N = get_atom_on_turf(entry)
		if (istype(N))
			LAZYADD(.,  "[N.board_id]")//"board_id",
