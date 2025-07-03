var/global/obj/reactions_reagents_holder = new

SUBSYSTEM_DEF(reactions)
	name = "Reactions"
	wait = 2 SECONDS
	priority = SS_PRIORITY_REACTIONS
	flags = SS_NO_INIT | SS_NO_FIRE

	var/list/fusion_reactions = list()

/datum/controller/subsystem/reactions/proc/process_gasmix(datum/gas_mixture/gasmix)
	var/list/all_fluid = gasmix.get_fluid()

	var/list/react_list = process_reactions(all_fluid.Copy(), gasmix.temperature, gasmix.heat_capacity(), gasmix.pressure, gasmix.volume)
	var/list/result_fluid = react_list[1]

	var/list/combined_list = result_fluid.Copy()
	combined_list.Add(all_fluid.Copy())

	for(var/f_type in combined_list)
		if(result_fluid[f_type] == all_fluid[f_type]) // no change
			continue
		var/difference = result_fluid[f_type] - all_fluid[f_type]
		gasmix.adjust_gas(f_type, difference, FALSE)

	gasmix.temperature = react_list[2]
	gasmix.update_values()

	/*
	if(length(gasmix.gas))
		var/list/reacted_list = process_reactions(gasmix.gas, gasmix.temperature, null, gasmix.pressure, gasmix.volume)
		gasmix.gas = reacted_list[1]
		gasmix.temperature = reacted_list[2]
	if(length(gasmix.liquids))
		var/list/reacted_list = process_reactions(gasmix.liquids, gasmix.temperature, null, gasmix.pressure, gasmix.volume)
		gasmix.liquids = reacted_list[1]
		gasmix.temperature = reacted_list[2]
	if(length(gasmix.solids))
		var/list/reacted_list = process_reactions(gasmix.solids, gasmix.temperature, null, gasmix.pressure, gasmix.volume)
		gasmix.solids = reacted_list[1]
		gasmix.temperature = reacted_list[2]
	*/

/datum/controller/subsystem/reactions/proc/process_reactions(list/moles, temperature, heat_capacity, pressure = ONE_ATMOSPHERE, volume)
	var/has_fuel = FALSE
	var/has_oxidizer = FALSE
	var/old_temperature = temperature
	for(var/g in moles)
		var/decl/material/mat = GET_DECL(g)
		if(mat.combustion_energy)
			has_fuel = TRUE
		if(mat.oxidizer_power)
			has_oxidizer = TRUE
	if(!heat_capacity)
		heat_capacity = 0
		for(var/g in moles)
			var/decl/material/mat = GET_DECL(g)
			heat_capacity += moles[g] * mat.gas_specific_heat

	var/list/chem_return_list = process_reaction_chem(moles, temperature, heat_capacity, pressure, volume)
	moles = chem_return_list[1]
	temperature = chem_return_list[2]

	// Process combustion
	if(has_fuel && has_oxidizer)
		var/list/return_list = process_reaction_oxidation(moles, temperature, heat_capacity, pressure, volume)
		moles = return_list[1]
		temperature = return_list[2]
		heat_capacity = return_list[3]
		pressure = return_list[4]

	return list(moles, temperature, old_temperature)

#define PRE_EXPONENTIAL_FACTOR 10**7
// n = concentration * k
// concentration is in moles per liter
/datum/controller/subsystem/reactions/proc/get_reaction_rate(reactant_moles, activation_energy, temperature, volume)
	return min(reactant_moles, (reactant_moles/volume) * get_reaction_rate_constant(activation_energy, temperature))

// k = PRE_EXPONENTIAL_FACTOR * EULER**-(activation_energy/8.314*temperature)
/datum/controller/subsystem/reactions/proc/get_reaction_rate_constant(activation_energy, temperature)
	return PRE_EXPONENTIAL_FACTOR * EULER**(-(activation_energy/(8.314*temperature)))

#undef PRE_EXPONENTIAL_FACTOR

