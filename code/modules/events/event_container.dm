var/global/list/severity_to_string = list(EVENT_LEVEL_MUNDANE = "Mundane", EVENT_LEVEL_MODERATE = "Moderate", EVENT_LEVEL_MAJOR = "Major")

/datum/event_container
	var/severity = -1
	var/delayed = 0
	var/delay_modifier = 1
	var/next_event_time = 0
	var/list/available_events
	var/list/last_event_time = list()
	var/datum/event_meta/next_event = null

	var/last_world_time = 0

/datum/event_container/proc/process()
	if(!next_event_time)
		set_event_delay()

	if(delayed || !get_config_value(/decl/config/toggle/allow_random_events))
		next_event_time += (world.time - last_world_time)
	else if(world.time > next_event_time)
		start_event()

	last_world_time = world.time

/datum/event_container/proc/start_event()
	if(!next_event)	// If non-one has explicitly set an event, randomly pick one
		next_event = acquire_event()

	// Has an event been acquired?
	if(next_event)
		// Set when the event of this type was last fired, and prepare the next event start
		last_event_time[next_event] = world.time
		set_event_delay()
		next_event.enabled = !next_event.one_shot	// This event will no longer be available in the random rotation if one shot

		new next_event.event_type(next_event)	// Events are added and removed from the processing queue in their New/kill procs

		log_debug("Starting event '[next_event.name]' of severity [severity_to_string[severity]].")
		next_event = null						// When set to null, a random event will be selected next time
	else
		// If not, wait for one minute, instead of one tick, before checking again.
		next_event_time += (60 * 10)


/datum/event_container/proc/acquire_event()
	if(available_events.len == 0)
		return
	var/active_with_role = number_active_with_role()

	var/list/possible_events = list()
	for(var/datum/event_meta/EM in available_events)
		if(initial(EM.event_type.check_proc) && !call(initial(EM.event_type.check_proc))())
			continue
		var/event_weight = get_weight(EM, active_with_role)
		if(event_weight)
			possible_events[EM] = event_weight

	if(possible_events.len == 0)
		return null

	// Select an event and remove it from the pool of available events
	var/picked_event = pickweight(possible_events)
	available_events -= picked_event
	return picked_event

/datum/event_container/proc/get_weight(var/datum/event_meta/EM, var/list/active_with_role)
	if(!EM.enabled)
		return 0

	var/weight = EM.get_weight(active_with_role)
	var/last_time = last_event_time[EM]
	if(last_time)
		var/time_passed = world.time - last_time
		var/weight_modifier = max(0, round(((get_config_value(/decl/config/num/expected_round_length) HOURS) - time_passed) / 300))
		weight = weight - weight_modifier

	return weight

/datum/event_container/proc/set_event_delay()
	// If the next event time has not yet been set and we have a custom first time start
	var/list/event_first_run = get_config_value(/decl/config/lists/event_first_run)
	if(next_event_time == 0 && event_first_run[severity])
		var/lower = event_first_run[severity]["lower"]
		var/upper = event_first_run[severity]["upper"]
		var/event_delay = rand(lower, upper) MINUTES
		next_event_time = world.time + event_delay
	// Otherwise, follow the standard setup process
	else
		var/playercount_modifier = 1
		switch(global.player_list.len)
			if(0 to 10)
				playercount_modifier = 1.2
			if(11 to 15)
				playercount_modifier = 1.1
			if(16 to 25)
				playercount_modifier = 1
			if(26 to 35)
				playercount_modifier = 0.9
			if(36 to 100000)
				playercount_modifier = 0.8
		playercount_modifier = playercount_modifier * delay_modifier

		var/list/event_delay_lower = get_config_value(/decl/config/lists/event_delay_lower)
		var/list/event_delay_upper = get_config_value(/decl/config/lists/event_delay_upper)
		var/event_delay = (rand(event_delay_lower[severity], event_delay_upper[severity]) * playercount_modifier) MINUTES
		next_event_time = world.time + event_delay

	log_debug("Next event of severity [severity_to_string[severity]] in [(next_event_time - world.time)/600] minutes.")

/datum/event_container/proc/SelectEvent()
	var/datum/event_meta/EM = input("Select an event to queue up.", "Event Selection", null) as null|anything in available_events
	if(!EM)
		return
	if(next_event)
		available_events += next_event
	available_events -= EM
	next_event = EM
	return EM

