#define MAX_DOCKING_SIZE 30
#define MAX_SHIP_TILES 	400
#define MAX_NAME_LENGTH  30

#define SHIP_CLASS_CRAFT 7
#define SHIP_CLASS_CORVETTE 13
#define SHIP_CLASS_FRIGATE 19

/proc/getShipClassName(var/ship_class)
	switch(ship_class)
		if(SHIP_CLASS_CRAFT)
			return "craft"
		if(SHIP_CLASS_CORVETTE)
			return "corvette"
		if(SHIP_CLASS_FRIGATE)
			return "frigate"

/obj/machinery/docking_beacon
	name = "magnetic docking beacon"
	desc = "A magnetic docking beacon that coordinates the movement of spacecraft into secure locations. It can additionally be used as a drydock for constructing shuttles."
	icon = 'icons/obj/machines/dock_beacon.dmi'
	icon_state = "unpowered2"
	density = TRUE
	anchored = FALSE
	construct_state = /singleton/machine_construction/default/panel_closed
	uncreated_component_parts = null
	stat_immune = MACHINE_STAT_NOPOWER
	base_type = /obj/machinery/docking_beacon
	obj_flags = OBJ_FLAG_ROTATABLE
	var/display_name					 // Display name of the docking beacon, editable on the docking control program.
	var/list/permitted_shuttles = list() // Shuttles that are always permitted by the docking beacon.

	var/locked = TRUE
	var/docking_by_codes = FALSE		 // Whether or not docking by code is permitted.
	var/docking_codes = 0				 // Required code for docking by code.
	var/docking_width = 10
	var/docking_height = 10
	var/projecting = FALSE

	var/construction_mode = FALSE		 // Whether or not the docking beacon is constructing a ship.
	var/ship_name = ""
	var/ship_color = COLOR_WHITE
	var/list/errors

	var/connected_to = ""
	var/connection_type = 1

	var/max_ship_size = SHIP_CLASS_CORVETTE


/obj/machinery/docking_beacon/Initialize()
	. = ..()
	SSshuttle.docking_beacons += src

/obj/machinery/docking_beacon/Destroy()
	. = ..()
	SSshuttle.docking_beacons -= src
	permitted_shuttles.Cut()



/obj/machinery/docking_beacon/interface_interact(mob/user)
	ui_interact(user)
	return TRUE

/obj/machinery/docking_beacon/ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = 1, master_ui = null, datum/topic_state/state = GLOB.default_state)
	var/list/data = list()
	data["faction_beacon"] = !!connection_type

	data["size"] = "[docking_width] x [docking_height]"
	data["locked"] = locked
	data["display_name"] = display_name
	data["allow_codes"] = docking_by_codes
	if(allowed(user))
		data["permitted"] = permitted_shuttles
		data["codes"] = docking_codes
	else
		data["permitted"] = list("ACCESS DENIED")
		data["codes"] = "*******"

	data["construction_mode"] = construction_mode
	data["errors"] = errors
	data["ship_name"] = ship_name
	data["ship_color"] = ship_color

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data)
	if (!ui)
		ui = new(user, src, ui_key, "docking_beacon.tmpl", "Docking Beacon Settings", 540, 400, state = state)
		ui.set_initial_data(data)
		ui.open()

