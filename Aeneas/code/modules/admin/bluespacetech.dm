/*
// Bluespace Technician is a godmode avatar designed for debugging and admin actions
// Their primary benefit is the ability to spawn in wherever you are, making it quick to get a human for your needs
// They also have incorporeal flying movement if they choose, which is often the fastest way to get somewhere specific
// They are mostly invincible, although godmode is a bit imperfect.
// Most of their superhuman qualities can be toggled off if you need a normal human for testing biological functions
//
// As the Aeneas setting does not have bluespace, the BST is replaced with Crazy Eddie, who is a more flexible IC tool.
// One might see Crazy Eddie in character, but nobody will believe you. Its the Looney Tunes pink elephant gag.
*/

#define TESTING 1
//ADMIN_VERB_ADD(/client/proc/cmd_dev_bst, R_ADMIN|R_DEBUG, TRUE)

/client/proc/cmd_dev_bst()
	set category = "Debug"
	set name = "Be Crazy Eddie"
	set desc = "Incarnate yourself as Crazy Eddie."

	if(!check_rights(R_ADMIN|R_DEBUG, C = src))
		return

	var/T = get_turf(mob)
	var/mob/living/carbon/human/bst/bst = new(T)
	bst.anchored = TRUE
	bst.ckey = ckey
	bst.name = "Crazy Eddie"
	bst.real_name = "Crazy Eddie"
	bst.voice_name = "Crazy Eddie"
	bst.gender = prefs.gender
	if (prefs.gender == MALE)
		bst.h_style = "Bedhead"
		bst.change_hair_color(220,220,200)
		bst.f_style = "7 O'clock Shadow and Moustache"
		bst.change_facial_hair_color(220,220,200)
		bst.equip_to_slot_or_del(new /obj/item/clothing/mask/smokable/pipe(bst), slot_wear_mask)
	else if (prefs.gender == FEMALE)
		bst.h_style = "Long Hair Alt 2"
		bst.change_hair_color(230,230,205)
		bst.equip_to_slot_or_del(new /obj/item/clothing/mask/smokable/cigarette/trident(bst), slot_wear_mask) // Ladylike.

	//Items
	bst.equip_to_slot_or_del(new /obj/item/clothing/under/serviceoveralls/bst(bst), slot_w_uniform)
	bst.equip_to_slot_or_del(new /obj/item/device/radio/headset/ert/bst(bst), slot_l_ear)
	bst.equip_to_slot_or_del(new /obj/item/weapon/storage/backpack/holding/bst(bst), slot_back)
	bst.equip_to_slot_or_del(new /obj/item/weapon/storage/box/survival(bst.back), slot_in_backpack)
	bst.equip_to_slot_or_del(new /obj/item/clothing/shoes/dutyboots/bst(bst), slot_shoes)
	bst.equip_to_slot_or_del(new /obj/item/clothing/head/hardhat/dblue(bst), slot_head)
	bst.equip_to_slot_or_del(new /obj/item/clothing/glasses/welding/bst(bst), slot_glasses)
	bst.equip_to_slot_or_del(new /obj/item/weapon/storage/belt/utility/full/bst(bst), slot_belt)
	bst.equip_to_slot_or_del(new /obj/item/clothing/gloves/thick/duty/bst(bst), slot_gloves)
	bst.equip_to_slot_or_del(new /obj/item/weapon/storage/box/ids(bst.back), slot_in_backpack)
	bst.equip_to_slot_or_del(new /obj/item/device/multitool(bst.back), slot_in_backpack)
	bst.equip_to_slot_or_del(new /obj/item/modular_computer/pda/captain(bst.back), slot_in_backpack)

	var/obj/item/weapon/storage/box/pills = new /obj/item/weapon/storage/box(null, TRUE)
	pills.name = "adminordrazine"
	for(var/i = 1, i < 12, i++)
		new /obj/item/weapon/reagent_containers/pill/adminordrazine(pills)
	bst.equip_to_slot_or_del(pills, slot_in_backpack)

	//Sort out ID
	var/obj/item/weapon/card/id/bst/id = new/obj/item/weapon/card/id/bst(bst)
	id.registered_name = bst.real_name
	id.assignment = "Mostly Harmless"
	id.name = "[id.assignment]"
	bst.equip_to_slot_or_del(id, slot_wear_id)
	bst.update_inv_wear_id()
	bst.regenerate_icons()

	//TODO:
	//Add the rest of the languages
	//bst.add_language(LANGUAGE_COMMON)

	spawn(10)
		bst_post_spawn(bst)

	log_admin("Crazy Eddie Spawned: X:[bst.x] Y:[bst.y] Z:[bst.z] User:[src]")
	return 1

