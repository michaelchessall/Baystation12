/datum/gas_mixture/after_load()
	for(var/x in gas)
		var/val = gas[x]
		if(val < 0.01)
			gas -= x
	..()

/**
/obj/vehicle/train/cargo/engine/after_load()
	..()
	update_engine_verbs()
**/
/datum/turbolift_floor/var/list/area_contents = list()
/datum/turbolift_floor/var/list/extra_turfs = list()

/datum/turbolift_floor/after_load()
	var/area/turbolift/A = new
	A.contents.Add(area_contents)
	A.lift_floor_label = label
	A.lift_floor_name = name
	A.name = name
	A.lift_announce_str = announce_str
	A.arrival_sound = arrival_sound
	area_ref = "\ref[A]"

/obj/machinery/telepad_cargo/after_load()
	if(req_access_faction && req_access_faction != "")
		connected_faction = get_faction(req_access_faction)
		if(connected_faction)
			connected_faction.cargo_telepads |= src


/obj/machinery/computer/bridge_computer/after_load()
	..()
	if(shuttle && loc && loc.loc)
		shuttle.shuttle_area |= loc.loc


	icon_state = "pipe-s"



/obj/structure/disposalpipe/segment/after_load()
	..()
	if(icon_state == "pipe-s")
		dpdir = dir | turn(dir, 180)
	else
		dpdir = dir | turn(dir, -90)
	if(loc)
		update()
	return

/obj/structure/disposalpipe/trunk/after_load()
	..()
	dpdir = dir
	spawn(1)
		getlinked()
	update()
	return

/obj/item/weapon/reagent_containers/after_load()
	update_icon()
	..()


/obj/machinery/power/terminal/after_load()
	..()
	if(!loc)
		atom_flags |= ATOM_FLAG_INITIALIZED	// This prevents the subsystem from getting upset
		qdel(src)
		return
	var/turf/T = get_turf(src)
	if(level==1) hide(!T.is_plating())
	return


/obj/machinery/power/smes/buildable/after_load()
	RefreshParts()
	..()

/obj/machinery/power/solar_control/after_load()
	..()
	src.search_for_connected()
	if(connected_tracker && track == 2)
		connected_tracker.set_angle(GLOB.sun.angle)
	src.set_panels(cdir)


/obj/structure/cable/after_load()
	icon_state = "[d1]-[d2]"

	var/turf/T = src.loc			// hide if turf is not intact
	if(T)
		if(level==1) hide(!T.is_plating())
	mergeConnectedNetworks(d1)
	mergeConnectedNetworks(d2)

/obj/item/weapon/stock_parts/power/terminal/map_storage_saved_vars = "density;icon_state;name;pixel_x;pixel_y;contents;dir;terminal"


/obj/machinery/power/apc/after_load()
	connect_to_network()
	var/obj/item/weapon/stock_parts/power/terminal/terminal = get_component_of_type(/obj/item/weapon/stock_parts/power/terminal)
	if(terminal && terminal.terminal)
		terminal.set_terminal(src, terminal.terminal)
	..()
	Initialize(populate_parts = FALSE)
	for(var/obj/item/weapon/stock_parts/power/power in power_components)
		power.set_status(src, PART_STAT_CONNECTED)
		power.set_status(src, PART_STAT_INSTALLED)
		power.set_status(src, PART_STAT_PROCESSING)
		power.start_processing(src)

	update_icon()

/obj/item/weapon/paper/after_load()
	info_links = replacetext(info_links,"***MY_REF***","\ref[src]")
	update_icon()
	..()

/obj/item/organ/internal/stack/after_load()
	..()
	try_connect()
	if(duty_status)
		try_duty()


/obj/item/organ/internal/lungs/after_load()
	..()
	sync_breath_types()

/obj/item/organ/external/after_load()
	..()
	if(isnull(pain_disability_threshold))
		pain_disability_threshold = (max_damage * 0.75)
	if(owner)
		replaced(owner)
		sync_colour_to_human(owner)
	get_icon()


/obj/machinery/airlock_sensor_norad/after_load()
	pixel_x = (src.dir & 3)? 0 : (src.dir == 4 ? -30 : 30)
	pixel_y = (src.dir & 3)? (src.dir ==1 ? -30 : 30) : 0

