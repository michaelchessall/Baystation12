
/obj/overmap/visitable/var/free_landing = TRUE
/obj/overmap/visitable/var/restricted_area = 50
/obj/overmap/visitable/proc/allow_free_landing(var/datum/shuttle/landing_shuttle)
	return free_landing

/obj/overmap/visitable/ship/landable
	// We forego the use of visitor landmarks, and use free landing instead.
	free_landing = TRUE
	restricted_area = 20

	// Keep track of the landable ship areas and landmark to rebuild the shuttle on load.
	var/list/saved_areas = list()
	var/obj/shuttle_landmark/saved_landmark

// Rebuild the shuttle on load.
/obj/overmap/visitable/ship/landable/Initialize()
	if(!SSshuttle.shuttles[shuttle] && persistent_id)
		if(saved_areas)
			var/list/using_areas = list()
			for(var/area/A in world)
				if(A.a_id in saved_areas)
					using_areas |= A
			if(!get_turf(saved_landmark)) // The landmark was not saved in place, move it.
				saved_landmark.forceMove(get_turf(src))
			var/datum/shuttle/autodock/overmap/created/shuttle_dat = new(null, saved_landmark, using_areas, shuttle)
			shuttle_dat.shuttle_area = using_areas
			shuttle_dat.current_location = saved_landmark
			shuttle_dat.name = shuttle
			SSshuttle.shuttles[shuttle] = shuttle_dat
			SSshuttle.process_shuttles |= shuttle_dat
			if(shuttle_dat.current_location && istype(shuttle_dat.current_location))
				shuttle_dat.current_location.shuttle_arrived(shuttle_dat)
			GLOB.shuttle_moved_event.register(shuttle_dat, src, .proc/on_shuttle_jump)
		else
			log_warning("Landable ship [src] could not rebuild shuttle!")
	saved_landmark = null
	saved_areas.Cut()
	. = ..()

/obj/overmap/visitable/ship/landable/proc/move_to_starting_location()

	if(start_x && start_y)
		forceMove(locate(start_x, start_y,GLOB.using_map.overmap_z))
		return
	..()


/obj/overmap/visitable/ship/landable/on_saving_start(instanceid)
	// In case the ship is landed in a sector, save where the sector is located.
	start_x = loc.x
	start_y = loc.y
	if(isturf(loc))
		var/turf/T = loc
		old_loc = "[T.x],[T.y]"
	else
		old_loc = loc
	// Find where the ship currently is. If the ship is landed, its home z-level won't be saved unless something else is saving it.
	var/datum/shuttle/ship_shuttle = SSshuttle.shuttles[shuttle]
	if(!ship_shuttle || !ship_shuttle.current_location)
		log_error("Could not move the landable ship [src] into its current location!")
		return
	var/turf/shuttle_turf // Locate a safe turf to place the landable ship where it will save.

	if(ship_shuttle.current_location != landmark)
		shuttle_turf = get_turf(ship_shuttle.current_location)
		SSpersistence.AddSavedLevel(shuttle_turf.z)

	for(var/ship_z in map_z)
		SSpersistence.AddSavedLevel(ship_z)

	shuttle_turf = get_turf(ship_shuttle.current_location) // If the entire z-level is saving, the landmark of the shuttle certainly will as well.
	for(var/area/A in ship_shuttle.shuttle_area)
		saved_areas |= "\ref[A]|[instanceid]"

	saved_landmark = ship_shuttle.current_location

	forceMove(shuttle_turf)

// /obj/overmap/visitable/ship/landable/on_saving_end()
// 	saved_areas.Cut()
// 	saved_landmark = null
// 	var/datum/shuttle/ship_shuttle = SSshuttle.shuttles[shuttle]
// 	if(ship_shuttle)
// 		if(ship_shuttle.current_location == landmark)
// 			for(var/ship_z in map_z)
// 				SSpersistence.RemoveSavedLevel(ship_z)
// 		else
// 			for(var/area/A in ship_shuttle.shuttle_area)
// 				SSpersistence.RemoveSavedArea(A)
// 	forceMove(LOAD_CUSTOM_SV("old_loc"))
// 	CLEAR_SV("old_loc")

// The landable ship contains a reference to its landmark, so only save if the ship is in its z-level.
/**
/obj/shuttle_landmark/ship/should_save()
	var/datum/shuttle/S = SSshuttle.shuttles[shuttle_name]
	if(S && S.current_location && S.current_location == src)
		return TRUE
	return FALSE
*/
/obj/shuttle_landmark/ship/Initialize(mapload, shuttle_name)
	if(SSpersistence.in_loaded_world && src.shuttle_name != initial(src.shuttle_name))
		. = ..(mapload, src.shuttle_name) // Used the loaded shuttle_name for tagging and shuttle restriction.
	else
		. = ..()

SAVED_VAR(/obj/overmap/visitable/ship, moving_state)
SAVED_VAR(/obj/overmap/visitable/ship, vessel_size)
SAVED_VAR(/obj/overmap/visitable/ship, burn_delay)
SAVED_VAR(/obj/overmap/visitable/ship, fore_dir)
SAVED_VAR(/obj/overmap/visitable/ship, engines)
SAVED_VAR(/obj/overmap/visitable/ship, skill_needed)
SAVED_VAR(/obj/overmap/visitable/ship, operator_skill)

SAVED_VAR(/obj/overmap/visitable/ship/landable, shuttle)
SAVED_VAR(/obj/overmap/visitable/ship/landable, landmark)
SAVED_VAR(/obj/overmap/visitable/ship/landable, multiz)
SAVED_VAR(/obj/overmap/visitable/ship/landable, status)
SAVED_VAR(/obj/overmap/visitable/ship/landable, saved_landmark)
SAVED_VAR(/obj/overmap/visitable/ship/landable, saved_areas)
