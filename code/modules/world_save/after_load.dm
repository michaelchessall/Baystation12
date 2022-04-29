/obj/effect/overmap/visitable/after_load()
	register_z_levels()
/obj/effect/overmap/visitable/Read(savefile/f)
	..()
	zlevels_to_load.Add(map_z)
/obj/effect/overmap/visitable/before_save()
	zlevels_to_save.Add(map_z)



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

/mob/proc/get_id_name(var/if_no_id = "Unknown")
	return if_no_id



/obj/machinery/telepad_cargo/var/datum/world_faction/connected_faction
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

/obj/item/network_cards/after_load()
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

///obj/machinery/power/solar_control/after_load()
//	..()
//	src.search_for_connected()

//	if(connected_tracker && track == 2)
//		connected_tracker.set_angle(GLOB.sun.angle)
//	src.set_panels(cdir)


/obj/structure/cable/after_load()
	icon_state = "[d1]-[d2]"

	var/turf/T = src.loc			// hide if turf is not intact
	if(T)
		if(level==1) hide(!T.is_plating())
	mergeConnectedNetworks(d1)
	mergeConnectedNetworks(d2)


/obj/item/stock_parts/power/terminal/map_storage_saved_vars = "density;icon_state;name;pixel_x;pixel_y;contents;dir;terminal"


/obj/machinery/power/apc/after_load()
	connect_to_network()
	var/obj/item/stock_parts/power/terminal/terminal = get_component_of_type(/obj/item/stock_parts/power/terminal)
	if(terminal && terminal.terminal)
		terminal.set_terminal(src, terminal.terminal)
	..()
	Initialize(populate_parts = FALSE)
	for(var/obj/item/stock_parts/power/power in power_components)
		power.set_status(src, PART_STAT_CONNECTED)
		power.set_status(src, PART_STAT_INSTALLED)
		power.set_status(src, PART_STAT_PROCESSING)
		power.start_processing(src)

	update_icon()

/obj/item/paper/after_load()
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


/obj/item/paper/contract/after_load()
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
//	/obj/item/clothing/accessory/bowtie/after_load()
//		if(has_suit)
//			has_suit.verbs += /obj/item/clothing/accessory/bowtie/verb/toggle
//	icon_tied = icon_tied || icon_state
//		..()
///obj/item/clothing/accessory/bowtie/after_load()
//	if(has_suit)
//		has_suit.verbs += /obj/item/clothing/accessory/bowtie/verb/toggle
//	icon_tied = icon_tied || icon_state
	..()

/**
/obj/item/clothing/accessory/holster/after_load()
	..()
	if(has_suit)
		has_suit.verbs += /obj/item/clothing/accessory/holster/verb/holster_verb
**/
/**
/obj/item/clothing/accessory/toggleable/after_load()
	if(!icon_closed)
		icon_closed = icon_state
	if(has_suit)
		has_suit.verbs += /obj/item/clothing/accessory/toggleable/verb/toggle
	..()

**/
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


/obj/item/storage/after_load()
	. = ..()
	prepare_ui()

/**
/obj/item/weapon/storage/internal/after_load()
	storage_ui = new storage_ui(src)
	prepare_ui()
	if(master_item)
		loc = master_item
		name = master_item.name
		verbs -= /obj/item/verb/verb_pickup	//make sure this is never picked up.
	..()
**/
/obj/machinery/door/after_load()
	update_connections()
	update_icon()
/**
/obj/item/weapon/storage/internal/pockets/after_load()
	if(master_item)
		loc = master_item
		name = master_item.name
		if(istype(loc, /obj/item/clothing/suit/storage))
			var/obj/item/clothing/suit/storage/coat = loc
			if(coat)
				coat.pockets = src
	//	if(istype(loc, /obj/item/clothing/accessory/storage))
	//		var/obj/item/clothing/accessory/storage/web = loc
	//		if(web)
	//			web.hold = src
	..()

**/
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
/**
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


**/
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

/obj/item/stock_parts/computer/network_card/after_load()
	..()
	get_network()
/**
/obj/machinery/bluespace_beacon/after_load()
	..()
	var/turf/T = loc
	if(T)
		Beacon = new /obj/item/device/radio/beacon
		Beacon.invisibility = INVISIBILITY_MAXIMUM
		Beacon.loc = T

		hide(!T.is_plating())


// INIT OVERRIDES!!
**/
/obj/structure/anomaly_container/Initialize()
	. = ..()
	spawn(20)
	if(!map_storage_loaded)
		var/obj/machinery/artifact/A = locate() in loc
		if(A)
			contain(A)
/**
/obj/vehicle/train/cargo/engine/Initialize()
	. = ..()
	if(!map_storage_loaded)
		cell = new /obj/item/cell/high(src)
		key = new(src)
**/

