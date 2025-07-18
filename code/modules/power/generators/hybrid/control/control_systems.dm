/obj/machinery/reactor_button/protected/scram
	name = "EP-SCRAM"
	id = "EP-SCRAM"
	cooldown = 60 SECONDS

/obj/machinery/reactor_button/protected/scram/do_action(mob/user)
	..()
	rcontrol.scram("OPERATOR REQUEST")
	visible_message(SPAN_WARNING("[user] SCRAMs the reactor!"))

/obj/machinery/reactor_button/protected/mode_of_operation
	name = "CONTROL MODE"
	cooldown = 10 SECONDS

/obj/machinery/reactor_button/protected/mode_of_operation/do_action(mob/user)
	..()
	var/newmode = tgui_input_list(user, "Select a new reactor system mode", "Control Mode", list(REACTOR_CONTROL_MODE_MANUAL, REACTOR_CONTROL_MODE_SEMIAUTO, REACTOR_CONTROL_MODE_AUTO))
	var/response = rcontrol.switch_mode(newmode)
	if(!response)
		to_chat(user, SPAN_WARNING("This mode is unavailable!"))
		return
	if(response == 2)
		to_chat(user, SPAN_NOTICE("The system is already in the same mode."))
		return
	visible_message(SPAN_WARNING("[user] switches [src] to [newmode]!"))

/obj/machinery/reactor_button/protected/containment
	name = "CONTAINMENT PRIMER"
	desc = "Turns on the reactor's shields. Has a very large cooldown."
	id = "CONTAINMENT PRIMER"
	cooldown = 5 MINUTES

/obj/machinery/reactor_button/protected/containment/do_action(mob/user)
	..()
	var/obj/machinery/power/hybrid_reactor/rcore = reactor_components["core"]
	if(rcore.containment)
		return
	rcore.containment = TRUE
	rcontrol.make_log("CONTAINMENT STARTED.", 1)

/obj/machinery/reactor_button/rswitch/autoscram
	name = "AUTOSCRAM"
	id = "AUTOSCRAM"
	cooldown = 5 SECONDS

/obj/machinery/reactor_button/rswitch/autoscram/do_action(mob/user)
	..()
	rcontrol.scram_control = state
	if(state)
		visible_message(SPAN_NOTICE("[user] turns on automatic SCRAM control."))
		rcontrol.make_log("AUTOSCRAM ENABLED.", 1)
	else
		visible_message(SPAN_WARNING("[user] shuts down automatic SCRAM control."))
		rcontrol.make_log("AUTOSCRAM DISABLED.", 3)

/obj/machinery/reactor_button/acknowledge_alarms
	name = "ACKNOWLEDGE ALARMS"
	cooldown = 5 SECONDS

/obj/machinery/reactor_button/acknowledge_alarms/do_action(mob/user)
	..()
	rcontrol.cleared_messages = rcontrol.all_messages.Copy()

/obj/machinery/reactor_button/mute_alarms
	name = "MUTE ALARMS"
	cooldown = 3 MINUTE

/obj/machinery/reactor_button/mute_alarms/do_action(mob/user)
	..()
	visible_message(SPAN_WARNING("[user] temporarily disables the control system alarms."))
	rcontrol.make_log("ALARMS MUTED.", 1)
	rcontrol.should_alarm = FALSE
	spawn(3 MINUTE)
		rcontrol.should_alarm = TRUE
	for(var/obj/machinery/rotating_alarm/reactor/control_room/SL in rcontrol.control_spinning_lights)
		QDEL_NULL(SL.oo_alarm)
		QDEL_NULL(SL.arm_alarm)

/obj/machinery/reactor_button/protected/purge
	name = "PURGE"
	id = "PURGE"
	cooldown = 5 MINUTES

/obj/machinery/reactor_button/protected/purge/do_action(mob/user)
	..()
	rcontrol.delayed_purge()

/obj/machinery/reactor_button/protected/efss_discharge
	name = "EFSS DISCHARGE"
	id = "EFSS"
	cooldown = 5 MINUTES

/obj/machinery/reactor_button/rswitch/battery_charging
	name = "BATTERY CHARGER"
	id = "BATTERY CHARGER"

/obj/machinery/reactor_button/rswitch/battery_charging/do_action(mob/user)
	..()
	var/obj/machinery/power/hybrid_reactor/rcore = reactor_components["core"]
	rcore.field_charging = state