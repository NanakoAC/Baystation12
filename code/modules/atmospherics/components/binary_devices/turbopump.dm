/*
A turbopump is a combination of a turbine and a pump which uses high pressure gas
spinning a turbine to mechanically drive a pump of another, seperate gas.

node1, air1, network1 correspond to pump input	(higher pressure)
node2, air2, network2 correspond to pump output	(lower pressure)

node3, air3, network3 coorespond to turbine input (low pressure)
node4, air4, network4 coorespond to turbine output(high pressure)

Nodes are arranged in the order north, south, west, east, with node1 being north on a
north-facing turbopump. node2 will then be south, node3 west, and node4 east.

This object is designed to pump coolant gas through a one-way, binary gas device
which heats the coolant and produces a higher temperature, and so higher pressure,
gas to power the turbine. That turbine then powers the pump directly through the
pressure lost in the turbine. It is important that enough inefficiency exists that
this device is not a perpetual motion machine. It is also a design goal to not have
a maximum limit on gas output pressure.

Real turbopumps will shatter if they run at too high of an RPM. For our purposes a
design limit of 1 megawatt of pumping power, tied to a display of 1,000 RPM, is the
maximum safe limit. Beyond this, sparks fly similar to the TEG generator and
the efficiency falls. At 2,000 RPM, the turbopump explodes.

The turbopump does not require electrical power to operate, but electrical power will
allow remote operation of a bypass valve. This throttle moves gas from node1 to node 2
without generating turbine power, using the pressure regulator framework.

*/

/obj/machinery/atmospherics/binary/pump/turbo
	name = "turbopump"
	desc = "A powerful turbopump. The other bits of a rocket are probably around here somewhere."
	icon = 'icons/obj/pipeturbine.dmi'
	icon_state = "turbine"
	anchored = 1
	density = 1

	idle_power_usage = 0

	initialize_directions = NORTH | SOUTH | EAST | WEST

	power_rating = 0 //On a turbopump, the power rating is constantly varying, and is based on the work generated by the turbine

	//How effectively kinetic energy converts into pumping power
	var/efficiency = 0.4

	//When above max safe energy, this additional multiplier is factored onto efficiency
	var/overload_efficiency = 0.75

	//Stored energy from turbine rotation
	var/kinetic_energy = 0

	//Percentage of kinetic energy lost each tick
	var/kin_loss = 0.05

	//Last recorded pressure delta
	var/pressure_delta = 0

	//Minimum delta to do any work
	var/min_pressure_delta = 10

	var/volume_ratio = 0.2

	//Above this energy value, the pump starts throwing out sparks
	var/max_safe_energy = 1 MEGAWATTS

	//Above this energy value, the turbopump immediately explodes
	var/destruct_energy = 2 MEGAWATTS

	//The turbine ports
	var/obj/machinery/atmospherics/node3
	var/obj/machinery/atmospherics/node4

	var/datum/gas_mixture/air3 = new
	var/datum/gas_mixture/air4 = new

	var/datum/pipe_network/network3
	var/datum/pipe_network/network4

	pipe_class = PIPE_CLASS_QUATERNARY


//atmos_init finds the objects (typically pipes) which connect to us, and fills the nodeX variables with them
/obj/machinery/atmospherics/binary/pump/turbo/atmos_init()

	if(node3 && node4)
		return

	var/node3_connect = turn(dir, -90)
	var/node4_connect = turn(dir, 90)

	for(var/obj/machinery/atmospherics/target in get_step(src,node3_connect))
		if(target.initialize_directions & get_dir(target,src))
			if (check_connect_types(target,src))
				node3 = target
				break

	for(var/obj/machinery/atmospherics/target in get_step(src,node4_connect))
		if(target.initialize_directions & get_dir(target,src))
			if (check_connect_types(target,src))
				node4 = target
				break

	//Node1 and node2 are already handled in the parent
	..()


//Using the nodes we found earlier, this creates connections to them
/obj/machinery/atmospherics/binary/pump/turbo/build_network()
	if(!network3 && node3)
		network3 = new /datum/pipe_network()
		network3.normal_members += src
		network3.build_network(node3, src)

	if(!network4 && node4)
		network4 = new /datum/pipe_network()
		network4.normal_members += src
		network4.build_network(node4, src)

	//As always, parent handles 2 and 1
	..()

//This passes the air back to those connections
/obj/machinery/atmospherics/binary/pump/turbo/return_network_air(var/datum/pipe_network/reference)
	if (reference == network3)
		return air3

	if (reference == network4)
		return air4

	//As always, parent handles 2 and 1
	.=..(reference)



