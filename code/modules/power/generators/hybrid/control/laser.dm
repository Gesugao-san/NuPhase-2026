/obj/machinery/reactor_button/rswitch/lasarm
	name = "LAS-ARM"
	cooldown = 20
	icon_state = "switch2-off"
	off_icon_state = "switch2-off"
	on_icon_state = "switch2-on"

/obj/machinery/reactor_button/rswitch/lasarm/do_action(mob/user)
	..()
	visible_message(SPAN_WARNING("[user] switches [src] to [state ? "ARMED" : "DISARMED"]!"))
	for(var/tag in reactor_components)
		var/obj/machinery/rlaser/las = reactor_components[tag]
		if(!istype(las, /obj/machinery/rlaser))
			continue
		las.armed = state
		if(las.armed)
			rcontrol.make_log("LASERS ARMED.", 2)
		else
			rcontrol.make_log("LASERS DISARMED.", 1)
		if(state)
			las.operating = TRUE
		else
			las.operating = FALSE


/obj/machinery/reactor_button/rswitch/lasprime
	name = "LAS-PRIMER"
	cooldown = 10
	icon_state = "switch2-off"
	off_icon_state = "switch2-off"
	on_icon_state = "switch2-on"

/obj/machinery/reactor_button/rswitch/lasprime/do_action(mob/user)
	..()
	visible_message(SPAN_WARNING("[user] switches [src] to [state ? "PRIMED" : "ABORT"]!"))
	if(state == 1)
		var/primed = FALSE
		var/total_energy = 0
		for(var/tag in reactor_components)
			var/obj/machinery/rlaser/las = reactor_components[tag]
			if(!istype(las, /obj/machinery/rlaser))
				continue
			if(las.prime())
				total_energy += las.capacitor_charge * las.active_power_usage
				primed = TRUE
		if(primed)
			playsound(src, 'sound/machines/switchbuzzer.ogg', 50)
			rcontrol.make_log("LASERS PRIMED.", 2)
		spawn(5 SECONDS)
			for(var/obj/machinery/reactor_monitor/general/mon in rcontrol.announcement_monitors)
				mon.chat_report("LASERS DISCHARGED. TOTAL ENERGY: [watts_to_text(total_energy)]/s*1.4.", 1)
			rcontrol.make_log("LASERS DISCHARGED. TOTAL ENERGY: [watts_to_text(total_energy)]/s*1.4.", 1)
			for(var/mob/living/carbon/human/H in human_mob_list)
				shake_camera(H, 20, 0.9)
			state = 0
			icon_state = off_icon_state
	else
		for(var/tag in reactor_components)
			var/obj/machinery/rlaser/las = reactor_components[tag]
			if(!istype(las, /obj/machinery/rlaser))
				continue
			las.primed = FALSE

/obj/machinery/reactor_button/lasomode
	name = "LAS-OMODE"
	icon_state = "button2"

/obj/machinery/reactor_button/lasomode/do_action(mob/user)
	..()
	var/mode = tgui_input_list(user, "Select a new laser operation mode", "LASER-OMODE", list(LASER_MODE_CONTINUOUS, LASER_MODE_IGNITION, LASER_MODE_IMPULSE, LASER_MODE_OFF))
	if(!mode)
		return
	for(var/tag in reactor_components)
		var/obj/machinery/rlaser/las = reactor_components[tag]
		if(!istype(las, /obj/machinery/rlaser))
			continue
		las.switch_omode(mode)
	visible_message(SPAN_WARNING("[user] switches [src] to [mode]!"))
	rcontrol.make_log("LASER HEATING MODE SWITCHED TO [mode].", 1)

/obj/machinery/reactor_button/lasnmode
	name = "LAS-NMODE"
	icon_state = "button2"

/obj/machinery/reactor_button/lasnmode/do_action(mob/user)
	..()
	var/mode = tgui_input_list(user, "Select a new laser neutron mode", "LASER-OMODE", list(NEUTRON_MODE_BOMBARDMENT, NEUTRON_MODE_MODERATION, NEUTRON_MODE_OFF))
	if(!mode)
		return
	for(var/tag in reactor_components)
		var/obj/machinery/rlaser/las = reactor_components[tag]
		if(!istype(las, /obj/machinery/rlaser))
			continue
		las.nmode = mode
	visible_message(SPAN_WARNING("[user] switches [src] to [mode]!"))
	rcontrol.make_log("LASER NEUTRON MODE SWITCHED TO [mode].", 1)