/**
/obj/item/network_cards/food/snacks/slice/Initialize()
	. = ..()
	if(!map_storage_loaded)
		if(filled)
			var/obj/item/network_cards/food/snacks/whole = new whole_path()
			if(whole && whole.slices_num)
				var/reagent_amount = whole.reagents.total_volume/whole.slices_num
				whole.reagents.trans_to_obj(src, reagent_amount)

			qdel(whole)

**/
/**
/obj/item/pizzabox/margherita/Initialize()
	. = ..()
	if(!map_storage_loaded)
		pizza = new /obj/item/network_cards/food/snacks/sliceable/pizza/margherita(src)
		boxtag = "Margherita Deluxe"

/obj/item/pizzabox/vegetable/Initialize()
	. = ..()
	if(!map_storage_loaded)
		pizza = new /obj/item/network_cards/food/snacks/sliceable/pizza/vegetablepizza(src)
		boxtag = "Gourmet Vegatable"

/obj/item/pizzabox/mushroom/Initialize()
	. = ..()
	if(!map_storage_loaded)
		pizza = new /obj/item/network_cards/food/snacks/sliceable/pizza/mushroompizza(src)
		boxtag = "Mushroom Special"

/obj/item/pizzabox/meat/Initialize()
	. = ..()
	if(!map_storage_loaded)
		pizza = new /obj/item/network_cards/food/snacks/sliceable/pizza/meatpizza(src)
		boxtag = "Meatlover's Supreme"
**/
/**
/obj/item/weapon/storage/box/mixedglasses/Initialize()
	. = ..()
	if(!map_storage_loaded)
		make_exact_fit()

/obj/item/weapon/storage/box/glasses/Initialize()
	. = ..()
	if(!map_storage_loaded)
		for(var/i = 1 to 7)
			new glass_type(src)
		make_exact_fit()

/obj/item/weapon/storage/box/glass_extras/Initialize()
	if(!map_storage_loaded)
		for(var/i = 1 to 14)
			new extra_type(src)
	. = ..()
**/
/**
/obj/item/weapon/gun/projectile/dartgun/Initialize()
	if(!map_storage_loaded)
		if(starting_chems)
			for(var/chem in starting_chems)
				var/obj/B = new container_type(src)
				B.reagents.add_reagent(chem, 60)
				beakers += B
	. = ..()
	update_icon()
**/
/**
/obj/item/weapon/gun/projectile/Initialize()
	. = ..()
	if(!map_storage_loaded)
		if(starts_loaded)
			if(ispath(ammo_type) && (load_method & (SINGLE_CASING|SPEEDLOADER)))
				for(var/i in 1 to max_shells)
					loaded += new ammo_type(src)
			if(ispath(magazine_type) && (load_method & MAGAZINE))
				ammo_magazine = new magazine_type(src)
	update_icon()
**/
/**
/obj/item/weapon/gun/magnetic/railgun/Initialize()
	if(!map_storage_loaded)
		capacitor = new initial_capacitor_type(src)
		capacitor.charge = capacitor.max_charge

		cell = new initial_cell_type(src)
		if (ispath(loaded))
			loaded = new loaded
	slowdown_per_slot[slot_l_hand] =  slowdown_held
	slowdown_per_slot[slot_r_hand] =  slowdown_held
	slowdown_per_slot[slot_back] =    slowdown_worn
	slowdown_per_slot[slot_belt] =    slowdown_worn
	slowdown_per_slot[slot_s_store] = slowdown_worn

	. = ..()
**/
/**
/obj/item/weapon/gun/energy/Initialize()
	. = ..()
	if(!map_storage_loaded)
		if(cell_type)
			power_supply = new cell_type(src)
		else
			power_supply = new /obj/item/weapon/cell/device/variable(src, max_shots*charge_cost)
	if(self_recharge)
		START_PROCESSING(SSobj, src)
	update_icon()
**/
/obj/item/ammo_casing/Initialize()
	. = ..()
	if(!map_storage_loaded)
		if(ispath(projectile_type))
			BB = new projectile_type(src)

/obj/item/ammo_magazine/Initialize()
	. = ..()
	if(!map_storage_loaded)
		if(isnull(initial_ammo))
			initial_ammo = max_ammo

		if(initial_ammo)
			for(var/i in 1 to initial_ammo)
				stored_ammo += new ammo_type(src)

		update_icon()