//The turbopump will always pump as much as it can
/obj/machinery/atmospherics/binary/pump/turbo/pump_get_transfer_moles(air1, air2, pressure_delta, sink_mod)
	return INFINITY


/obj/machinery/atmospherics/binary/pump/turbo/powered(var/chan = -1, var/area/check_area = null)
	return TRUE //Does not draw external power

/obj/machinery/atmospherics/binary/pump/turbo/use_power_oneoff()
	return TRUE

//This machine operates even when power is off
/obj/machinery/atmospherics/binary/pump/turbo/inoperable(var/additional_flags = 0)
	return (stat & (BROKEN|additional_flags))


//We process after the parent, and generate power for the next tick
/obj/machinery/atmospherics/binary/pump/turbo/Process()
	.=..()

	if (!.) //Parent returns false if we're broken
		return


	kinetic_energy *= 1 - kin_loss
	pressure_delta = max(air3.return_pressure() - air4.return_pressure(), 0)
	if(pressure_delta > min_pressure_delta)
		kinetic_energy += 1/ADIABATIC_EXPONENT * pressure_delta * air3.volume * (1 - volume_ratio**ADIABATIC_EXPONENT)
		air3.temperature *= volume_ratio**ADIABATIC_EXPONENT

		var/datum/gas_mixture/air_all = new
		air_all.volume = air3.volume + air4.volume
		air_all.merge(air3.remove_ratio(1))
		air_all.merge(air4.remove_ratio(1))

		air3.merge(air_all.remove(volume_ratio))
		air4.merge(air_all)

	power_rating = kinetic_energy * efficiency

	if(kinetic_energy > max_safe_energy)
		if(kinetic_energy > destruct_energy)
			explode()
			return

		power_rating *= overload_efficiency
		if (prob(5))
			var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
			s.set_up(3, 1, src)
			s.start()

	update_icon()

	if (network3)
		network3.update = 1
	if (network4)
		network4.update = 1



/obj/machinery/atmospherics/binary/pump/turbo/update_icon()
	overlays.Cut()
	if(pressure_delta > min_pressure_delta)
		overlays += image('icons/obj/pipeturbine.dmi', "moto-turb")
	if(kinetic_energy > max_safe_energy * 0.1)
		overlays += image('icons/obj/pipeturbine.dmi', "low-turb")
	if(kinetic_energy > max_safe_energy * 0.5)
		overlays += image('icons/obj/pipeturbine.dmi', "med-turb")
	if(kinetic_energy > max_safe_energy * 0.8)
		overlays += image('icons/obj/pipeturbine.dmi', "hi-turb")



/obj/machinery/atmospherics/binary/pump/turbo/get_initialize_directions()
	return initial(initialize_directions)

