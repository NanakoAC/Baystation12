/obj/item/device/oxycandle
	name = "oxygen candle"
	desc = "A steel can with the words 'EMERGENCY OXYGEN - Remove pin and place on heat-resistant surface.' stenciled on the side.\nA small label reads <span class='warning'>'WARNING: FIRE HAZARD.'</span>"
	icon = 'icons/obj/device.dmi'
	icon_state = "oxycandle"
	item_state = "oxycandle"
	w_class = ITEM_SIZE_SMALL // Should fit into internal's box or maybe pocket
	var/target_pressure = ONE_ATMOSPHERE
	var/datum/gas_mixture/air_contents = null
	var/volume = 4600
	var/on = 0
	var/activation_sound = 'sound/effects/flare.ogg'
	light_color = "#e58775"
	light_outer_range = 2
	light_max_bright = 1
	var/brightness_on = 1 // Moderate-low bright.
	var/rigged = 0
	action_button_name = null

/obj/item/device/oxycandle/New()
	..()
	update_icon()

/obj/item/device/oxycandle/afterattack(var/obj/O, var/mob/user, var/proximity)
	if(proximity && istype(O) && on)
		O.HandleObjectHeating(src, user, 500)
	..()

// Nikov here. When I originally suggested these to Aurora, I had a feature in mind they wouldn't add.
//
// A moment, please.
//
//	Wednesday, 21 March 2007
//	HMS Tireless, nuclear submarine, submerged, North Polar icecap, explosion and fire on board
//	HUNTROD, Anthony, Ordnance Electrical Mechanic (O.E.M.) (W) 2c, D216007R, accident
//	MCCANN, Paul , Leading Operator Mechanic (W), D252555M, accident
//
// As you were.

/obj/item/device/oxycandle/attackby(var/obj/item/I, var/mob/user)
	..()
	if(istype(I, /obj/item/weapon/reagent_containers/syringe))
		var/obj/item/weapon/reagent_containers/syringe/S = I

		to_chat(user, "You inject the solution into the [src].")

		if(S.reagents.has_reagent(/datum/reagent/fuel, 5))	// Contamination by hydraulic oil caused the HMS Tireless explosion.

			to_chat(user, "Sodium chlorate and hydrocarbon fuel, what could go wrong...")
			log_and_message_admins("injected an oxygen candle with fuel, rigging it to explode.", user)
			rigged = 1

		S.reagents.clear_reagents()

		if(S.reagents.has_reagent(/datum/reagent/acid, 5))	// This would probably cause an instant reaction, but who cares.

			to_chat(user, "You'll need to update that warning label.")
			log_and_message_admins("injected an oxygen candle with acid, rigging it to explode.", user)
			rigged = 1

		S.reagents.clear_reagents()
	else
		..()
	return

/obj/item/device/oxycandle/attack_self(mob/user)
	if(!on && !rigged)
		to_chat(user, "<span class='notice'>You pull the pin and [src] ignites.</span>")
		on = 1
		update_icon()
		playsound(src.loc, activation_sound, 75, 1)
		air_contents = new /datum/gas_mixture()
		air_contents.volume = 200 //liters
		air_contents.temperature = T20C + 80	// Fire is hot. IRL these are more like 600 degrees.
		var/list/air_mix = list(GAS_OXYGEN = 1 * (target_pressure * air_contents.volume) / (R_IDEAL_GAS_EQUATION * air_contents.temperature))
		air_contents.adjust_multi(GAS_OXYGEN, air_mix[GAS_OXYGEN])
		START_PROCESSING(SSprocessing, src)
	if(!on && rigged)
		to_chat(user, "<span class='notice'>You pull the pin and [src] ignites.</span>")
		on = 1
		update_icon()
		playsound(src.loc, activation_sound, 75, 1)
		sleep(10)
		var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
		s.set_up(5, 1, src)
		s.start()
		to_chat(user, "<span class='warning'>Sparks spray from the candle!</span>")
		sleep(20)	// Frag out!
		var/turf/T = get_turf(src.loc)
		spawn(0)
			explosion(T, 0, 1, 3, 5)
			log_and_message_admins("Rigged oxygen candle explosion, last touched by [fingerprintslast]. Check logs for who rigged it as they may be the victim of a tricky trap.") // Staff can be dumb, you know.
			sleep(1)
			qdel(src)
		on = 2
		update_icon()
	else
		..()
	return

// Process of Oxygen candles releasing air. Makes 200 volume of oxygen
/obj/item/device/oxycandle/Process()
	if(!loc)
		return
	var/turf/pos = get_turf(src)
	if(volume <= 0 || !pos || (pos.turf_flags & TURF_IS_WET)) //Now uses turf flags instead of whatever aurora did
		STOP_PROCESSING(SSprocessing, src)
		on = 2
		update_icon()
		update_held_icon()
		SetName("burnt oxygen candle")
		desc += "All of the chemical filler has smoldered away."
		return
	if(pos)
		pos.hotspot_expose(1500, 5)
	var/datum/gas_mixture/environment = loc.return_air()
	var/pressure_delta = target_pressure - environment.return_pressure()
	var/output_volume = environment.volume * environment.group_multiplier
	var/air_temperature = air_contents.temperature? air_contents.temperature : environment.temperature
	var/transfer_moles = pressure_delta*output_volume/(air_temperature * R_IDEAL_GAS_EQUATION)
	var/datum/gas_mixture/removed = air_contents.remove(transfer_moles)
	if (!removed) //Just in case
		return
	environment.merge(removed)
	volume -= 200
	var/list/air_mix = list(GAS_OXYGEN = 1 * (target_pressure * air_contents.volume) / (R_IDEAL_GAS_EQUATION * air_contents.temperature))
	air_contents.adjust_multi(GAS_OXYGEN, air_mix[GAS_OXYGEN])

/obj/item/device/oxycandle/on_update_icon()
	if(on == 1)
		icon_state = "oxycandle_on"
		item_state = icon_state
		set_light(brightness_on)
	else if(on == 2)
		icon_state = "oxycandle_burnt"
		item_state = icon_state
		set_light(0)
	else
		icon_state = "oxycandle"
		item_state = icon_state
		set_light(0)
	update_held_icon()

/obj/item/device/oxycandle/Destroy()
	QDEL_NULL(air_contents)
	STOP_PROCESSING(SSprocessing, src)
	. = ..()