/client/proc/bst_post_spawn(mob/living/carbon/human/bst/bst)
	var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
	s.set_up(5, 1, src)
	s.start()

	bst.anchored = FALSE

/mob/living/carbon/human/bst
	universal_understand = TRUE
	status_flags = GODMODE
	var/fall_override = TRUE
	var/mob/original_body = null

/mob/living/carbon/human/bst/can_inject(var/mob/user, var/error_msg, var/target_zone)
	user << span("alert", "[src] drunkenly stumbles away from you before you can inject them.")
	user.drop_item()
	return FALSE

/mob/living/carbon/human/bst/binarycheck()
	return TRUE

/mob/living/carbon/human/bst/proc/suicide()

	src.custom_emote(1,"touches a stray wire and, in a flurry of sparks, is gone.")
	var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
	s.set_up(5, 1, src)
	s.start()
	spawn(10)
		qdel(src)
	if(key)

		var/mob/observer/ghost/ghost = ghostize(TRUE)
		ghost.name = "[ghost.key] CrazyEddie"
		ghost.real_name = "[ghost.key] CrazyEddie"
		ghost.voice_name = "[ghost.key] CrazyEddie"
		ghost.admin_ghosted = TRUE

/mob/living/carbon/human/bst/verb/antigrav()
	set name = "Toggle Gravity"
	set desc = "Toggles falling for you."
	set category = "Crazy Eddie"

	if (fall_override)
		fall_override = FALSE
		src << SPAN_NOTICE("You will now fall normally.")
	else
		fall_override = TRUE
		src << SPAN_NOTICE("You will no longer fall.")

/mob/living/carbon/human/bst/verb/bstwalk()
	set name = "Break Immersion"
	set desc = "Stop pretending to be human and phase through solid matter."
	set category = "Crazy Eddie"
	set popup_menu = 0

	if(!HasMovementHandler(/datum/movement_handler/mob/incorporeal))
		src << SPAN_NOTICE("You will now phase through solid matter.")
		//incorporeal_move = TRUE
		ReplaceMovementHandler(/datum/movement_handler/mob/incorporeal)
	else
		src << SPAN_NOTICE("You will no longer phase through solid matter.")
		//incorporeal_move = FALSE
		RemoveMovementHandler(/datum/movement_handler/mob/incorporeal)

/mob/living/carbon/human/bst/verb/bstrecover()
	set name = "Revive"
	set desc = "Take a drink for medicinal purposes."
	set category = "Crazy Eddie"
	set popup_menu = FALSE

	src.custom_emote(1,"produces a hidden flask and swigs down something reeking of rocket fuel.")
	src.revive()

/mob/living/carbon/human/bst/verb/bstawake()
	set name = "Wake Up"
	set desc = "This is a quick fix to the relogging sleep bug."
	set category = "Crazy Eddie"
	set popup_menu = FALSE

	src.sleeping = FALSE

/mob/living/carbon/human/bst/verb/bstquit()
	set name = "Blink Out"
	set desc = "Go back to your day job (if you have one)."
	set category = "Crazy Eddie"

	src.suicide()

/mob/living/carbon/human/bst/verb/tgm()
	set name = "Toggle Godmode"
	set desc = "Enable or disable god mode. For testing things that require you to be vulnerable."
	set category = "Crazy Eddie"

	status_flags ^= GODMODE
	src << SPAN_NOTICE("God mode is now [status_flags & GODMODE ? "enabled" : "disabled"]")

	src << span("notice", "God mode is now [status_flags & GODMODE ? "enabled" : "disabled"].")


///////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////I T E M S/////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

/obj/item/weapon/storage/backpack/holding/bst
	//worn_access = TRUE

/obj/item/device/radio/headset/ert/bst
	name = "old headset"
	desc = "A dilapitated old headset. The letters 'CE' are suggested by chipped paint on the side."
	icon_state = "eng_headset_alt"
	item_state = "eng_headset_alt"
	translate_binary = TRUE

/obj/item/device/radio/headset/ert/bst/attack_hand()
	if(!usr)
		return
	if(!isbst(usr))
		usr << span("alert", "Your hand seems to go right through the headset. It's like it doesn't exist.")
		return
	else
		..()

/obj/item/device/radio/headset/ert/bst/recalculateChannels(var/setDescription = FALSE)
	..(setDescription)
	translate_binary = TRUE
	//translate_hive = TRUE

