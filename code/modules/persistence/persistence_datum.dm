// This is a set of datums instantiated by SSpersistence.
// They basically just handle loading, processing and saving specific forms
// of persistent data like graffiti and round to round filth.

/datum/persistent
	var/name
	var/filename
	//var/tokens_per_line
	var/entries_expire_at
	var/entries_decay_at
	var/entry_decay_weight = 0.5
	var/file_entry_split_character = "\t"
	var/file_entry_subsplit_character = "+"
	var/file_entry_substitute_character = " "
	var/file_line_split_character =  "\n"
	var/has_admin_data
	var/list/labels //Labels is a list which should be added to in the build_labels proc
	var/max_size = 1000000 //Maximum total number of characters that can be written to each file, intended to prevent abusive players from filling disk space
	//Any record that would push it over this size is simply discarded as are farther records
	var/current_size = 0 //Total size of data already written, reset when file is wiped.
		//during writing, this contains a running total.

/datum/persistent/New()

	SetFilename()
	..()


/datum/persistent/proc/Initialize()
	build_labels()

	if(fexists(filename))
		for(var/entry_line in file2list(filename, file_line_split_character))
			if(!entry_line)
				continue
			var/list/tokens = splittext(entry_line, file_entry_split_character)
			tokens = LabelTokens(tokens)
			if(!CheckTokenSanity(tokens))
				continue
			ProcessAndApplyTokens(tokens)

//Labels should be built here. Subclasses should always call parent first then add their own labels onto the end
/datum/persistent/proc/build_labels()
	LAZYADD(labels, "age")

/datum/persistent/proc/SetFilename()
	if(name)
		filename = "data/persistent/[lowertext(GLOB.using_map.name)]-[lowertext(name)].txt"
	if(!isnull(entries_decay_at) && !isnull(entries_expire_at))
		entries_decay_at = Floor(entries_expire_at * entries_decay_at)

/datum/persistent/proc/LabelTokens(var/list/tokens)
	var/list/labelled_tokens = list()
	var/index = 1
	for (var/a in labels)
		labelled_tokens[a] = tokens[index]
		index++
	return labelled_tokens

/datum/persistent/proc/GetValidTurf(var/list/tokens)
	return null
	//if(T && CheckTurfContents(T, tokens))
		//return T

/datum/persistent/proc/CheckTurfContents(var/turf/T, var/list/tokens)
	return TRUE

/datum/persistent/proc/CheckTokenSanity(var/list/tokens)
	if (!isnull(tokens["age"]))
		var/age = text2num(tokens["age"])
		if (age <= entries_expire_at )
			return TRUE

/datum/persistent/proc/CreateEntryInstance(var/turf/creating, var/list/tokens)
	return

/datum/persistent/proc/ProcessAndApplyTokens(var/list/tokens)

	//Increment the age whenever an instance is created. Note that here we're just incrementing a token value
	//It's still up to subclasses to apply this value to the created object
	if (isnum(tokens["age"]))
		var/newage = text2num(tokens["age"])
		tokens["age"] = "[newage+1]"
	CreateEntryInstance(GetValidTurf(tokens), tokens)

/datum/persistent/proc/IsValidEntry(var/atom/entry)
	if(!istype(entry))
		return FALSE
	if(GetEntryAge(entry) >= entries_expire_at)
		return FALSE
	var/turf/T = get_turf(entry)
	if(!T || !is_main_level(T.z) )
		return FALSE
	var/area/A = get_area(T)
	if(!A || (A.area_flags & AREA_FLAG_IS_NOT_PERSISTENT))
		return FALSE
	return TRUE

/datum/persistent/proc/GetEntryAge(var/atom/entry)
	return 0

/datum/persistent/proc/CompileEntry(var/atom/entry)
	LAZYADD(.,"[GetEntryAge(entry)]") //"age",



/datum/persistent/proc/Shutdown()
	write_data()



/datum/persistent/proc/write_data()
	if(fexists(filename))
		fdel(filename)
	current_size = 0
	var/write_file = file(filename)
	for(var/thing in SSpersistence.tracking_values[type])
		if(IsValidEntry(thing))

			var/list/data = CompileEntry(thing) //Data gathered from an atom, this may contain several sets of records
			var/next_size = list_text_length(data)
			if ((current_size + next_size) > max_size)
				log_debug("Warning: Persistence file [name] - [filename] exceeded max size. Writing terminated early.")
				return
			var/list/record = list() //Data for a single item
			for(var/i in data)
				if (i == file_entry_split_character) //Marks a division between multiple records in the data
					if (LAZYLEN(record))
						to_file(write_file, jointext(record, file_entry_split_character)) //We write then reset the current record
					record = list()
					continue

				i = replacetext(i, file_entry_split_character, file_entry_substitute_character)
				LAZYADD(record, i) //Add the thing to the record
			if (LAZYLEN(record))
				to_file(write_file, jointext(record, file_entry_split_character)) //Write the last (and possibly only) record to file
			current_size += next_size

/datum/persistent/proc/RemoveValue(var/atom/value)
	qdel(value)

/datum/persistent/proc/GetAdminSummary(var/mob/user, var/can_modify)
	. = list("<tr><td colspan = 4><b>[capitalize(name)]</b></td></tr>")
	. = "<tr><td colspan = 4><b>Size: [current_size]</b></td></tr>"
	. += "<tr><td colspan = 4><hr></td></tr>"
	for(var/thing in SSpersistence.tracking_values[type])
		. += "<tr>[GetAdminDataStringFor(thing, can_modify, user)]</tr>"
	. += "<tr><td colspan = 4><hr></td></tr>"


/datum/persistent/proc/GetAdminDataStringFor(var/thing, var/can_modify, var/mob/user)
	if(can_modify)
		. = "<td colspan = 3>[thing]</td><td><a href='byond://?src=\ref[src];caller=\ref[user];remove_entry=\ref[thing]'>Destroy</a></td>"
	else
		. = "<td colspan = 4>[thing]</td>"

/datum/persistent/Topic(var/href, var/href_list)
	. = ..()
	if(!.)
		if(href_list["remove_entry"])
			var/datum/value = locate(href_list["remove_entry"])
			if(istype(value))
				RemoveValue(value)
				. = TRUE
		if(.)
			var/mob/user = locate(href_list["caller"])
			if(user)
				SSpersistence.show_info(user)