/obj/machinery/atmospherics/pipe/zpipe/after_load()
	..()
	switch(dir)
		if(SOUTH)
			initialize_directions = SOUTH
		if(NORTH)
			initialize_directions = NORTH
		if(WEST)
			initialize_directions = WEST
		if(EAST)
			initialize_directions = EAST
		if(NORTHEAST)
			initialize_directions = NORTH
		if(NORTHWEST)
			initialize_directions = WEST
		if(SOUTHEAST)
			initialize_directions = EAST
		if(SOUTHWEST)
			initialize_directions = SOUTH

/obj/item/weapon/computer_hardware/network_card/after_load()
	..()
	get_network()
/obj/item/weapon/computer_hardware/network_card/var/datum/ntnet/connected_network
/obj/item/weapon/computer_hardware/network_card/var/connected_to = ""
/obj/item/weapon/computer_hardware/network_card/var/password = ""
/obj/item/weapon/computer_hardware/network_card/var/connected = 0
/obj/item/weapon/computer_hardware/network_card/proc/get_network()
	if(connected_network && connected_network.net_uid == connected_to)
		connected = 1
		return connected_network
	else
		connected_network = null
		for(var/datum/world_faction/fact in GLOB.all_world_factions)
			if(fact.network)
				if(fact.network.net_uid == connected_to)
					if(!fact.network.secured || fact.network.password == password)
						connected_network = fact.network
						connected = 1
						return connected_network
	connected = 0



/mob/living/simple_animal/after_load()
	if(stat == 2)
		death()

/mob/living/silicon/robot/var/obj/item/device/lmi/lmi = null
/mob/living/silicon/robot/after_load()
	if(lmi)
		add_lace_action()

/mob/living/silicon/robot/proc/add_lace_action()
	for(var/datum/action/lace/laceac in actions)
		return 1
	if(lmi)
		if(lmi.brainobj)
			var/datum/action/lace/laceaction = new(lmi.brainobj)
			laceaction.Grant(src)


/mob/living/carbon/lace/after_load()
	if(container)
		container.lacemob = src
	for(var/datum/action/action in actions)
		action.target = container

/mob/living/bot/var/datum/world_faction/connected_faction = null
/mob/living/bot/var/datum/world_faction/req_access_faction = ""

/mob/living/bot/after_load()
	..()
	connected_faction = get_faction(req_access_faction)


/turf/simulated/mineral/after_load()
	update_icon(0)
	..()

/**
/turf/simulated/asteroid/after_load()
	updateMineralOverlays(1)
	..()
**/
/**
/turf/simulated/floor/asteroid/after_load()
	var/resource = resources
	var/xi = x
	var/yi = y
	var/zi = z
	ChangeTurf(/turf/simulated/asteroid)
	spawn()
		var/turf/simulated/asteroid = locate(xi,yi,zi)
		asteroid.resources = resource
	..()
**/
/obj/machinery/computer/mining/var/list/connected_coordinates //Saves/loads the coordinates of the connected machines to be restored on load
/obj/machinery/computer/mining/after_load()
	connected = list()
	for(var/list/coords in connected_coordinates)
		var/turf/location = locate(coords["x"], coords["y"], coords["z"])
		connect_machine(locate(/obj/machinery/mineral) in location)
	..()
/obj/machinery/computer/mining/proc/connect_machine(var/obj/machinery/mineral/mach)
	if(!connected)
		connected = list()
	if(mach && istype(mach))
		mach.console = src
		connected |= mach
		return TRUE
	return FALSE


/obj/machinery/mineral/after_load()
	..()
	set_input(input_turf)
	set_output(output_turf)

/**
/obj/item/stack/material_dust/after_load()
	..()
	set_material_data(material)
	update_icon()
**/
/**

/obj/item/weapon/ore/after_load() //Remove me after first save reload!
	var/obj/item/stack/ore/newore = new()
	//Pass our details to the new ore
	newore.material = src.material
	newore.geologic_data = src.geologic_data
	newore.drop_to_stacks(loc)
	qdel(src)

**//**
/obj/item/stack/ore/after_load()
	..()
	set_material_data(material)
	update_icon()
**/