/datum/event_container/mundane
	severity = EVENT_LEVEL_MUNDANE
	available_events = list(
		// Severity level, event name, event type, base weight, role weights, one shot, min weight, max weight. Last two only used if set and non-zero
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Nothing",						/datum/event/nothing,				100),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "APC Damage",					/datum/event/apc_damage,			20, 	list(ASSIGNMENT_ENGINEER = 10)),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Computer Damage",				/datum/event/computer_damage,		20, 	list(ASSIGNMENT_ENGINEER = 10)),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Computer Update",				/datum/event/computer_update,		20),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Camera Damage",					/datum/event/camera_damage,			20, 	list(ASSIGNMENT_ENGINEER = 10)),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Sensor Suit Jamming",			/datum/event/sensor_suit_jamming,	50,		list(ASSIGNMENT_MEDICAL = 20, ASSIGNMENT_COMPUTER = 20), 1),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Light Check",					/datum/event/light_check, 			400),
		//new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Vermin Infestation",			/datum/event/infestation, 			100,	list(ASSIGNMENT_JANITOR = 100)),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Wallrot",						/datum/event/wallrot, 				0,		list(ASSIGNMENT_ENGINEER = 30, ASSIGNMENT_GARDENER = 50)),
		new /datum/event_meta/no_overmap(EVENT_LEVEL_MUNDANE, "Electrical Storm",	/datum/event/electrical_storm, 		20,		list(ASSIGNMENT_ENGINEER = 20, ASSIGNMENT_JANITOR = 100)),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Toilet Clog",					/datum/event/toilet_clog,			50, 	list(ASSIGNMENT_JANITOR = 20)),
		new /datum/event_meta(EVENT_LEVEL_MUNDANE, "Random Ailments",				/datum/event/ailments,				50, 	list(ASSIGNMENT_ANY = 1))
	)

/datum/event_container/moderate
	severity = EVENT_LEVEL_MODERATE
	available_events = list(
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Nothing",								/datum/event/nothing,					1230),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Appendicitis", 						/datum/event/spontaneous_appendicitis, 	0,		list(ASSIGNMENT_MEDICAL = 10), 1),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Communication Blackout",				/datum/event/communications_blackout,	100,	list(ASSIGNMENT_COMPUTER = 100, ASSIGNMENT_ENGINEER = 20)),
		new /datum/event_meta/no_overmap(EVENT_LEVEL_MODERATE, "Electrical Storm",			/datum/event/electrical_storm, 			10,		list(ASSIGNMENT_ENGINEER = 15, ASSIGNMENT_JANITOR = 10)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Grid Check",							/datum/event/grid_check, 				200,	list(ASSIGNMENT_ENGINEER = 10)),
		new /datum/event_meta/extended_penalty(EVENT_LEVEL_MODERATE, "Random Antagonist",	/datum/event/random_antag,				2.5,	list(ASSIGNMENT_SECURITY = 1), 1, 0, 5),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Sensor Suit Jamming",					/datum/event/sensor_suit_jamming,		10,		list(ASSIGNMENT_MEDICAL = 20, ASSIGNMENT_COMPUTER = 20)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Solar Storm",							/datum/event/solar_storm, 				10,		list(ASSIGNMENT_ENGINEER = 20, ASSIGNMENT_SECURITY = 10), 1),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Spider Infestation",					/datum/event/spider_infestation, 		25,		list(ASSIGNMENT_SECURITY = 15), 1),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Medical Breach",						/datum/event/prison_break/medical,		0,		list(ASSIGNMENT_MEDICAL = 100)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Science Breach",						/datum/event/prison_break/science,		0,		list(ASSIGNMENT_SCIENCE = 100)),
		new /datum/event_meta(EVENT_LEVEL_MODERATE, "Toilet Flooding",						/datum/event/toilet_clog/flood,			50, 	list(ASSIGNMENT_JANITOR = 20))
	)

/datum/event_container/major
	severity = EVENT_LEVEL_MAJOR
	available_events = list(
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Nothing",							/datum/event/nothing,				1320),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Blob",							/datum/event/blob, 					0,	list(ASSIGNMENT_ENGINEER = 40), 1),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Containment Breach",				/datum/event/prison_break/station,	0,	list(ASSIGNMENT_ANY = 5)),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Oceanborn Invasion",				/datum/event/darkwater,	0,	),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "AI Takeover",						/datum/event/ai_takeover, 			0,	list(ASSIGNMENT_SECURITY = 10)),
		new /datum/event_meta/no_overmap(EVENT_LEVEL_MAJOR, "Meteor Wave",			/datum/event/meteor_wave,			0,	list(ASSIGNMENT_ENGINEER = 10),	1),
		new /datum/event_meta(EVENT_LEVEL_MAJOR, "Space Vines",						/datum/event/spacevine, 			0,	list(ASSIGNMENT_ENGINEER = 15), 1),
		new /datum/event_meta/no_overmap(EVENT_LEVEL_MAJOR, "Electrical Storm",		/datum/event/electrical_storm, 		0,	list(ASSIGNMENT_ENGINEER = 10, ASSIGNMENT_JANITOR = 5))
	)