/obj/item/clothing/under/serviceoveralls/bst
	name = "ratty jumpsuit"
	desc = "A ratty set of work overalls. Someone embroidered the letters 'CE' into a pocket."
	has_sensor = FALSE
	sensor_mode = 0
	siemens_coefficient = 0
	cold_protection = FULL_BODY
	heat_protection = FULL_BODY

/obj/item/clothing/under/serviceoveralls/bst/attack_hand()
	if(!usr)
		return
	if(!isbst(usr))
		usr << span("alert", "Your hand seems to go right through the [src]. It's like it doesn't exist.")
		return
	else
		..()

/obj/item/clothing/gloves/thick/duty/bst
	name = "tattered leather gloves"
	desc = "A pair of genuine, if abused, letter gloves. Someone crudely stitched 'CE' into them."
	siemens_coefficient = 0
	permeability_coefficient = 0

/obj/item/clothing/gloves/thick/duty/bst/attack_hand()
	if(!usr)
		return
	if(!isbst(usr))
		usr << span("alert", "Your hand seems to go right through the [src]. It's like it doesn't exist.")
		return
	else
		..()

/obj/item/clothing/glasses/welding/bst
	name = "scratched welding goggles"
	desc = "A pair of welding goggles with enough tinting scuffed off to be dubiously effective."
	vision_flags = (SEE_TURFS|SEE_OBJS|SEE_MOBS)
	see_invisible = SEE_INVISIBLE_NOLIGHTING
	flash_protection = FLASH_PROTECTION_MAJOR

/obj/item/clothing/glasses/welding/bst/verb/toggle_xray(mode in list("X-Ray without Lighting", "X-Ray with Lighting", "Normal"))
	set name = "Change Vision Mode"
	set desc = "Changes your glasses' vision mode."
	set category = "Crazy Eddie"
	set src in usr

	switch (mode)
		if ("X-Ray without Lighting")
			vision_flags = (SEE_TURFS|SEE_OBJS|SEE_MOBS)
			see_invisible = SEE_INVISIBLE_NOLIGHTING
		if ("X-Ray with Lighting")
			vision_flags = (SEE_TURFS|SEE_OBJS|SEE_MOBS)
			see_invisible = -1
		if ("Normal")
			vision_flags = FALSE
			see_invisible = -1

	usr << "<span class='notice'>\The [src]'s vision mode is now <b>[mode]</b>.</span>"

/obj/item/clothing/glasses/welding/bst/attack_hand()
	if(!usr)
		return
	if(!isbst(usr))
		usr << span("alert", "Your hand seems to go right through the [src]. It's like it doesn't exist.")
		return
	else
		..()

/obj/item/clothing/shoes/dutyboots/bst
	name = "scuffed work boots"
	desc = "A pair of scuffed boots held together with sentimental hopes. The rubber sole has been worn slick."
	icon_state = "duty"
	//TODO: Enable noslip
	//item_flags = NOSLIP

/obj/item/clothing/shoes/dutyboots/bst/attack_hand()
	if(!usr)
		return
	if(!isbst(usr))
		usr << span("alert", "Your hand seems to go right through the [src]. It's like it doesn't exist.")
		return
	else
		..()

	return TRUE //Because Bluespace

/obj/item/weapon/card/id/bst
	icon_state = "centcom"
	desc = "An ID so old as to be held together with tape."

/obj/item/weapon/card/id/bst/New()
		access = get_all_accesses()+get_all_centcom_access()+get_all_syndicate_access()

/obj/item/weapon/card/id/bst/attack_hand()
	if(!usr)
		return
	if(!isbst(usr))
		usr << span("alert", "Your hand seems to go right through the [src]. It's like it doesn't exist.")
		return
	else
		..()

/obj/item/weapon/storage/belt/utility/full/bst

/obj/item/weapon/storage/belt/utility/full/bst/New()
	..()
	//new /obj/item/weapon/tool/multitool(src)
	new /obj/item/device/t_scanner(src)

/mob/living/carbon/human/bst/restrained()
	return !(status_flags & GODMODE)


/mob/living/carbon/human/bst/can_fall()
	return fall_override ? FALSE : ..()


//These are just wrappers on the standard move up/down verbs, duplicating them into the BST menu for easy clicking
/mob/living/carbon/human/bst/verb/moveup()
	set name = "Move Upwards"
	set category = "Crazy Eddie"
	up()
	//zMove(UP)

/mob/living/carbon/human/bst/verb/movedown()
	set name = "Move Downwards"
	set category = "Crazy Eddie"
	down()
	//zMove(DOWN)