/datum/controller/subsystem/reactions/proc/process_reaction_chem(list/moles, temperature, heat_capacity, pressure = ONE_ATMOSPHERE, volume)
	reactions_reagents_holder.temperature = temperature
	var/datum/reagents/temp_holder = new((volume*1000)*(pressure/ONE_ATMOSPHERE), reactions_reagents_holder)
	for(var/mat_type in moles)
		var/decl/material/mat = GET_DECL(mat_type)
		LAZYSET(temp_holder.reagent_volumes, mat_type, moles[mat_type] * mat.molar_volume)
	temp_holder.update_total()
	temp_holder.process_reactions()
	moles.Cut()
	for(var/mat_type in temp_holder.reagent_volumes)
		var/decl/material/mat = GET_DECL(mat_type)
		moles[mat_type] = temp_holder.reagent_volumes[mat_type] / mat.molar_volume
	return list(moles, reactions_reagents_holder.temperature)

/datum/controller/subsystem/reactions/proc/process_reaction_oxidation(list/moles, temperature, heat_capacity, pressure = ONE_ATMOSPHERE, volume)
	var/list/oxidizers = list()
	var/list/oxidizers_by_power = list()
	var/list/fuels = list()
	var/thermal_energy = temperature * heat_capacity
	var/total_moles = 0
	for(var/g in moles)
		total_moles += moles[g]
		var/decl/material/mat = GET_DECL(g)
		if(mat.combustion_energy && mat.combustion_products)
			fuels[g] = moles[g]
		if(mat.oxidizer_power)
			oxidizers_by_power[g] = mat.oxidizer_power

	// Sort oxidizers and use the one with the lowest oxidizer_power first.
	oxidizers_by_power = sortTim(oxidizers_by_power, /proc/cmp_numeric_asc, TRUE)
	for(var/g in oxidizers_by_power)
		oxidizers[g] = moles[g]

	// Remove all reactants from the fuel list temporarily
	moles.Remove(oxidizers, fuels)

	for(var/g in oxidizers)
		for(var/f in fuels)
			var/decl/material/fuel_mat = GET_DECL(f)
			if(thermal_energy * fuels[f] < fuel_mat.combustion_activation_energy * total_moles)
				continue
			var/need_fuel_moles = oxidizers[g] / fuel_mat.oxidizer_to_fuel_ratio
			var/actually_spent_fuel = min(fuels[f], need_fuel_moles, oxidizers_by_power[g] * get_reaction_rate(fuels[f], fuel_mat.combustion_activation_energy, temperature, volume))
			var/actually_spent_oxidizer = actually_spent_fuel * fuel_mat.oxidizer_to_fuel_ratio
			var/product
			if(fuel_mat.combustion_products[g])
				product = fuel_mat.combustion_products[g]
			else
				product = fuel_mat.combustion_products[/decl/material/gas/oxygen]
			fuels[f] -= actually_spent_fuel
			oxidizers[g] -= actually_spent_oxidizer
			moles[product] += actually_spent_fuel
			thermal_energy += actually_spent_fuel * fuel_mat.combustion_energy
			if(!oxidizers[g])
				break

	for(var/g in oxidizers)
		moles[g] += oxidizers[g]
	for(var/g in fuels)
		moles[g] += fuels[g]
	temperature = thermal_energy / heat_capacity

	return list(moles, temperature, heat_capacity, pressure)

/datum/controller/subsystem/reactions/proc/test_combustion(mob/user)
	to_chat(user, "--------------------")
	for(var/i=1, i<20, i++)
		var/list/react_result = process_reactions(list(/decl/material/gas/hydrogen = 60, /decl/material/gas/oxygen = 30), 100*i, 6600, volume = 1000)
		to_chat(user, "T: [100*i] ===> T: [round(react_result[2], 0.1)] H: [round(react_result[1][/decl/material/gas/hydrogen], 0.1)] O: [round(react_result[1][/decl/material/gas/oxygen], 0.1)]")
	to_chat(user, "--------------------")
	for(var/i=1, i<20, i++)
		var/list/react_result = process_reactions(list(/decl/material/gas/hydrogen = 300/i, /decl/material/gas/oxygen = 30), 3500, 6600, volume = 1000)
		to_chat(user, "T: 3500 ===> T: [round(react_result[2], 0.1)] H: [round(react_result[1][/decl/material/gas/hydrogen], 0.1)] O: [round(react_result[1][/decl/material/gas/oxygen], 0.1)]")
	to_chat(user, "--------------------")