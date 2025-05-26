/mob/living/carbon/human/monkey/punpun
	real_name = "Pun Pun"
	gender = MALE

/mob/living/carbon/human/monkey/punpun/Initialize()
	. = ..()
	var/obj/item/clothing/C
	if(prob(50))
		C = new /obj/item/clothing/under/waiter/monke(src)
		equip_to_appropriate_slot(C)
	else
		C = new /obj/item/clothing/pants/casual/mustangjeans/monke(src)
		C.attach_accessory(null, new/obj/item/clothing/accessory/toggleable/hawaii/random(src))
		equip_to_appropriate_slot(C)
		if(prob(10))
			C = new/obj/item/clothing/head/collectable/petehat(src)
			equip_to_appropriate_slot(C)

/decl/hierarchy/outfit/blank_subject
	name = "Test Subject"
	uniform = /obj/item/clothing/under/color/white
	shoes = /obj/item/clothing/shoes/color/white
	head = /obj/item/clothing/head/helmet/facecover
	mask = /obj/item/clothing/mask/muzzle
	suit = /obj/item/clothing/suit/straight_jacket

/decl/hierarchy/outfit/blank_subject/post_equip(mob/living/carbon/human/H)
	..()
	var/obj/item/clothing/under/color/white/C = locate() in H
	if(C)
		C.has_sensor  = SUIT_LOCKED_SENSORS
		C.sensor_mode = SUIT_SENSOR_OFF

/mob/living/carbon/human/blank/Initialize(mapload)
	. = ..(mapload, SPECIES_HUMAN)
	var/number = "[pick(possible_changeling_IDs)]-[rand(1,30)]"
	fully_replace_character_name("Subject [number]")
	var/decl/hierarchy/outfit/outfit = outfit_by_type(/decl/hierarchy/outfit/blank_subject)
	outfit.equip(src)
	var/obj/item/clothing/head/helmet/facecover/F = locate() in src
	if(F)
		F.SetName("[F.name] ([number])")

/mob/living/carbon/human/blank/ssd_check()
	return FALSE

/mob/living/carbon/human/shelter_npc
	var/list/possible_outfits = list(/decl/hierarchy/outfit/job/cargo/cargo_tech)

/mob/living/carbon/human/shelter_npc/Initialize(mapload, species_name, datum/dna/new_dna)
	. = ..(mapload, SPECIES_HUMAN)
	randomize_gender()
	var/decl/pronouns/new_pronouns = get_pronouns_by_gender(get_sex())
	pronouns = new_pronouns
	var/new_bodytype = species.get_bodytype_by_pronouns(new_pronouns)
	set_bodytype(new_bodytype)
	randomize_skin_tone()
	randomize_hair_style()
	randomize_facial_hair_style()
	randomize_eye_color()
	var/decl/cultural_info/culture = get_cultural_value(TAG_CULTURE)
	SetName(src, culture.get_random_name(gender))
	real_name = name
	var/decl/hierarchy/outfit/corpse_outfit = outfit_by_type(pickweight(possible_outfits))
	corpse_outfit.equip(src)
	update_icon()

/mob/living/carbon/human/shelter_npc/ssd_check()
	return FALSE