/*
/obj/machinery/atmospherics/components/turbopump





	var/efficiency = 0.9
	var/kinetic_energy = 0
	var/datum/gas_mixture/air3 = new
	var/datum/gas_mixture/air4 = new
	var/volume_ratio = 0.2
	var/kin_loss = 0.001

	var/dP = 0

	var/datum/pipe_network/network1
	var/datum/pipe_network/network2

	pipe_class = PIPE_CLASS_QUATERNARY
	rotate_class = PIPE_ROTATE_STANDARD

	New()
		..()
		air3.volume = 200
		air4.volume = 800
		volume_ratio = air3.volume / (air3.volume + air4.volume)
		switch(dir)
			if(NORTH)
				initialize_directions = EAST|WEST
			if(SOUTH)
				initialize_directions = EAST|WEST
			if(EAST)
				initialize_directions = NORTH|SOUTH
			if(WEST)
				initialize_directions = NORTH|SOUTH

	Destroy()
		if(node1)
			node1.disconnect(src)
			QDEL_NULL(network1)
		if(node2)
			node2.disconnect(src)
			QDEL_NULL(network2)

		node1 = null
		node2 = null

		. = ..()

	Process()
		..()
		if(anchored && !(stat&BROKEN))
			kinetic_energy *= 1 - kin_loss
			dP = max(air3.return_pressure() - air4.return_pressure(), 0)
			if(dP > 10)
				kinetic_energy += 1/ADIABATIC_EXPONENT * dP * air3.volume * (1 - volume_ratio**ADIABATIC_EXPONENT) * efficiency
				air3.temperature *= volume_ratio**ADIABATIC_EXPONENT

				var/datum/gas_mixture/air_all = new
				air_all.volume = air3.volume + air4.volume
				air_all.merge(air3.remove_ratio(1))
				air_all.merge(air4.remove_ratio(1))

				air3.merge(air_all.remove(volume_ratio))
				air4.merge(air_all)

			update_icon()

		if (network1)
			network1.update = 1
		if (network2)
			network2.update = 1

	update_icon()
		overlays.Cut()
		if (dP > 10)
			overlays += image('icons/obj/pipeturbine.dmi', "moto-turb")
		if (kinetic_energy > 100000)
			overlays += image('icons/obj/pipeturbine.dmi', "low-turb")
		if (kinetic_energy > 500000)
			overlays += image('icons/obj/pipeturbine.dmi', "med-turb")
		if (kinetic_energy > 1000000)
			overlays += image('icons/obj/pipeturbine.dmi', "hi-turb")

	attackby(obj/item/weapon/W as obj, mob/user as mob)
		if(isWrench(W))
			anchored = !anchored
			to_chat(user, "<span class='notice'>You [anchored ? "secure" : "unsecure"] the bolts holding \the [src] to the floor.</span>")

			if(anchored)
				if(dir & (NORTH|SOUTH))
					initialize_directions = EAST|WEST
				else if(dir & (EAST|WEST))
					initialize_directions = NORTH|SOUTH

				atmos_init()
				build_network()
				if (node1)
					node1.atmos_init()
					node1.build_network()
				if (node2)
					node2.atmos_init()
					node2.build_network()
			else
				if(node1)
					node1.disconnect(src)
					qdel(network1)
				if(node2)
					node2.disconnect(src)
					qdel(network2)

				node1 = null
				node2 = null

		else
			..()

	verb/rotate_clockwise()
		set category = "Object"
		set name = "Rotate Turbopump (Clockwise)"
		set src in view(1)

		if (usr.stat || usr.restrained() || anchored)
			return

		src.set_dir(turn(src.dir, -90))


	verb/rotate_anticlockwise()
		set category = "Object"
		set name = "Rotate Turbopump (Counterclockwise)"
		set src in view(1)

		if (usr.stat || usr.restrained() || anchored)
			return

		src.set_dir(turn(src.dir, 90))

//Goddamn copypaste from binary base class because atmospherics machinery API is not damn flexible
	network_expand(datum/pipe_network/new_network, obj/machinery/atmospherics/pipe/reference)
		if(reference == node1)
			network1 = new_network

		else if(reference == node2)
			network2 = new_network

		if(new_network.normal_members.Find(src))
			return 0

		new_network.normal_members += src

		return null

	atmos_init()
		..()
		if(node1 && node2) return

		var/node2_connect = turn(dir, -90)
		var/node1_connect = turn(dir, 90)

		for(var/obj/machinery/atmospherics/target in get_step(src,node1_connect))
			if(target.initialize_directions & get_dir(target,src))
				node1 = target
				break

		for(var/obj/machinery/atmospherics/target in get_step(src,node2_connect))
			if(target.initialize_directions & get_dir(target,src))
				node2 = target
				break

	build_network()
		if(!network1 && node1)
			network1 = new /datum/pipe_network()
			network1.normal_members += src
			network1.build_network(node1, src)

		if(!network2 && node2)
			network2 = new /datum/pipe_network()
			network2.normal_members += src
			network2.build_network(node2, src)


	return_network(obj/machinery/atmospherics/reference)
		build_network()

		if(reference==node1)
			return network1

		if(reference==node2)
			return network2

		return null

	reassign_network(datum/pipe_network/old_network, datum/pipe_network/new_network)
		if(network1 == old_network)
			network1 = new_network
		if(network2 == old_network)
			network2 = new_network

		return 1

	return_network_air(datum/pipe_network/reference)
		var/list/results = list()

		if(network1 == reference)
			results += air3
		if(network2 == reference)
			results += air4

		return results

	disconnect(obj/machinery/atmospherics/reference)
		if(reference==node1)
			qdel(network1)
			node1 = null

		else if(reference==node2)
			qdel(network2)
			node2 = null

		return null

/*
Every cycle, the pump uses the air in air3 to try and make air4 the perfect pressure.

node3, air3, network3 correspond to input
node4, air4, network4 correspond to output

Thus, the two variables affect pump operation are set in New():
	air1.volume
		This is the volume of gas available to the pump that may be transfered to the output
	air2.volume
		Higher quantities of this cause more air to be perfected later
			but overall network volume is also increased as this increases...
*/



	var/optimum_turbine_speed = 1000
	var/failure_turbine_speed = 2000

	var/frequency = 0
	var/id = null
	var/datum/radio_frequency/radio_connection

/obj/machinery/atmospherics/binary/turbopump/Initialize()
	. = ..()
	air3.volume = ATMOS_DEFAULT_VOLUME_PUMP
	air4.volume = ATMOS_DEFAULT_VOLUME_PUMP

