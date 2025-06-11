/obj/structure/reagent_dispensers/watertank
	name = "water tank"
	desc = "A tank containing water."
	icon = 'icons/obj/objects.dmi'
	icon_state = "watertank"
	amount_per_transfer_from_this = 100
	possible_transfer_amounts = @"[10,25,50,100]"
	initial_capacity = 350000
	initial_reagent_types = list(/decl/material/liquid/water = 1)
	atom_flags = ATOM_FLAG_CLIMBABLE
	movable_flags = MOVABLE_FLAG_WHEELED

/obj/structure/reagent_dispensers/watertank/newtank
	icon = 'icons/obj/objects.dmi'
	icon_state = "newwatertank"

/obj/structure/reagent_dispensers/watertank/firefighter
	name = "firefighting water reserve"
	initial_capacity = 50000

/obj/structure/reagent_dispensers/watertank/attackby(obj/item/W, mob/user)
	if((istype(W, /obj/item/robot_parts/l_arm) || istype(W, /obj/item/robot_parts/r_arm)) && user.unEquip(W))
		to_chat(user, "You add \the [W] arm to \the [src].")
		qdel(W)
		new /obj/item/farmbot_arm_assembly(loc, src)
		return TRUE
	. = ..()

/obj/structure/reagent_dispensers/fueltank
	name = "fuel tank"
	desc = "A tank containing welding fuel."
	icon = 'icons/obj/objects.dmi'
	icon_state = "weldtank"
	initial_capacity = 300000
	amount_per_transfer_from_this = 100
	initial_reagent_types = list(/decl/material/liquid/fuel = 1)
	atom_flags = ATOM_FLAG_CLIMBABLE
	movable_flags = MOVABLE_FLAG_WHEELED

	var/obj/item/assembly_holder/rig = null

/obj/structure/reagent_dispensers/fueltank/newtank
	icon = 'icons/obj/objects.dmi'
	icon_state = "newweldtank"

/obj/structure/reagent_dispensers/fueltank/newtank/diesel
	name = "diesel tank"
	desc = "Contains low-quality diesel."
	initial_reagent_types = list(/decl/material/liquid/diesel = 1)

/obj/structure/reagent_dispensers/fueltank/examine(mob/user)
	. = ..()
	if(rig)
		to_chat(user, SPAN_WARNING("There is some kind of device rigged to the tank."))

/obj/structure/reagent_dispensers/fueltank/attack_hand(var/mob/user)
	if (rig)
		visible_message(SPAN_NOTICE("\The [user] begins to detach \the [rig] from \the [src]."))
		if(do_after(user, 20, src))
			visible_message(SPAN_NOTICE("\The [user] detaches \the [rig] from \the [src]."))
			rig.dropInto(loc)
			rig = null
			overlays.Cut()

/obj/structure/reagent_dispensers/fueltank/attackby(obj/item/W, mob/user)
	add_fingerprint(user)
	if(istype(W,/obj/item/assembly_holder))
		if (rig)
			to_chat(user, SPAN_WARNING("There is another device already in the way."))
			return ..()
		visible_message(SPAN_NOTICE("\The [user] begins rigging \the [W] to \the [src]."))
		if(do_after(user, 20, src) && user.unEquip(W, src))
			visible_message(SPAN_NOTICE("\The [user] rigs \the [W] to \the [src]."))
			var/obj/item/assembly_holder/H = W
			if (istype(H.a_left,/obj/item/assembly/igniter) || istype(H.a_right,/obj/item/assembly/igniter))
				log_and_message_admins("rigged a fuel tank for explosion at [loc.loc.name].")
			rig = W
			update_icon()
		return TRUE
	if(W.isflamesource())
		log_and_message_admins("triggered a fuel tank explosion with \the [W].")
		visible_message(SPAN_DANGER("\The [user] puts \the [W] to \the [src]!"))
		try_detonate_reagents()
		return TRUE
	. = ..()

/obj/structure/reagent_dispensers/fueltank/on_update_icon()
	..()
	if(rig)
		var/image/I = new
		I.appearance = rig
		I.pixel_x += 6
		I.pixel_y += 1
		add_overlay(I)

