/datum/persistent/paper/sticky
	name = "stickynotes"
	paper_type = /obj/item/weapon/paper/sticky
	requires_noticeboard = FALSE


/datum/persistent/paper/sticky/GetValidTurf(var/list/tokens)
	return locate(tokens["x"], tokens["y"], tokens["z"])


/datum/persistent/paper/sticky/build_labels()
	..()
	LAZYADD(labels, "x")
	LAZYADD(labels, "y")
	LAZYADD(labels, "z")
	LAZYADD(labels, "offset_x")
	LAZYADD(labels, "offset_y")
	LAZYADD(labels, "color")

/datum/persistent/paper/sticky/CreateEntryInstance(var/turf/creating, var/list/tokens)
	var/atom/paper = ..()
	if(paper)
		paper.pixel_x = text2num(tokens["offset_x"])
		paper.pixel_y = text2num(tokens["offset_y"])
		paper.color =   tokens["color"]
	return paper

/datum/persistent/paper/sticky/CompileEntry(var/atom/entry, var/write_file)
	. = ..()
	var/obj/item/weapon/paper/sticky/paper = entry
	var/turf/T = get_turf(entry)
	LAZYADD(., T.x)					//, "x"
	LAZYADD(., T.y)					//, "y"
	LAZYADD(., T.z)					//, "z"
	LAZYADD(., "[paper.pixel_x]")	//"offset_x",
	LAZYADD(., "[paper.pixel_y]")	//"offset_y",
	LAZYADD(., "[paper.color]")		//"color",