/obj/machinery/portable_atmospherics/hydroponics/after_load()
	update_icon()


/obj/machinery/portable_atmospherics/hydroponics/after_load()
	update_icon()

/obj/item/seeds/after_load()
	update_seed()


/obj/item/weapon/paper/contract/after_load()
	cancel()
	update_icon()


/datum/world_faction/after_load()
	if(!debts)
		debts = list()
	..()

/datum/assignment/after_load()
	..()

/obj/machinery/docking_beacon/after_load()
	if(req_access_faction && req_access_faction != "" || (faction && faction.uid != req_access_faction))
		faction = get_faction(req_access_faction)
	check_shuttle()
	stat = 0
	update_icon()

/obj/item/weapon/spacecash/after_load()
	..()
	update_icon()


/datum/money_account/after_load()
	var/datum/money_account/M = get_account_loadless(account_number)
	if(M && M.money >= money)
		message_admins("duplicate account loaded owner: [owner_name] account_number: [M.account_number]")
		return M
	else if(M && M.money < money)
		all_money_accounts.Remove(M)
		all_money_accounts.Add(src)
		return src
	else
		all_money_accounts.Add(src)
	..()
	return src

/**
/obj/item/girderpart/after_load()
	name = "[material.display_name] " + initial(name)
	color = material.icon_colour
**/
/**
/obj/structure/girder/after_load()
	update_material()

**/
/obj/item/clothing/accessory/bowtie/after_load()
	if(has_suit)
		has_suit.verbs += /obj/item/clothing/accessory/bowtie/verb/toggle
//	icon_tied = icon_tied || icon_state
	..()

/**
/obj/item/clothing/accessory/holster/after_load()
	..()
	if(has_suit)
		has_suit.verbs += /obj/item/clothing/accessory/holster/verb/holster_verb
**/
/obj/item/clothing/accessory/toggleable/after_load()
	if(!icon_closed)
		icon_closed = icon_state
	if(has_suit)
		has_suit.verbs += /obj/item/clothing/accessory/toggleable/verb/toggle
	..()


/stat_rig_module/activate/after_load()
	..()
	if(module)
		name = module.activate_string
		if(module.active_power_cost)
			name += " ([module.active_power_cost*10]A)"

/stat_rig_module/deactivate/after_load()
	..()
	if(module)
		name = module.deactivate_string
		// Show cost despite being 0, if it means changing from an active cost.
		if(module.active_power_cost || module.passive_power_cost)
			name += " ([module.passive_power_cost*10]P)"

		module_mode = "deactivate"



/stat_rig_module/engage/after_load()
	..()
	if(module)
		name = module.engage_string
		if(module.use_power_cost)
			name += " ([module.use_power_cost*10]E)"
		module_mode = "engage"


/obj/item/clothing/head/welding/after_load()
	base_state = "welding"

/obj/machinery/atmospherics/pipe/after_load()
	..()
	build_network()

/obj/machinery/atmospherics/pipe/manifold/after_load()
	switch(dir)
		if(NORTH)
			initialize_directions = EAST|SOUTH|WEST
		if(SOUTH)
			initialize_directions = WEST|NORTH|EAST
		if(EAST)
			initialize_directions = SOUTH|WEST|NORTH
		if(WEST)
			initialize_directions = NORTH|EAST|SOUTH

/obj/machinery/atmospherics/pipe/cap/after_load()
	..()
	initialize_directions = dir

/obj/machinery/atmospherics/pipe/tank/after_load()
	initialize_directions = dir
	..()
/**
/obj/machinery/atmospherics/unary/vent_scrubber/after_load()
	..()
	if(loc)
		initial_loc = get_area(loc)
		area_uid = initial_loc.uid
**/
/**
/obj/machinery/atmospherics/unary/vent_pump/after_load()
	..()
	air_contents.volume = ATMOS_DEFAULT_VOLUME_PUMP

	icon = null
	if(loc)
		initial_loc = get_area(loc)
		area_uid = initial_loc.uid
**/
/obj/machinery/atmospherics/unary/after_load()

	initialize_directions = dir
