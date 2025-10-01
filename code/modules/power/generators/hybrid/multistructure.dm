/obj/structure/reactor_superstructure
	name = "C.C-F.R-1900"
	desc = "Nuclear Fusion-Fission Reactor hanged on a giant support structure."
	anchored = TRUE
	layer = ABOVE_HUMAN_LAYER
	appearance_flags = PIXEL_SCALE | LONG_GLIDE
	icon = 'icons/obj/machines/power/fusion_reactor.dmi'
	icon_state = "map"
	pixel_y = -208
	pixel_x = -208
	var/datum/sound_token/sound_token
	var/sound_id

/obj/structure/reactor_superstructure/Initialize(ml, _mat, _reinf_mat)
	. = ..()
	sound_id = "[/obj/structure/reactor_superstructure]_[sequential_id(/obj/structure/reactor_superstructure)]"
	add_filter("glow", 1, list(type="drop_shadow", x = 0, y = 0, offset = 0, size = 0))
	reactor_components["superstructure"] = src
	icon_state = "core"
	add_overlay(overlay_image(icon, "comms"))
	add_overlay(overlay_image(icon, "lasers"))

/obj/structure/reactor_superstructure/Destroy()
	. = ..()
	qdel(sound_token)

/obj/structure/reactor_superstructure/proc/startsound()
	sound_token = play_looping_sound(src, sound_id, 'sound/machines/reactorloop.ogg', 100, 15, 7)

var/list/global/reactor_ports = list()

/obj/machinery/atmospherics/unary/reactor_exchanger
	icon = 'icons/obj/atmospherics/components/unary/connector.dmi'
	icon_state = "map_connector"

	name = "reactor port"

	dir = SOUTH
	initialize_directions = SOUTH

	use_power = POWER_USE_OFF
	interact_offline = TRUE

	uncreated_component_parts = null
	frame_type = /obj/item/pipe
	construct_state = /decl/machine_construction/pipe

	level = 1

	connect_types = CONNECT_TYPE_REGULAR|CONNECT_TYPE_FUEL
	build_icon_state = "connector"

	pipe_class = PIPE_CLASS_UNARY
	var/target_temperature = 4500

/obj/machinery/atmospherics/unary/reactor_exchanger/Initialize()
	. = ..()
	air_contents.volume = 800000

/obj/machinery/atmospherics/unary/reactor_exchanger/Process()
	. = ..()
	var/obj/machinery/power/hybrid_reactor/core = reactor_components["core"]
	var/datum/gas_mixture/coregas = core.containment_field
	if(coregas.temperature > target_temperature) //we consoom
		var/latent_heat_energy = 0
		for(var/f_type in air_contents.solids)
			var/decl/material/mat = GET_DECL(f_type)
			latent_heat_energy += air_contents.solids[f_type] * mat.latent_heat
		var/temperature_delta = target_temperature - air_contents.temperature
		var/required_energy = (air_contents.heat_capacity() * temperature_delta) + latent_heat_energy
		coregas.add_thermal_energy(required_energy * -1)
		air_contents.add_thermal_energy(required_energy)


/obj/machinery/atmospherics/unary/reactor_connector
	icon = 'icons/obj/atmospherics/components/unary/connector.dmi'
	icon_state = "map_connector"

	name = "reactor port"

	dir = SOUTH
	initialize_directions = SOUTH

	use_power = POWER_USE_OFF
	interact_offline = TRUE

	uncreated_component_parts = null
	frame_type = /obj/item/pipe
	construct_state = /decl/machine_construction/pipe

	level = 1

	connect_types = CONNECT_TYPE_REGULAR|CONNECT_TYPE_FUEL
	build_icon_state = "connector"

	pipe_class = PIPE_CLASS_UNARY
	var/obj/machinery/atmospherics/unary/reactor_connector/linked = null

/obj/machinery/atmospherics/unary/reactor_connector/on_update_icon()
	icon_state = "connector"
	build_device_underlays(FALSE)

/obj/machinery/atmospherics/unary/reactor_connector/Initialize()
	. = ..()
	air_contents.volume = 2000

/obj/machinery/atmospherics/unary/reactor_connector/hide(var/i)
	update_icon()

/obj/machinery/atmospherics/unary/reactor_connector/ingoing
/obj/machinery/atmospherics/unary/reactor_connector/outgoing

/obj/machinery/atmospherics/unary/reactor_connector/ingoing/Initialize()
	. = ..()
	reactor_ports["[uid]-in"] = src
	spawn(100)
		linked = reactor_ports["[uid]-out"]

/obj/machinery/atmospherics/unary/reactor_connector/outgoing/Initialize()
	. = ..()
	STOP_PROCESSING_MACHINE(src, MACHINERY_PROCESS_SELF)
	reactor_ports["[uid]-out"] = src
	spawn(100)
		linked = reactor_ports["[uid]-in"]
		START_PROCESSING_MACHINE(src, MACHINERY_PROCESS_SELF)

/obj/machinery/atmospherics/unary/reactor_connector/outgoing/Process()
	. = ..()
	if(linked)
		air_contents.merge(linked.air_contents)
		linked.air_contents.remove_ratio(1)

/obj/structure/reactor_table
	name = "large table"
	anchored = 1
	density = 1
	opacity = 0
	layer = STRUCTURE_LAYER
	icon = 'icons/obj/structures/reactor_panel.dmi'