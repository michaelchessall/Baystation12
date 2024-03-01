// This is special hardware configuration program.
// It is to be used only with modular computers.
// It allows you to toggle components of your device.

/datum/computer_file/program/network
	filename = "network"
	filedesc = "Network Tool"
	extended_desc = "This program allows connecting to different networks."
	program_icon_state = "generic"
	program_key_state = "generic_key"
	program_menu_icon = "gear"
	unsendable = 1
	undeletable = 1
	size = 4
	processing_size = 0.5
	available_on_ntnet = FALSE
	requires_ntnet = FALSE
	nanomodule_path = /datum/nano_module/program/network
	usage_flags = PROGRAM_ALL
	category = PROG_UTIL

/datum/nano_module/program/network
	name = "Network Tool"

/datum/nano_module/program/network/ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = 1, datum/topic_state/state = GLOB.default_state)
	var/list/data = list()

	data = program.get_header_data()
	var/obj/item/stock_parts/computer/network_card/network_card = program.computer.get_component(PART_NETWORK)
	data["card_exists"] = !!network_card
	var/list/all_networks[0]
	if(network_card)
		var/datum/WorldFaction/faction = network_card.GetWorldFaction()
		if(faction)
			data["faction_name"] = faction.display_name
		else
			data["faction_name"] = "*DISCONNECTED*"
		for(var/datum/WorldFaction/sel_faction in all_world_factions)
			if(sel_faction.network_visible)
				var/sel_name = sel_faction.display_name
				if(sel_faction.network_password) sel_name += " (Password Protected)"
				all_networks.Add(list(list(
				"name" = sel_name,
				"ref" = "\ref[sel_faction]"
				)))
		data["all_networks"] = all_networks
		data["password"] = network_card.password ? network_card.password : "*UNSET*"

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "network.tmpl", "Network Utility", 575, 700, state = state)
		ui.auto_update_layout = 1
		ui.set_initial_data(data)
		ui.open()

/datum/nano_module/program/network/Topic(href, href_list)
	. = ..()
	if (.)
		return
	var/obj/item/stock_parts/computer/network_card/network_card = program.computer.get_component(PART_NETWORK)
	if(!network_card)
		return

	switch(href_list["action"])
		if("password")
			var/temp_name =input("Enter password.", "Network Password", "")
			if(program.computer && program.can_run(usr, 1))
				if(temp_name)
					network_card.password = temp_name
		if("connect")
			var/temp_name = input("Enter Network ID.", "Network ID", "")
			if(program.computer && program.can_run(usr, 1))
				if(temp_name)
					network_card.faction_uid = temp_name
		if("connect_ref")
			var/ref = href_list["assign_target"]
			var/datum/WorldFaction/faction = locate(ref)
			if(faction)
				network_card.faction_uid = faction.uid

	return TOPIC_REFRESH