/**
/obj/machinery/atmospherics/unary/vent_pump/after_load()
	..()
	air_contents.volume = ATMOS_DEFAULT_VOLUME_PUMP

	icon = null
	if(loc)
		initial_loc = get_area(loc)
		area_uid = initial_loc.uid

**/
/obj/machinery/atmospherics/trinary/after_load()
	..()
	switch(dir)
		if(NORTH)
			initialize_directions = EAST|NORTH|SOUTH
		if(SOUTH)
			initialize_directions = SOUTH|WEST|NORTH
		if(EAST)
			initialize_directions = EAST|WEST|SOUTH
		if(WEST)
			initialize_directions = WEST|NORTH|EAST

/obj/machinery/atmospherics/trinary/filter/m_filter/after_load()
	..()
	switch(dir)
		if(NORTH)
			initialize_directions = WEST|NORTH|SOUTH
		if(SOUTH)
			initialize_directions = SOUTH|EAST|NORTH
		if(EAST)
			initialize_directions = EAST|WEST|NORTH
		if(WEST)
			initialize_directions = WEST|SOUTH|EAST

/obj/machinery/atmospherics/trinary/mixer/m_mixer/after_load()
	..()
	switch(dir)
		if(NORTH)
			initialize_directions = WEST|NORTH|SOUTH
		if(SOUTH)
			initialize_directions = SOUTH|EAST|NORTH
		if(EAST)
			initialize_directions = EAST|WEST|NORTH
		if(WEST)
			initialize_directions = WEST|SOUTH|EAST


/obj/machinery/atmospherics/omni/after_load()
	..()
	ports = new()
	for(var/d in GLOB.cardinal)
		var/datum/omni_port/new_port = new(src, d)
		switch(d)
			if(NORTH)
				new_port.mode = tag_north
			if(SOUTH)
				new_port.mode = tag_south
			if(EAST)
				new_port.mode = tag_east
			if(WEST)
				new_port.mode = tag_west
		if(new_port.mode > 0)
			initialize_directions |= d
		ports += new_port

	build_icons()

/obj/machinery/atmospherics/binary/after_load()
	..()
	switch(dir)
		if(NORTH)
			initialize_directions = NORTH|SOUTH
		if(SOUTH)
			initialize_directions = NORTH|SOUTH
		if(EAST)
			initialize_directions = EAST|WEST
		if(WEST)
			initialize_directions = EAST|WEST

/obj/item/device/assembly_holder/timer_igniter/after_load()
	if(loc)
		loc.verbs |= /obj/item/device/assembly_holder/timer_igniter/verb/configure

/**
/turf/simulated/wall/r_wall/after_load()
	..()
	var/mat = material
	var/r_mat = r_material
	var/p_mat = p_material
	ChangeTurf(/turf/simulated/wall)
	material = mat
	r_material = r_mat
	p_material = p_mat


/turf/simulated/wall/after_load()
	..()
	if(reinf_material)
		p_material = reinf_material
		r_material = reinf_material
	reinf_material = null
	update_full(1, 1)
**/

/obj/structure/window/var/ini_dir = ""
/obj/structure/window/var/saved_dir = ""
/obj/structure/window/after_load()
	dir = saved_dir
	ini_dir = dir
	update_nearby_tiles(need_rebuild=1)
	..()
	update_icon()

/obj/structure/noticeboard/after_load()
	icon_state = "nboard0[notices]"
	notices = contents.len
	..()

/obj/structure/janitorialcart/after_load()
	update_icon()

/obj/structure/after_load()
	update_connections(1)
	..()


/obj/item/weapon/storage/after_load()
	. = ..()
	prepare_ui()


/obj/item/weapon/storage/internal/after_load()
	storage_ui = new storage_ui(src)
	prepare_ui()
	if(master_item)
		loc = master_item
		name = master_item.name
		verbs -= /obj/item/verb/verb_pickup	//make sure this is never picked up.
		..()


/obj/item/weapon/storage/internal/pockets/after_load()
	if(master_item)
		loc = master_item
		name = master_item.name
		if(istype(loc, /obj/item/clothing/suit/storage))
			var/obj/item/clothing/suit/storage/coat = loc
			if(coat)
				coat.pockets = src
		if(istype(loc, /obj/item/clothing/accessory/storage))
			var/obj/item/clothing/accessory/storage/web = loc
			if(web)
				web.hold = src
		..()


