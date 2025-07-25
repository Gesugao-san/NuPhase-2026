/decl/material/liquid
	name = null
	melting_point = T0C
	boiling_point = T100C
	opacity = 0.5
	molar_mass = 0.018 //water
	latent_heat = 40650
	abstract_type = /decl/material/liquid
	gas_tile_overlay = "vapor"
	gas_overlay_limit = 0.05

/decl/material/liquid/Initialize()
	if(!gas_name)
		gas_name = "vaporized [name]"
	if(!solid_name)
		solid_name = "frozen [name]"
	. = ..()