/obj/machinery/docking_beacon/OnTopic(mob/user, href_list, datum/topic_state/state)
	. = ..()
	if(.)
		return


	if(href_list["edit_codes"])
		var/newcode = sanitize(input("Input new docking codes:", "Docking codes", docking_codes) as text|null)
		if(!CanInteract(usr,state))
			return TOPIC_NOACTION
		if(newcode)
			docking_codes = uppertext(newcode)
			return TOPIC_REFRESH

	if(href_list["edit_display_name"])
		var/newname = sanitize(input("Input new display name:", "Display name", display_name) as text|null)
		if(!CanInteract(usr,state))
			return TOPIC_NOACTION
		if(newname)
			display_name = newname
			return TOPIC_REFRESH
		return TOPIC_HANDLED

	if(href_list["edit_size"])
		var/newwidth = input("Input new docking width for beacon:", "Docking size", docking_width) as num|null
		var/newheight = input("Input new docking height for beacon:", "Docking size", docking_height) as num|null
		if(!CanInteract(usr,state))
			return TOPIC_NOACTION
		if(newwidth && newheight)
			docking_width = clamp(newwidth, 0, MAX_DOCKING_SIZE)
			docking_height = clamp(newheight, 0, MAX_DOCKING_SIZE)
			return TOPIC_REFRESH
		return TOPIC_HANDLED

	if(href_list["toggle_lock"])
		locked = !locked
		return TOPIC_REFRESH

	if(href_list["toggle_codes"])
		docking_by_codes = !docking_by_codes
		return TOPIC_REFRESH

	if(href_list["edit_permitted_shuttles"])
		var/shuttle = sanitize(input(usr,"Enter the ID of the shuttle you wish to permit/unpermit for this beacon:", "Enter ID") as text|null)
		if(shuttle)
			if(shuttle in permitted_shuttles)
				permitted_shuttles -= shuttle
				return TOPIC_REFRESH
			else if(shuttle in SSshuttle.shuttles)
				permitted_shuttles += shuttle
				return TOPIC_REFRESH
		return TOPIC_HANDLED

	if(href_list["project"])
		if(projecting)
			return
		visible_message(SPAN_NOTICE("\The [src] projects a hologram of its effective landing area."))
		for(var/turf/T in get_turfs())
			new /obj/effect/temporary(T, 5 SECONDS,'icons/effects/alphacolors.dmi', "green")
			projecting = TRUE
			addtimer(new Callback(src, .proc/allow_projection), 10 SECONDS) // No spamming holograms.

	if(href_list["settings"])
		return TOPIC_HANDLED

	if(href_list["toggle_construction"])
		construction_mode = !construction_mode
		LAZYCLEARLIST(errors)
		return TOPIC_REFRESH

	if(href_list["change_color"])
		var/new_color = input(user, "Choose a color.", "\the [src]", ship_color) as color|null
		if(!CanInteract(usr,state))
			return TOPIC_NOACTION
		if(new_color && new_color != ship_color)
			ship_color = new_color
			to_chat(user, SPAN_NOTICE("You set \the [src] to create a ship with <font color='[ship_color]'>this color</font>."))
			return TOPIC_HANDLED

	if(href_list["change_ship_name"])
		var/new_ship_name = sanitize(input(user, "Enter a new name for the ship:", "Change ship name.") as null|text)
		if(!CanInteract(usr,state))
			return TOPIC_NOACTION
		if(!new_ship_name)
			return TOPIC_HANDLED
		if(length(new_ship_name) > MAX_NAME_LENGTH)
			to_chat(user, SPAN_WARNING("That name is too long!"))
			return TOPIC_HANDLED
		ship_name = new_ship_name
		return TOPIC_REFRESH

	if(href_list["check_validity"])
		if(!construction_mode)
			return TOPIC_HANDLED
		check_ship_validity(get_areas())
		return TOPIC_REFRESH

	if(href_list["finalize"])
		if(!construction_mode)
			return TOPIC_HANDLED
		var/confirm = alert(user, "This will permanently finalize the ship, are you sure?", "Ship finalization", "No", "Yes")
		if(!CanInteract(usr,state))
			return TOPIC_NOACTION
		if(confirm == "Yes")
			if(create_ship())
				construction_mode = FALSE
				ship_name = ""
				LAZYCLEARLIST(errors)
			else
				to_chat(usr, SPAN_WARNING("Could not finalize the construction of the ship!"))
		return TOPIC_REFRESH

/obj/machinery/docking_beacon/proc/allow_projection()
	projecting = FALSE

/obj/machinery/docking_beacon/proc/check_permission(var/shuttle_tag, var/codes)
	. = FALSE
	if(construction_mode)
		return
	if(!locked)
		return TRUE
	if(docking_by_codes && docking_codes == codes)
		return TRUE
	if(shuttle_tag in permitted_shuttles)
		return TRUE

/obj/machinery/docking_beacon/proc/get_turfs()
	switch(dir)
		if(NORTH)
			return block(locate(x-((docking_width-1)/2), y+docking_height+1, z), locate(x+((docking_width-1)/2), y+1, z))
		if(SOUTH)
			return block(locate(x-((docking_width-1)/2), y-docking_height-1, z), locate(x+((docking_width-1)/2), y-1, z))
		if(EAST)
			return block(locate(x+docking_height+1, y-((docking_width-1)/2), z), locate(x+1, y+((docking_width-1)/2), z))
		if(WEST)
			return block(locate(x-docking_height-1, y-((docking_width-1)/2), z), locate(x-1, y+((docking_width-1)/2), z))

/obj/machinery/docking_beacon/proc/get_docking_turf()
	var/turf/T
	switch(dir)
		if(NORTH)
			T = locate(x, y+docking_height+1+1, z)
		if(SOUTH)
			T = loc
		if(EAST)
			T = locate(x+(docking_height/2)+1, y+((docking_width-1)/2)+1, z)
		if(WEST)
			T = locate(x-(docking_height/2)-1, y+((docking_width-1)/2)+1, z)
	if(T)
		var/area/base_area
		var/obj/overmap/visitable/O = map_sectors["[z]"]
		if(O && istype(O))
			base_area = O.base_area
		if(!base_area)
			return

		var/obj/shuttle_landmark/temporary/lz = new(T, 1)
		lz.base_area = base_area
		lz.base_turf = get_base_turf(z)
		return lz

