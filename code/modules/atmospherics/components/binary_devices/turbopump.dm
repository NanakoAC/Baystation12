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
	active_power_usage = 0

	initialize_directions = NORTH | SOUTH | EAST | WEST

	power_rating = 0 //On a turbopump, the power rating is constantly varying, and is based on the work generated by the turbine

	//How effectively kinetic energy converts into pumping power
	var/efficiency = 0.7

	//When above max safe energy, this additional multiplier is factored onto efficiency
	var/overload_efficiency = 0.75

	//Stored energy from turbine rotation
	var/kinetic_energy = 0

	target_pressure = INFINITY

	//Percentage of kinetic energy lost each tick
	var/kin_loss = 0.05

	//Last recorded pressure delta
	var/pressure_delta = 0

	//Minimum delta to do any work
	var/min_pressure_delta = 0//10

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
	var/debug_power = 0

	open_valve = TRUE

	//UI Variables
	//This data is stored for displaying info to user in ui
	var/last_pump_flow = 0 	//Volume of gas moved through the pump, in Litres per second
	var/last_pump_mass = 0	//Mass of gas moved through the pump, in Kilograms per second
	var/last_turbine_flow = 0
	var/last_turbine_mass = 0

/obj/machinery/atmospherics/binary/pump/turbo/New()
	.=..()
	air3 = new
	air4 = new
	air3.volume = 200
	air4.volume = 800

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
				world << "Input found at [jumplink(node3)]"
				break

	for(var/obj/machinery/atmospherics/target in get_step(src,node4_connect))
		if(target.initialize_directions & get_dir(target,src))
			if (check_connect_types(target,src))
				node4 = target
				world << "Output found at [jumplink(node4)]"
				break

	//Node1 and node2 are already handled in the parent
	..()

	world << "Pump Input found at [jumplink(node1)]"
	world << "Pump Output found at [jumplink(node2)]"


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
	//Cache some data from the parent
	var/pump_in_moles = air1.total_moles

	.=..()
	var/moles_transferred = pump_in_moles - air1.total_moles

	//Store these calculations for the UI
	if (pump_in_moles)
		last_pump_flow = (moles_transferred / pump_in_moles)*air1.volume
		last_pump_mass = moles_transferred * air1.specific_mass()

	if (!.) //Parent returns false if we're broken
		return


	/*
		Cache some data before we do anything
	*/
	var/input_moles = air3.total_moles //Record the total moles of the input, we'll use this in a minute
	var/input_specific_mass  = air3.specific_mass() //Record the average mass per mole. We need to do this before gas goes through incase air3 gets entirely emptied



	//STAGE 1: TURBINE WORK
	/*
		The formula for work done by a turbine is..
		w = K / ((K - 1) * R * T1 * [1 - ((p2 / p1)((K-1)/K))])
		w = work, the kinetic energy we'll generate
		K = specific heat ratio, we will not bother calculating this and just use a generally accepted value of 1.4
		R = Individual gas constant, we'll get this from the input gas mixture
		T1 = Absolute temperature in kelvin, we'll just grab the temp of gas input
		P1 = Pressure of input
		P2 = Pressure of output
	*/
	var/W = 0
	var/K = 1.4
	var/R = air3.individual_gas_constant_average()
	var/T1 = air3.temperature
	var/P1 = air3.return_pressure()
	var/P2 = air4.return_pressure()

	//kinetic_energy *= 1 - kin_loss
	pressure_delta = max(P1 - P2, 0)
	if(pressure_delta > min_pressure_delta)

		W = (K / (K-1)) * (R * T1 * (1 - ((P2 / P1)**((K-1)/K)))) //This complex formula gives us specific work of the turbine, that is work per kilogram of gas


		kinetic_energy = W

	/*
	world << "---------------------------------------------"
	world << "W = [W]"
	world << "K = [K]"
	world << "R = [R]"
	world << "T1 = [T1]"
	world << "P1 = [P1]"
	world << "P2 = [P2]"
	*/

	//STAGE 2: GAS FLOW


	/*
		We shall let gas flow through the turbine
		This will equalise the pressure between air3 and air4 by letting some gas through
		In addition, it will populate our last_flow_rate var with the percentage of moles that it let through
	*/
	//world << "Preflow pressure [P1] [P2]"
	pump_gas_passive(src, air3, air4)
	//world << "Postflow pressure [air3.return_pressure()] [air4.return_pressure()]"

	/*
		Now how much did we actually let through?
		This gives us the actual mass, in kilograms, of the gas that passed through the turbine
	*/
	last_turbine_mass = (input_moles - air3.total_moles) * input_specific_mass
	last_turbine_flow = last_flow_rate

	kinetic_energy *= last_turbine_mass //So we multiply it by the mass of the gas to get a result

	kinetic_energy /= ATMOS_PUMP_EFFICIENCY //Then we divide it by this poorly implemented hack to prevent creating a perpetual motion machine
	//Todo: Remove this pump efficiency value from everything

	kinetic_energy += debug_power
	power_rating = kinetic_energy * efficiency //power_rating is used for pumping


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

/obj/machinery/atmospherics/binary/pump/turbo/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	if(!operable())
		return

	// this is the data which will be sent to the ui
	var/data[0]

	data = list(
		"kinetic_energy" = round(kinetic_energy,1),
		"power" = round(power_rating,1),
		"safe_energy" = max_safe_energy,	//Nano UI can't handle rounded non-integers, apparently.
		"overload_energy" = destruct_energy,
		"last_pump_flow" = fixed_decimal(last_pump_flow, 2),
		"last_pump_mass" = fixed_decimal(last_pump_mass,2),
		"last_turbine_flow" = fixed_decimal(last_turbine_flow,2),
		"last_turbine_mass" = fixed_decimal(last_turbine_mass,2),
		"pump_pressure_in" = fixed_decimal(air1.return_pressure(),2),
		"pump_pressure_out" = fixed_decimal(air2.return_pressure(),2),
		"turbine_pressure_in" = fixed_decimal(air3.return_pressure(),2),
		"turbine_pressure_out" = fixed_decimal(air4.return_pressure(),2)
	)

	// update the ui if it exists, returns null if no ui is passed/found
	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		// the ui does not exist, so we'll create a new() one
		// for a list of parameters and their descriptions see the code docs in \code\modules\nano\nanoui.dm
		ui = new(user, src, ui_key, "turbopump.tmpl", name, 470, 290)
		ui.set_initial_data(data)	// when the ui is first opened this is the data it will use
		ui.open()					// open the new ui window
		ui.set_auto_update(1)		// auto update every Master Controller tick