/obj/structure/reagent_dispensers/fueltank/bullet_act(var/obj/item/projectile/Proj)
	if(Proj.get_structure_damage())
		if(istype(Proj.firer))
			var/turf/turf = get_turf(src)
			if(turf)
				var/area/area = turf.loc || "*unknown area*"
				log_and_message_admins("[key_name_admin(Proj.firer)] shot a fuel tank in \the [area.proper_name].")
			else
				log_and_message_admins("shot a fuel tank outside the world.")

		if(!istype(Proj ,/obj/item/projectile/beam/lastertag) && !istype(Proj ,/obj/item/projectile/beam/practice) )
			try_detonate_reagents()

/obj/structure/reagent_dispensers/fueltank/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	if(exposed_temperature > T0C+500)
		try_detonate_reagents()
	return ..()

/obj/structure/reagent_dispensers/peppertank
	name = "pepper spray refiller"
	desc = "Refills pepper spray canisters."
	icon = 'icons/obj/objects.dmi'
	icon_state = "peppertank"
	anchored = 1
	density = 0
	amount_per_transfer_from_this = 45
	initial_reagent_types = list(/decl/material/liquid/capsaicin/condensed = 1)

/obj/structure/reagent_dispensers/water_cooler
	name = "water cooler"
	desc = "A machine that dispenses cool water to drink."
	amount_per_transfer_from_this = 50
	icon = 'icons/obj/vending.dmi'
	icon_state = "water_cooler"
	possible_transfer_amounts = null
	anchored = 1
	initial_capacity = 500
	initial_reagent_types = list(/decl/material/liquid/water = 1)
	tool_interaction_flags = (TOOL_INTERACTION_ANCHOR | TOOL_INTERACTION_DECONSTRUCT)
	var/cups = 12
	var/cup_type = /obj/item/chems/drinks/sillycup

/obj/structure/reagent_dispensers/water_cooler/attack_hand(var/mob/user)
	if(cups > 0)
		var/visible_messages = DispenserMessages(user)
		visible_message(visible_messages[1], visible_messages[2])
		var/cup = new cup_type(loc)
		user.put_in_active_hand(cup)
		cups--
	else
		to_chat(user, RejectionMessage(user))

/obj/structure/reagent_dispensers/water_cooler/proc/DispenserMessages(var/mob/user)
	return list("\The [user] grabs a paper cup from \the [src].", "You grab a paper cup from \the [src]'s cup compartment.")

/obj/structure/reagent_dispensers/water_cooler/proc/RejectionMessage(var/mob/user)
	return "The [src]'s cup dispenser is empty."

/obj/structure/reagent_dispensers/water_cooler/attackby(obj/item/W, mob/user)
	. = ..()
	if(!.)
		flick("[icon_state]-vend", src)
		playsound(src.loc, pick('sound/structures/watercooler/use1.wav', 'sound/structures/watercooler/use2.wav', 'sound/structures/watercooler/use3.wav', 'sound/structures/watercooler/use4.wav'), 50)

/obj/structure/reagent_dispensers/beerkeg
	name = "beer keg"
	desc = "A beer keg."
	icon = 'icons/obj/objects.dmi'
	icon_state = "beertankTEMP"
	amount_per_transfer_from_this = 100
	initial_reagent_types = list(/decl/material/liquid/ethanol/beer = 1)
	atom_flags = ATOM_FLAG_CLIMBABLE

/obj/structure/reagent_dispensers/acid
	name = "sulphuric acid dispenser"
	desc = "A dispenser of acid for industrial processes."
	icon = 'icons/obj/objects.dmi'
	icon_state = "acidtank"
	amount_per_transfer_from_this = 100
	anchored = 1
	initial_reagent_types = list(/decl/material/liquid/acid = 1)

/obj/structure/reagent_dispensers/get_alt_interactions(var/mob/user)
	. = ..()
	LAZYADD(., /decl/interaction_handler/set_transfer/reagent_dispenser)

/decl/interaction_handler/set_transfer/reagent_dispenser
	expected_target_type = /obj/structure/reagent_dispensers

/decl/interaction_handler/set_transfer/reagent_dispenser/is_possible(var/atom/target, var/mob/user)
	. = ..()
	if(.)
		var/obj/structure/reagent_dispensers/R = target
		return !!R.possible_transfer_amounts

/decl/interaction_handler/set_transfer/reagent_dispenser/invoked(var/atom/target, var/mob/user)
	var/obj/structure/reagent_dispensers/R = target
	R.set_amount_per_transfer_from_this()