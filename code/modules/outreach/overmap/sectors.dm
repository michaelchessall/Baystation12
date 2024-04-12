var/global/list/saved_overmap = list()
SAVED_VAR(/obj/overmap/visitable, old_loc)
/obj/overmap/visitable
	should_save = TRUE 		 // Overmap sectors move themselves from the overmap to either a z-level or an area for landable ships on save.TRUE
					 		 // If the area or z-level is saved, the overmap effect will be saved.
	var/atom/old_loc	 	 // Where the ship was prior to saving. Used to relocate the ship following saving, not on load.

/obj/overmap/visitable/Initialize()
	. = ..()
	saved_overmap |= src

/obj/overmap/visitable/proc/on_saving_start(instanceid)
	// Record where to replace the sector upon reinitialization
	start_x = x
	start_y = y
	if(isturf(loc))
		var/turf/T = loc
		old_loc = "[T.x],[T.y]"
	else
		old_loc = loc

	for(var/ship_z in map_z)
		SSpersistence.AddSavedLevel(ship_z)
	// Force move the sector to its z level(s) so that it can properly reinitialize.
	forceMove(locate(world.maxx/2, world.maxy/2, max(map_z)))


/obj/overmap/visitable/proc/on_saving_end()
	if(isobj(old_loc))
		forceMove(old_loc)
	else
		var/list/ex = splittext(old_loc, ",")
		var/turf/turf = locate(text2num(ex[1]), text2num(ex[2]), GLOB.using_map.overmap_z)
		forceMove(turf)
