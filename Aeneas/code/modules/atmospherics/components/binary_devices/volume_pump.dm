/obj/machinery/atmospherics/binary/pump/high_power
	icon = 'icons/atmos/volume_pump.dmi'
	icon_state = "map_off"
	level = 1

	name = "high power gas pump"
	desc = "A pump. Has double the power rating of the standard gas pump."

	idle_power_usage = 50	// oversized pumps means oversized idle use
	power_rating = 45000	// 45000 W ~ 60 HP
	build_icon_state = "volumepump"

/obj/machinery/atmospherics/binary/pump/high_power/on
	use_power = POWER_USE_IDLE
	icon_state = "map_on"

/obj/machinery/atmospherics/binary/pump/high_power/on_update_icon()
	if(!powered())
		icon_state = "off"
	else
		icon_state = "[use_power ? "on" : "off"]"

// For mapping purposes
/obj/machinery/atmospherics/binary/pump/high_power/on/max_pressure/Initialize()
	.=..()
	target_pressure = max_pressure_setting

// A possible variant for Atmospherics distribution feed.
/obj/machinery/atmospherics/binary/pump/high_power/on/distribution/Initialize()
	. = ..()
	target_pressure = round(10 * ONE_ATMOSPHERE)