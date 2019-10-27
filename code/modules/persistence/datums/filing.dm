/*
	This file handles longterm persistent document storage.
	Generally, this means filing cabinets in offices
*/


/datum/controller/subsystem/persistence/var/list/filing_cabinets = list() //A list on the persistence controller to host noticeboards

/datum/persistent/paper/filing

/datum/persistent/paper/filing
	name = "filed documents"


/datum/persistent/paper/filing/GetValidTurf(var/list/tokens)
	var/obj/structure/filingcabinet/N = LAZYACCESS(SSpersistence.filing_cabinets, tokens["filing_id"])
	if (N)
		return get_turf(N)


/datum/persistent/paper/filing/build_labels()
	..()
	LAZYADD(labels, "filing_id")

/datum/persistent/paper/filing/CreateEntryInstance(var/turf/creating, var/list/tokens)
	.=..()
	//Find our cabinet
	var/obj/structure/filingcabinet/N = locate() in creating

	//Now we need to get the toplevel.
	//This will be the paper itself if it's alone
	//Or it'll be a folder or bundle if it's inside one of those
	var/atom/holder = get_atom_on_turf(.)

	//Holder could also be ourselves if this is a second piece of paper added to a bundle or folder on this board
	if (holder != N)
		//And pin it to the noticeboard
		N.insert_item(holder)


/datum/persistent/paper/filing/CompileEntry(var/atom/entry, var/write_file)
	. = ..()
	if (istype(entry,/obj/item/weapon/paper))
		var/obj/structure/filingcabinet/N = get_atom_on_turf(entry)
		if (istype(N))
			LAZYADD(.,  "[N.filing_id]")//"filing_id",