/obj/item/weapon/flamethrower/after_load()
	..()
	update_icon()

/obj/item/device/radio/borg/after_load()
	..()
	if(!myborg && istype(loc, /mob/living))
		myborg = loc

/obj/item/device/radio/headset/after_load()
	recalculateChannels(1)
/**
/obj/item/radio/integrated/after_load()
	..()
	if(loc)
		if (istype(loc.loc, /obj/item/device/pda))
			hostpda = loc.loc
**/
/obj/effect/persistent_spawn/after_load()
	GLOB.latejoin_cryo |= loc
	qdel(src)
/**
/obj/effect/decal/cleanable/puddle_chem/after_load()
	atom_flags &= ~ATOM_FLAG_INITIALIZED
	on_reagent_change()
	loop()
**/
/**
/obj/mecha/after_load()
	if(occupant)
		icon_state = reset_icon()
	update_connect_verbs()
**/
/**
/obj/item/mecha_parts/mecha_equipment/tool/passenger/after_load()
	..()
	if (chassis)
		chassis.verbs |= /obj/mecha/proc/move_inside_passenger
**/
/obj/machinery/telecomms/var/list/links_coords = list()

/datum/coord_holder
	var/x
	var/y
	var/z
	map_storage_saved_vars = "x;y;z"

/obj/machinery/telecomms/before_save()
	links_coords = list()
	for(var/obj/ob in links)
		var/datum/coord_holder/holder = new()
		holder.x = ob.x
		holder.y = ob.y
		holder.z = ob.z
		links_coords += holder

/obj/machinery/telecomms/after_load()
	if(links_coords && links_coords.len)
		for(var/datum/coord_holder/holder in links_coords)
			var/turf/T = locate(holder.x,holder.y,holder.z)
			if(T)
				for(var/obj/machinery/telecomms/tele in T.contents)
					links |= tele


/obj/machinery/recharge_station/after_load()
	for(var/mob/M in contents)
		M.loc = get_turf(src)

/obj/machinery/porta_turret/var/datum/world_faction/connected_faction
/obj/machinery/porta_turret/after_load()
	..()
	connected_faction = get_faction(req_access_faction)
	setup()


/**
/obj/item/weapon/newspaper/after_load()
	var/datum/small_business/business = get_business(feed_id)
	if(business)
		for(var/datum/NewsIssue/issue in business.feed.all_issues)
			if(issue.uid == issue_id)
				linked_issue = issue
				break
	..()
**/
/obj/machinery/magnetic_module/after_load()
	..()
	if(loc)
		var/turf/T = loc
		hide(!T.is_plating())
		center = T

		spawn(10)	// must wait for map loading to finish
			if(radio_controller)
				radio_controller.add_object(src, freq, RADIO_MAGNETS)

		spawn()
			magnetic_process()



/obj/machinery/after_load()
	RefreshParts()

/obj/machinery/hologram/holopad/after_load()
	if(loc)
		desc = "It's a floor-mounted device for projecting holographic images. Its ID is '[loc.loc]'"
/**
/obj/structure/frame/after_load()
	..()
	if(circuit)
		check_components()
**/
/obj/machinery/portable_atmospherics/canister/after_load()
	..()
	update_icon()

/obj/machinery/alarm/after_load()
	. = ..()
	alarm_area = get_area(src)
	if(!alarm_area)
		return
	area_uid = alarm_area.uid
	if (name == "alarm")
		name = "[alarm_area.name] Air Alarm"

	if(!wires)
		wires = new(src)

	set_frequency(frequency)
	/**
	if (!master_is_operating())
		elect_master()
	**/
	update_icon()

/obj/item/weapon/stock_parts/computer/network_card/after_load()
	..()
	get_network()

/obj/machinery/bluespace_beacon/after_load()
	..()
	var/turf/T = loc
	if(T)
		Beacon = new /obj/item/device/radio/beacon
		Beacon.invisibility = INVISIBILITY_MAXIMUM
		Beacon.loc = T

		hide(!T.is_plating())