/obj/machinery/atmospherics/binary/pump/update_underlays()
	if(..())
		underlays.Cut()
		var/turf/T = get_turf(src)
		if(!istype(T))
			return
		add_underlay(T, node3, turn(dir, -90))
		add_underlay(T, node4, dir)

/obj/machinery/atmospherics/binary/turbopump/Process()
	last_power_draw = 0
	last_flow_rate = 0

	if((stat & (NOPOWER|BROKEN)) || !use_power)
		return

	var/power_draw = -1
	var/pressure_delta = target_pressure - air4.return_pressure()

	if(pressure_delta > 0.01 && air1.temperature > 0)
		//Figure out how much gas to transfer to meet the target pressure.
		var/transfer_moles = calculate_transfer_moles(air3, air4, pressure_delta, (network3)? network4.volume : 0)
		power_draw = pump_gas(src, air3, air4, transfer_moles, power_rating)

	if (power_draw >= 0)
		last_power_draw = power_draw
		use_power_oneoff(power_draw)

		if(network3)
			network3.update = 1

		if(network4)
			network4.update = 1

	return 1

//Radio remote control

/obj/machinery/atmospherics/binary/turbopump/proc/set_frequency(new_frequency)
	radio_controller.remove_object(src, frequency)
	frequency = new_frequency
	if(frequency)
		radio_connection = radio_controller.add_object(src, frequency, radio_filter = RADIO_ATMOSIA)

/obj/machinery/atmospherics/binary/turbopump/proc/broadcast_status()
	if(!radio_connection)
		return 0

	var/datum/signal/signal = new
	signal.transmission_method = 1 //radio signal
	signal.source = src

	signal.data = list(
		"tag" = id,
		"device" = "AGP",
		"power" = use_power,
		"target_output" = target_pressure,
		"sigtype" = "status"
	)

	radio_connection.post_signal(src, signal, radio_filter = RADIO_ATMOSIA)

	return 1

/obj/machinery/atmospherics/binary/pump/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	if(stat & (BROKEN|NOPOWER))
		return

	// this is the data which will be sent to the ui
	var/data[0]

	data = list(
		"on" = use_power,
		"pressure_set" = round(target_pressure*100),	//Nano UI can't handle rounded non-integers, apparently.
		"max_pressure" = max_pressure_setting,
		"last_flow_rate" = round(last_flow_rate*10),
		"last_power_draw" = round(last_power_draw),
		"max_power_draw" = power_rating,
	)

	// update the ui if it exists, returns null if no ui is passed/found
	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		// the ui does not exist, so we'll create a new() one
		// for a list of parameters and their descriptions see the code docs in \code\modules\nano\nanoui.dm
		ui = new(user, src, ui_key, "gas_pump.tmpl", name, 470, 290)
		ui.set_initial_data(data)	// when the ui is first opened this is the data it will use
		ui.open()					// open the new ui window
		ui.set_auto_update(1)		// auto update every Master Controller tick

/obj/machinery/atmospherics/binary/pump/Initialize()
	. = ..()
	if(frequency)
		set_frequency(frequency)

/obj/machinery/atmospherics/binary/pump/Destroy()
	unregister_radio(src, frequency)
	. = ..()

/obj/machinery/atmospherics/binary/pump/receive_signal(datum/signal/signal)
	if(!signal.data["tag"] || (signal.data["tag"] != id) || (signal.data["sigtype"]!="command"))
		return 0

	if(signal.data["power"])
		if(text2num(signal.data["power"]))
			update_use_power(POWER_USE_IDLE)
		else
			update_use_power(POWER_USE_OFF)

	if("power_toggle" in signal.data)
		update_use_power(!use_power)

	if(signal.data["set_output_pressure"])
		target_pressure = between(
			0,
			text2num(signal.data["set_output_pressure"]),
			ONE_ATMOSPHERE*50
		)

	if(signal.data["status"])
		spawn(2)
			broadcast_status()
		return //do not update_icon

	spawn(2)
		broadcast_status()
	update_icon()
	return

/obj/machinery/atmospherics/binary/turbopump/interface_interact(mob/user)
	ui_interact(user)
	return TRUE

/obj/machinery/atmospherics/binary/turbopump/Topic(href,href_list)
	if((. = ..())) return

	if(href_list["power"])
		update_use_power(!use_power)
		. = 1

	switch(href_list["set_press"])
		if ("min")
			target_pressure = 0
			. = 1
		if ("max")
			target_pressure = max_pressure_setting
			. = 1
		if ("set")
			var/new_pressure = input(usr,"Enter new output pressure (0-[max_pressure_setting]kPa)","Pressure control",src.target_pressure) as num
			src.target_pressure = between(0, new_pressure, max_pressure_setting)
			. = 1

	if(.)
		src.update_icon()
*/