/**
/obj/item/weapon/fuel_assembly/Initialize()
	. = ..()
	if(!map_storage_loaded)
		var/material/material = SSmaterials.get_material_by_name(fuel_type)
		if(istype(material))
			name = "[material.use_name] fuel rod assembly"
			desc = "A fuel rod for a fusion reactor. This one is made from [material.use_name]."
			fuel_colour = material.icon_colour
			fuel_type = material.use_name
			if(material.radioactivity)
				radioactivity = material.radioactivity
				desc += " It is warm to the touch."
				START_PROCESSING(SSobj, src)
			if(material.luminescence)
				set_light(material.luminescence, material.luminescence, material.icon_colour)
		else
			name = "[fuel_type] fuel rod assembly"
			desc = "A fuel rod for a fusion reactor. This one is made from [fuel_type]."

		icon_state = "blank"
		var/image/I = image(icon, "fuel_assembly")
		I.color = fuel_colour
		overlays += list(I, image(icon, "fuel_assembly_bracket"))
		rod_quantities[fuel_type] = initial_amount
**/
/obj/machinery/power/apc/init_round_start()
	// is starting with a power cell installed, create it and set its charge level
	if(!map_storage_loaded)
		has_electronics = 2 //installed and secured
		var/obj/item/stock_parts/power/battery/bat = get_component_of_type(/obj/item/stock_parts/power/battery)
		bat.add_cell(src, new cell_type(bat))
		var/obj/item/stock_parts/power/terminal/term = get_component_of_type(/obj/item/stock_parts/power/terminal)
		term.make_terminal(src)

	queue_icon_update()

	if(loc)
		var/area/A = src.loc.loc

		//if area isn't specified use current
		if(isarea(A) && src.areastring == null)
			src.area = A
			name = "\improper [area.name] APC"
		else
			src.area = get_area_name(areastring)
			name = "\improper [area.name] APC"
		area.apc = src
		update_icon()

/obj/item/sticky_pad/random/Initialize()
	. = ..()
	if(!map_storage_loaded)
		color = pick(COLOR_YELLOW, COLOR_LIME, COLOR_CYAN, COLOR_ORANGE, COLOR_PINK)