/mob/living/carbon/human/limb/handle_regular_hud_updates()
	if(hud_updateflag) // update our mob's hud overlays, AKA what others see flaoting above our head
		handle_hud_list()
	if(!client)	return 0
	handle_hud_icons()
	handle_vision()

	if(stat != DEAD)
		overlay_fullscreen("crit", /obj/screen/fullscreen/crit, 4) //fog overlay

		//Fire and Brute damage overlay (BSSR)
		var/hurtdamage = src.getBruteLoss() + src.getFireLoss() + damageoverlaytemp
		damageoverlaytemp = 0 // We do this so we can detect if someone hits us or not.
		if(hurtdamage)
			var/severity = 0
			switch(hurtdamage)
				if(10 to 25)		severity = 1
				if(25 to 40)		severity = 2
				if(40 to 55)		severity = 3
				if(55 to 70)		severity = 4
				if(70 to 85)		severity = 5
				if(85 to INFINITY)	severity = 6
			overlay_fullscreen("brute", /obj/screen/fullscreen/brute, severity)
		else
			clear_fullscreen("brute")

		if(healths)

			var/mutable_appearance/healths_ma = new(healths)
			healths_ma.icon_state = "blank"
			healths_ma.overlays = null

			if(has_chemical_effect(CE_PAINKILLER, 100))
				healths_ma.icon_state = "health_numb"
			else
				// Generate a by-limb health display.
				var/no_damage = 1
				var/trauma_val = 0 // Used in calculating softcrit/hardcrit indicators.
				if(can_feel_pain())
					trauma_val = max(shock_stage,get_shock())/(species.total_health-100)
				// Collect and apply the images all at once to avoid appearance churn.
				var/list/health_images = list()
				for(var/obj/item/organ/external/E in get_external_organs())
					if(no_damage && (E.brute_dam || E.burn_dam))
						no_damage = 0
					health_images += E.get_damage_hud_image()

				// Apply a fire overlay if we're burning.
				if(on_fire)
					health_images += image('icons/hud/screen1_health.dmi',"burning")

				// Show a general pain/crit indicator if needed.
				if(is_asystole())
					health_images += image('icons/hud/screen1_health.dmi',"hardcrit")
				else if(trauma_val)
					if(can_feel_pain())
						if(trauma_val > 0.7)
							health_images += image('icons/hud/screen1_health.dmi',"softcrit")
						if(trauma_val >= 1)
							health_images += image('icons/hud/screen1_health.dmi',"hardcrit")
				else if(no_damage)
					health_images += image('icons/hud/screen1_health.dmi',"fullhealth")
				healths_ma.overlays += health_images
			healths.appearance = healths_ma

		if(bodytemp)
			if (!species)
				switch(bodytemperature) //310.055 optimal body temp
					if(370 to INFINITY)		bodytemp.icon_state = "temp4"
					if(350 to 370)			bodytemp.icon_state = "temp3"
					if(335 to 350)			bodytemp.icon_state = "temp2"
					if(320 to 335)			bodytemp.icon_state = "temp1"
					if(300 to 320)			bodytemp.icon_state = "temp0"
					if(295 to 300)			bodytemp.icon_state = "temp-1"
					if(280 to 295)			bodytemp.icon_state = "temp-2"
					if(260 to 280)			bodytemp.icon_state = "temp-3"
					else					bodytemp.icon_state = "temp-4"
			else
				//TODO: precalculate all of this stuff when the species datum is created
				var/base_temperature = species.body_temperature
				if(base_temperature == null) //some species don't have a set metabolic temperature
					base_temperature = (getSpeciesOrSynthTemp(HEAT_LEVEL_1) + getSpeciesOrSynthTemp(COLD_LEVEL_1))/2

				var/temp_step
				if (bodytemperature >= base_temperature)
					temp_step = (getSpeciesOrSynthTemp(HEAT_LEVEL_1) - base_temperature)/4

					if (bodytemperature >= getSpeciesOrSynthTemp(HEAT_LEVEL_1))
						bodytemp.icon_state = "temp4"
					else if (bodytemperature >= base_temperature + temp_step*3)
						bodytemp.icon_state = "temp3"
					else if (bodytemperature >= base_temperature + temp_step*2)
						bodytemp.icon_state = "temp2"
					else if (bodytemperature >= base_temperature + temp_step*1)
						bodytemp.icon_state = "temp1"
					else
						bodytemp.icon_state = "temp0"

				else if (bodytemperature < base_temperature)
					temp_step = (base_temperature - getSpeciesOrSynthTemp(COLD_LEVEL_1))/4

					if (bodytemperature <= getSpeciesOrSynthTemp(COLD_LEVEL_1))
						bodytemp.icon_state = "temp-4"
					else if (bodytemperature <= base_temperature - temp_step*3)
						bodytemp.icon_state = "temp-3"
					else if (bodytemperature <= base_temperature - temp_step*2)
						bodytemp.icon_state = "temp-2"
					else if (bodytemperature <= base_temperature - temp_step*1)
						bodytemp.icon_state = "temp-1"
					else
						bodytemp.icon_state = "temp0"
	return 1

/mob/living/carbon/human/limb/verb/respawn()
	set name = "Respawn"
	set category = "OOC"

	if (!get_config_value(/decl/config/toggle/on/abandon_allowed))
		to_chat(usr, SPAN_WARNING("Respawn is disabled."))
		return
	if (!SSticker.mode)
		to_chat(usr, SPAN_WARNING("<b>You may not attempt to respawn yet.</b>"))
		return
	if (SSticker.mode.deny_respawn)
		to_chat(usr, SPAN_WARNING("Respawn is disabled for this roundtype."))
		return
	else if(!MayRespawn(1, get_config_value(/decl/config/num/respawn_delay)))
		return

	to_chat(usr, SPAN_NOTICE("You can respawn now, enjoy your new life!"))
	to_chat(usr, SPAN_NOTICE("<b>Make sure to play a different character, and please roleplay correctly!</b>"))
	announce_ghost_joinleave(client, 0)

	var/mob/new_player/M = new /mob/new_player()
	M.key = key
	log_and_message_admins("has respawned.", M)

/mob/living/carbon/human/limb/MayRespawn(var/feedback = 0, var/respawn_time = 0)
	if(!client)
		return 0
	if(limb_mob.stat != DEAD)
		if(feedback)
			to_chat(src, "<span class='warning'>Your non-dead body prevents you from respawning.</span>")
		return 0

	//var/timedifference = world.time - timeofdeath
	//if(!client.holder && respawn_time && timeofdeath && timedifference < respawn_time MINUTES)
	//	var/timedifference_text = time2text(respawn_time MINUTES - timedifference,"mm:ss")
	//	to_chat(src, "<span class='warning'>You must have been dead for [respawn_time] minute\s to respawn. You have [timedifference_text] left.</span>")
	//	return 0

	return 1