/obj/machinery/docking_beacon/proc/get_areas()
	. = list()
	for(var/turf/T in get_turfs())
		var/area/A = T.loc
		// Ignore space or other background areas.
		if((istype(A, /area/space) || istype(A, /area/exoplanet)))
			continue
		if(A in SSshuttle.shuttle_areas)
			continue
		. |= A

/obj/machinery/docking_beacon/proc/check_ship_validity(var/list/target_areas)
	LAZYCLEARLIST(errors)
	. = TRUE
	if(!ship_name || length(ship_name) < 5)
		LAZYDISTINCTADD(errors, "The ship must have a name.")
		. = FALSE
	else
		// Check if another ship/shuttle has an identical name.
		for(var/shuttle_tag in SSshuttle.shuttles)
			if(ship_name == shuttle_tag)
				LAZYDISTINCTADD(errors, "A ship with an identical name has already been registered.")
				. = FALSE
				break
	if(!length(target_areas))
		LAZYDISTINCTADD(errors, "The ship must have defined areas in the construction zone.")
		return FALSE
	var/list/area_turfs = list()
	for(var/area/A in target_areas)
		for(var/turf/T in A)
			area_turfs |= T
			if(length(area_turfs) > MAX_SHIP_TILES)
				LAZYDISTINCTADD(errors, "The ship is too large.")
				return FALSE // If the ship is too large, skip contiguity checks.

	// Check to make sure all the ships areas are connected.
	. = min(., check_contiguity(area_turfs))
	if(.)
		LAZYDISTINCTADD(errors, "The ship is valid for finalization.")

/obj/machinery/docking_beacon/proc/check_contiguity(var/list/area_turfs)
	if(!area_turfs || !LAZYLEN(area_turfs))
		return FALSE
	var/turf/start_turf = pick(area_turfs) // The last added area is the most likely to be incontiguous.
	var/list/pending_turfs = list(start_turf)
	var/list/checked_turfs = list()

	while(pending_turfs.len)
		var/turf/T = pending_turfs[1]
		pending_turfs -= T
		for(var/dir in GLOB.cardinal)	// Floodfill to find all turfs contiguous with the randomly chosen start_turf.
			var/turf/NT = get_step(T, dir)
			if(!isturf(NT) || !(NT in area_turfs) || (NT in pending_turfs) || (NT in checked_turfs))
				continue
			pending_turfs += NT

		checked_turfs += T

	if(LAZYLEN(area_turfs.Copy()) - LAZYLEN(checked_turfs)) // If there are turfs in area_turfs, not in checked_turfs there are non-contiguous turfs in the selection.
		LAZYDISTINCTADD(errors, "The ship construction is not contiguous.")
		return FALSE
	return TRUE

/obj/overmap/visitable/ship/landable/created/Initialize(mapload, ship_name, ship_color, ship_dir)
	if(ship_name)
		name = ship_name
		shuttle = ship_name

	if(ship_color)
		color = ship_color

	if(ship_dir)
		fore_dir = ship_dir

	. = ..(mapload)

/obj/machinery/docking_beacon/proc/create_ship()
	var/list/shuttle_areas = get_areas()
	// Double check to ensure the ship is valid.
	if(!check_ship_validity(shuttle_areas))
		return FALSE


	var/area/base_area
	var/obj/overmap/visitable/O = map_sectors["[z]"]
	if(O && istype(O))
		base_area = O.base_area
	if(!base_area)
		return

	var/turf/center_turf
	switch(dir)
		if(NORTH)
			center_turf = locate(x, (y+docking_height/2)+1, z)
		if(SOUTH)
			center_turf = locate(x, (y-docking_height/2)-1, z)
		if(EAST)
			center_turf = locate(x+(docking_height/2)+1, y, z)
		if(WEST)
			center_turf = locate(x-(docking_height/2)-1, y, z)
	if(!center_turf)
		return FALSE
	var/obj/shuttle_landmark/temporary/construction/landmark = new(get_turf(src), base_area, get_base_turf(z))
	landmark.base_area = base_area
	var/list/shuttle_args = list(landmark, shuttle_areas.Copy(), ship_name)
	SSshuttle.initialize_shuttle(/datum/shuttle/autodock/overmap/created, null, shuttle_args)

	new /obj/overmap/visitable/ship/landable/created(get_turf(src), ship_name, ship_color, GLOB.reverse_dir[dir])
	permitted_shuttles |= ship_name
	return TRUE

/obj/shuttle_landmark/temporary/construction
	flags = 0

/obj/shuttle_landmark/temporary/construction/Initialize(var/mapload, var/area/b_area, var/turf/b_turf)
	if(!persistent_id)
		base_area = b_area
		base_turf = b_turf
	. = ..(mapload)

#undef MAX_DOCKING_SIZE
#undef MAX_SHIP_TILES
#undef MAX_NAME_LENGTH
