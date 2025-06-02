/obj/machinery/atmospherics/binary/cryocooler
	name = "cryogenic cooling unit"
	desc = "A piece of heavy machinery that practically abuses thermodynamical states to move heat from one end into another."
	var/target_temperature = T20C
	var/efficiency = 0.86
	use_power = POWER_USE_IDLE
	idle_power_usage = 1500
	power_rating = 300000
	connect_types = CONNECT_TYPE_REGULAR|CONNECT_TYPE_FUEL|CONNECT_TYPE_WATER
	icon = 'icons/obj/atmospherics/components/binary/pump.dmi'
	icon_state = "map_off"
	level = 2

/obj/machinery/atmospherics/binary/cryocooler/physical_attack_hand(user)
	. = ..()
	if(!use_power)
		use_power = POWER_USE_IDLE
		to_chat(user, SPAN_NOTICE("You turn on the [src]"))
	else
		use_power = POWER_USE_OFF
		to_chat(user, SPAN_NOTICE("You turn off the [src]"))

/obj/machinery/atmospherics/binary/cryocooler/Process()
	last_power_draw = 0
	if((stat & (NOPOWER|BROKEN)) || !use_power)
		return
	if(air1.temperature > target_temperature)
		var/temperature_delta = target_temperature - air1.temperature
		var/required_energy_transfer = temperature_delta * air1.heat_capacity()
		var/actual_energy_transfer = min(required_energy_transfer * efficiency, power_rating)
		use_power_oneoff(min(abs(required_energy_transfer * (1 - efficiency)), power_rating))
		air2.add_thermal_energy(abs(actual_energy_transfer))
		air1.add_thermal_energy(actual_energy_transfer)