#define VOIDSUIT_INIT_EQUIPMENT(equipment_var, expected_path) \
if(ispath(##equipment_var, ##expected_path )){\
	##equipment_var = new equipment_var (src);\
}\
else if(##equipment_var) {\
	CRASH("[log_info_line(src)] has an invalid [#equipment_var] type: [log_info_line(##equipment_var)]");\
}

/obj/item/clothing/suit/space/void/Initialize()
	. = ..()
	if(!map_storage_loaded)
		VOIDSUIT_INIT_EQUIPMENT(boots,  /obj/item/clothing/shoes/magboots)
		VOIDSUIT_INIT_EQUIPMENT(helmet, /obj/item/clothing/head/helmet)
		VOIDSUIT_INIT_EQUIPMENT(tank,   /obj/item/tank)

#undef VOIDSUIT_INIT_EQUIPMENT



/turf/make_air()
	if(map_storage_loaded)
		initial_gas = list()
	air = new/datum/gas_mixture
	air.temperature = temperature
	if(initial_gas)
		air.gas = initial_gas.Copy()
	air.update_values()


/obj/structure/noticeboard/Initialize()
	if(!map_storage_loaded)
		for(var/obj/item/I in loc)
			if(notices > 4) break
			if(istype(I, /obj/item/paper))
				I.forceMove(src)
				notices++

	. = ..()


/obj/structure/closet/secure_closet/freezer/money/Initialize()
	. = ..()
	//let's make hold a substantial amount.
	if(!map_storage_loaded)
		var/created_size = 0
		for(var/i = 1 to 200) //sanity loop limit
			var/obj/item/cash_type = pick(3; /obj/item/spacecash/bundle/c1000, 4; /obj/item/spacecash/bundle/c500, 5; /obj/item/spacecash/bundle/c200)
			var/bundle_size = initial(cash_type.w_class) / 2
			if(created_size + bundle_size <= storage_capacity)
				created_size += bundle_size
				new cash_type(src)
			else
				break

/obj/structure/closet/LateInitialize(mapload, ...)
	if(!map_storage_loaded)
		var/list/will_contain = WillContain()
		if(will_contain)
			create_objects_in_loc(get_turf(src), will_contain)

		if(!opened && mapload) // if closed and it's the map loading phase, relevant items at the crate's loc are put in the contents
			store_contents()

/obj/item/storage/backpack/weldpack/Initialize()
	if(!map_storage_loaded)
		create_reagents(max_fuel)
		reagents.add_reagent(max_fuel)
	. = ..()

/obj/item/weldingtool/Initialize()
	if(!map_storage_loaded)
		if(ispath(tank))
			tank = new tank

	set_extension(src, /datum/extension/base_icon_state, /datum/extension/base_icon_state, icon_state)
	update_icon()

	. = ..()

/obj/item/welder_tank/Initialize()
	if(!map_storage_loaded)
		create_reagents(max_fuel)
		reagents.add_reagent(/datum/reagent/fuel, max_fuel)
		. = ..()

/obj/item/tank/Initialize()
	. = ..()

	if(!map_storage_loaded)
		. = ..()
		proxyassembly = new /obj/item/device/tankassemblyproxy(src)
		proxyassembly.tank = src

		air_contents = new /datum/gas_mixture(volume, T20C)
		for(var/gas in starting_pressure)
			air_contents.adjust_gas(gas, starting_pressure[gas]*volume/(R_IDEAL_GAS_EQUATION*T20C), 0)
		air_contents.update_values()


	START_PROCESSING(SSobj, src)
	update_icon(override = TRUE)
/**
/obj/item/storage/Initialize()
	. = ..()
	if(allow_quick_empty)
		verbs += /obj/item/weapon/storage/verb/quick_empty
	else
		verbs -= /obj/item/weapon/storage/verb/quick_empty

	if(allow_quick_gather)
		verbs += /obj/item/weapon/storage/verb/toggle_gathering_mode
	else
		verbs -= /obj/item/weapon/storage/verb/toggle_gathering_mode

	if(isnull(max_storage_space) && !isnull(storage_slots))
		max_storage_space = storage_slots*BASE_STORAGE_COST(max_w_class)

	prepare_ui()
	if(!map_storage_loaded)
		if(startswith)
			for(var/item_path in startswith)
				var/list/data = startswith[item_path]
				if(islist(data))
					var/qty = data[1]
					var/list/argsl = data.Copy()
					argsl[1] = src
					for(var/i in 1 to qty)
						new item_path(arglist(argsl))
				else
					for(var/i in 1 to (isnull(data)? 1 : data))
						new item_path(src)
			update_icon()
**/
/obj/item/storage/box/lights/Initialize()
	. = ..()
	if(!map_storage_loaded)
		make_exact_fit()

/obj/item/device/suit_cooling_unit/Initialize()
	. = ..()
	START_PROCESSING(SSobj, src)
	if(!map_storage_loaded)
		cell = new/obj/item/cell/high()		// 10K rated cell.
		cell.forceMove(src)

/obj/item/device/radio/headset/Initialize()
	. = ..()
	internal_channels.Cut()
//	if(!map_storage_loaded)
//		if(ks1type)
//			keyslot1 = new ks1type(src)
//		if(ks2type)
//			keyslot2 = new ks2type(src)
	recalculateChannels(1)


/obj/machinery/door/blast/Initialize()
	. = ..()


	if(!map_storage_loaded)
		if(!begins_closed)
			icon_state = icon_state_open
			set_density(0)
			set_opacity(0)
			layer = open_layer

		implicit_material = SSmaterials.get_material_by_name(MATERIAL_PLASTEEL)

/obj/machinery/computer/arcade/Initialize()
	. = ..()
	// If it's a generic arcade machine, pick a random arcade
	// circuit board for it and make the new machine
	if(!map_storage_loaded)
		if(random)
			var/obj/item/stock_parts/circuitboard/arcade/A = pick(subtypesof(/obj/item/stock_parts/circuitboard/arcade))
			var/path = initial(A.build_path)
			new path(loc)
			return INITIALIZE_HINT_QDEL



/obj/machinery/portable_atmospherics/canister/empty/Initialize()
	. = ..()
	if(!map_storage_loaded)
		name = 	initial(canister_type.name)
		icon_state = initial(canister_type.icon_state)
		canister_color = initial(canister_type.canister_color)

/obj/machinery/alarm/Initialize()
	. = ..()
	alarm_area = get_area(src)
	if(alarm_area)
		area_uid = alarm_area.uid
	if (name == "alarm")
		SetName("[alarm_area.name] Air Alarm")

	// breathable air according to human/Life()
	if(!map_storage_loaded)
		TLV["oxygen"] =			list(16, 19, 135, 140) // Partial pressure, kpa
		TLV["carbon dioxide"] = list(-1.0, -1.0, 5, 10) // Partial pressure, kpa
		TLV["phoron"] =			list(-1.0, -1.0, 0.2, 0.5) // Partial pressure, kpa
		TLV["other"] =			list(-1.0, -1.0, 0.5, 1.0) // Partial pressure, kpa
		TLV["pressure"] =		list(ONE_ATMOSPHERE*0.80,ONE_ATMOSPHERE*0.90,ONE_ATMOSPHERE*1.10,ONE_ATMOSPHERE*1.20) /* kpa */
		TLV["temperature"] =	list(T0C-26, T0C, T0C+40, T0C+66) // K

	var/decl/environment_data/env_info = decls_repository.get_decl(environment_type)
	for(var/g in gas_data.gases)
		if(!env_info.important_gasses[g])
			trace_gas += g

	set_frequency(frequency)
	update_icon()
/**
/obj/machinery/sleeper/Initialize()
	. = ..()
	if(!map_storage_loaded)
		beaker = new /obj/item/network_cards/glass/beaker/large(src)

	update_icon()

**/
