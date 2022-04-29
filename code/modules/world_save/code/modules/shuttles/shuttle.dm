/datum/shuttle
	var/finalized = 0
	var/owner // Owner, person or faction
	var/ownertype = 1 // 1 = personal, 2 = factional
	var/obj/machinery/computer/bridge_computer/bridge // The shuttle bridge computer
	var/size = 1 // size of shuttle
	var/initial_location
/datum/shuttle/proc/setup()
	if(!islist(shuttle_area))
		if(shuttle_area)
			shuttle_area = list(shuttle_area)
		else
			shuttle_area = list()

	if(initial_location)
		current_location = initial_location
	else
		current_location = locate(current_location)

	SSshuttle.shuttles[src.name] = src
	if(flags & SHUTTLE_FLAGS_PROCESS)
		SSshuttle.process_shuttles += src

//	if(flags & SHUTTLE_FLAGS_SUPPLY)
//		if(supply_controller.shuttle)
//			CRASH("A supply shuttle is already defined.")
//		supply_controller.shuttle = src
	if(!istype(current_location))
		CRASH("Shuttle \"[name]\" could not find its starting location.")

/datum/shuttle/proc/get_corner_turf()
	var/list/turfs = list()
	for(var/area/A in shuttle_area)
		for(var/turf/T in A.contents)
			turfs |= T
	var/turf/corner
	for(var/turf/T in turfs)
		if(!corner || (T.x <= corner.x && T.y <= corner.y))
			corner = T
	return corner
