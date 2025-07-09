#define WORLD_ICON_SIZE 32

//#define DEBUG_ENVIRONMENT // If defined, only loads the testing map.

//This file is just for the necessary /world definition
//Try looking in game/world.dm

/world
	mob = /mob/new_player
	turf = /turf/space
	area = /area/space
	view = "15x21"
	cache_lifespan = 7
	hub = "Exadv1.spacestation13"
	icon_size = WORLD_ICON_SIZE
	fps = 60
	movement_mode = PIXEL_MOVEMENT_MODE

#ifdef GC_FAILURE_HARD_LOOKUP
	loop_checks = FALSE
#endif
