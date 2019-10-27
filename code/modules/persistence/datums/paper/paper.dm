/*
	Base class for paper. This should not be used as is. It contains no locational information.

	A subclass should be made for each possible type of place/method that paper may be stored
*/

/datum/persistent/paper
	name = "paper"
	entries_expire_at = 5
	has_admin_data = TRUE
	var/paper_type = /obj/item/weapon/paper
	var/requires_noticeboard = TRUE

	//Lists of folders and paper bundles we've created to hold newly spawned sheets
	var/list/folders = list()
	var/list/bundles = list()

/datum/persistent/paper/build_labels()
	..()
	LAZYADD(labels, "author")
	LAZYADD(labels, "message")
	LAZYADD(labels, "title")
	LAZYADD(labels, "container") //Container is a string that will be empty for single sheets, and start with F or B if the sheet was in a folder or bundle

/datum/persistent/paper/CheckTurfContents(var/turf/T, var/list/tokens)
	if(requires_noticeboard && !(locate(/obj/structure/noticeboard) in T))
		new /obj/structure/noticeboard(T)
	. = ..()

/datum/persistent/paper/CreateEntryInstance(var/turf/creating, var/list/tokens)
	//var/obj/structure/noticeboard/board = locate() in creating
	//if(requires_noticeboard && LAZYLEN(board.notices) >= board.max_notices)
		//return
	var/obj/item/weapon/paper/paper = new paper_type(creating)
	paper.set_content(tokens["message"], tokens["title"])
	paper.last_modified_ckey = tokens["author"]
	paper.age = text2num(tokens["age"])


	//If any container is needed, then lets find or make it and put the paper in
	if (tokens["container"])
		var/list/params = splittext(tokens["container"], file_entry_subsplit_character)
		if (params[1] == "F") //If it needs a folder
			var/obj/item/weapon/folder/F = folders[tokens["container"]] //Lets see if we already made a suitable folder
			if (!istype(F))
				//Folder doesnt exist yet, lets make it!
				F = new(creating)
				F.icon_state = params[2] //Set the icon state to whatever was recorded
				F.name = params[3]
				folders[tokens["container"]] = F //And cache it in the folders list

			//Now we have a folder, stick our new paper inside it
			paper.forceMove(F)
			F.update_icon()
		else if (params[1] == "B") //If it needs a bundle
			var/obj/item/weapon/paper_bundle/B = bundles[tokens["container"]] //Lets see if we already made a suitable bundle
			if (!istype(B))
				//Bundle doesnt exist yet, lets make it!
				B = new(creating)
				B.name = params[2]
				bundles[tokens["container"]] = B //And cache it in the folders list

			//Now we have a bundle, stick our new paper inside it
			B.insert_sheet_at(null, null, paper)
			B.update_icon()



	//if(requires_noticeboard)
		//board.add_paper(paper)
	//SSpersistence.track_value(paper, type)
	return paper

/datum/persistent/paper/GetEntryAge(var/atom/entry)
	if (istype(entry,/obj/item/weapon/paper))
		var/obj/item/weapon/paper/paper = entry
		return paper.age
	return 0

/datum/persistent/paper/CompileEntry(var/atom/entry, var/write_file)
	if (istype(entry,/obj/item/weapon/paper))
		var/obj/item/weapon/paper/paper = entry
		. = ..() //We call parent only for individual paper sheets
		LAZYADD(., "[paper.last_modified_ckey ? paper.last_modified_ckey : "unknown"]") //"author",
		LAZYADD(., "[paper.info]") //"message",
		LAZYADD(., "[paper.name]") //"title",
		//If the paper is in a bundle or folder, we need to set its container field
		if (istype(paper.loc, /obj/item/weapon/folder))
			var/obj/item/weapon/folder/F = paper.loc
			//We'll make a deterministic folder ID from F, iconstate, and the reference
			LAZYADD(., "F[file_entry_subsplit_character][F.icon_state][file_entry_subsplit_character][F.name][file_entry_subsplit_character]\ref[F]") //"container",

		else if (istype(paper.loc, /obj/item/weapon/paper_bundle))
			var/obj/item/weapon/paper_bundle/B = paper.loc
			LAZYADD(.,"B[file_entry_subsplit_character][B.name][file_entry_subsplit_character]\ref[B]") //"container",
		else
			LAZYADD(., "") //No container, add an empty ID
	//For folders and paper bundles, we add each individual sheet to the data as a seperate record
	else if (istype(entry, /obj/item/weapon/folder) || istype(entry, /obj/item/weapon/paper_bundle))
		for (var/obj/item/weapon/paper/P in entry.contents)
			. += CompileEntry(P, write_file)
			. += file_entry_split_character //Throw in a special character to indicate that's the end of one record

/datum/persistent/paper/GetAdminDataStringFor(var/thing, var/can_modify, var/mob/user)
	var/obj/item/weapon/paper/paper = thing
	if(can_modify)
		. = "<td style='background-color:[paper.color]'>[paper.info]</td><td>[paper.name]</td><td>[paper.last_modified_ckey]</td><td><a href='byond://?src=\ref[src];caller=\ref[user];remove_entry=\ref[thing]'>Destroy</a></td>"
	else
		. = "<td colspan = 2;style='background-color:[paper.color]'>[paper.info]</td><td>[paper.name]</td><td>[paper.last_modified_ckey]</td>"

/datum/persistent/paper/RemoveValue(var/atom/value)
	var/obj/structure/noticeboard/board = value.loc
	if(istype(board))
		board.remove_paper(value)
	qdel(value)


/datum/persistent/paper/ProcessAndApplyTokens(var/list/tokens)
	.=..()
	// If it's old enough we start to trim down any textual information and scramble strings.
	if(tokens["message"] && !isnull(entries_decay_at) && !isnull(entry_decay_weight))
		var/_n =       tokens["age"]
		var/_message = tokens["message"]
		if(_n >= entries_decay_at)
			var/decayed_message = ""
			for(var/i = 1 to length(_message))
				var/char = copytext(_message, i, i + 1)
				if(prob(round(_n * entry_decay_weight)))
					if(prob(99))
						decayed_message += pick(".",",","-","'","\\","/","\"",":",";")
				else
					decayed_message += char
			_message = decayed_message
		if(length(_message))
			tokens["message"] = _message
		else
			return