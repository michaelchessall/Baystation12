/datum/computer_file/program/assignment
	filename = "assignment"
	filedesc = "Assignment Program"
	nanomodule_path = /datum/nano_module/program/assignment
	program_icon_state = "id"
	program_key_state = "id_key"
	program_menu_icon = "key"
	extended_desc = "Program for assigning crew members to positions within a faction."
	requires_ntnet = TRUE
	size = 8
	category = PROG_COMMAND
	var/datum/FactionRecord/selected_record
/datum/nano_module/program/assignment
	name = "Assignment program"
	var/mod_mode = 1
	var/is_centcom = 0
	var/show_assignments = 0
	var/datum/WorldFaction/selected_faction


/datum/nano_module/program/assignment/ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = 1, datum/topic_state/state = GLOB.default_state)
	var/list/data = host.initial_data()
	var/obj/item/stock_parts/computer/card_slot/card_slot = program.computer.get_component(PART_CARD)
	var/obj/item/stock_parts/computer/network_card/network_card = program.computer.get_component(PART_NETWORK)
	var/datum/WorldFaction/faction
	var/obj/item/card/id/userid = user.GetIdCard()
	if(network_card)
		faction = network_card.GetWorldFaction()
		selected_faction = faction
	var/datum/computer_file/program/assignment/prog_a = program
	var/datum/FactionRecord/selected_record = prog_a.selected_record
	data["src"] = "\ref[src]"
	data["manifest"] = html_crew_manifest()
	data["have_id_slot"] = !!card_slot
	data["have_printer"] = program.computer.has_component(PART_PRINTER)
	data["authenticated"] = program.can_run(user)
	if(card_slot)
		var/obj/item/card/id/id_card = card_slot.stored_card
		data["has_id"] = !!id_card
		data["id_owner"] = id_card && id_card.registered_name ? id_card.registered_name : "-----"
		data["id_name"] = id_card ? id_card.name : "-----"
	data["mmode"] = mod_mode
	if(selected_record)
		data["record_ref"] = "\ref[selected_record]"
		data["account_name"] = selected_record.get_name()
		var/outranked = 1
		var/datum/assignment/user_assignment
		var/datum/assignment_category/user_category
		var/commander = 0
		var/same = 0
		var/leader_name = faction.leader_name
		var/leader = 0
		var/user_rank = 0
		if(userid)
			user_category = faction.GetAssignmentCategory(userid.registered_name)
			user_assignment = faction.GetAssignment(userid.registered_name)
			if(user_category) commander = user_category.command
			same = (selected_record.get_name() == userid.registered_name)
			leader = (leader_name == userid.registered_name)
			if(user_assignment) user_rank = user_assignment.rank
		if(selected_record.curr_assignment)
			var/rank = 0
			data["assignment_name"] = selected_record.curr_assignment.name
			rank = selected_record.curr_assignment.rank
			if(rank >= user_rank && !same) outranked = 1
			else outranked = 0
			if(!leader && !commander && user_category != faction.GetAssignmentCategory(selected_record.get_name())) outranked = 1
		else
			outranked = 0
			data["assignment_name"] = "*UNASSIGNED*"
		if(leader)
			outranked = 0
		if(!outranked)
			data["outrank"] = 1
			var/list/assignment_categories[0]
			for(var/datum/assignment_category/category in faction.assignment_categories)
				var/samec = (user_assignment in category.assignments)
				var/list/ranks = list()
				for(var/datum/assignment/assign in category.assignments)
					ranks |= assign.rank
				var/list/assign_ranks[0]
				ranks = reverselist(ranks)
				for(var/rank in ranks)
					var/list/include_assign = list()
					for(var/datum/assignment/assign in category.assignments)
						if(assign.rank == rank) include_assign |= assign
					var/list/assignments[0]
					for(var/datum/assignment/assign in include_assign)
						var/outrankedc = 1
						var/selected = 0
						if(selected_record.curr_assignment == assign) selected = 1
						else if((commander || samec) && assign.rank < user_rank) outrankedc = 0
						if(leader || selected) outrankedc = 0
						assignments.Add(list(list(
						"assign_name" = assign.name,
						"assign_ref" = "\ref[assign]",
						"outranked" = outrankedc,
						"current" = selected
						)))
					assign_ranks.Add(list(list(
						"rank" = rank,
						"assignments" = assignments
						)))
				assignment_categories.Add(list(list(
					"assignment_category_name" = category.name,
					"ranks" = assign_ranks
				)))
			data["assignment_categories"] = assignment_categories



	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "assignment.tmpl", name, 600, 700, state = state)
		ui.auto_update_layout = 1
		ui.set_initial_data(data)
		ui.open()

/datum/computer_file/program/assignment/Topic(href, href_list)
	if(..())
		return 1
	var/mob/user = usr
	var/obj/item/card/id/user_id_card = user?.GetIdCard()
	var/obj/item/card/id/id_card = computer?.get_inserted_id()
	var/datum/nano_module/program/assignment/module = NM
	var/obj/item/stock_parts/computer/network_card/network_card = computer.get_component(PART_NETWORK)
	var/datum/WorldFaction/faction
	if(network_card)
		faction = network_card.GetWorldFaction()

	if (!module)
		return
	switch(href_list["action"])
		if("switchm")
			if(href_list["target"] == "mod")
				module.mod_mode = 1
			else if (href_list["target"] == "manifest")
				module.mod_mode = 0
		if("print")
			if(computer.has_component(PART_PRINTER)) //This option should never be called if there is no printer
				if(module.mod_mode)
					if(can_run(user, 1))
						var/contents = {"<h4>Access Report</h4>
									<u>Prepared By:</u> [user_id_card.registered_name ? user_id_card.registered_name : "Unknown"]<br>
									<u>For:</u> [id_card.registered_name ? id_card.registered_name : "Unregistered"]<br>
									<hr>
									<u>Assignment:</u> [id_card.assignment]<br>
									<u>Account Number:</u> #[id_card.associated_account_number]<br>
									<u>Email account:</u> [id_card.associated_email_login["login"]]
									<u>Email password:</u> [stars(id_card.associated_email_login["password"], 0)]
									<u>Blood Type:</u> [id_card.blood_type]<br><br>
									<u>Access:</u><br>
								"}

						var/known_access_rights = get_access_ids(ACCESS_TYPE_STATION|ACCESS_TYPE_CENTCOM)
						for(var/A in id_card.access)
							if(A in known_access_rights)
								contents += "  [get_access_desc(A)]"

						if(!computer.print_paper(contents,"access report"))
							to_chat(usr, SPAN_NOTICE("Hardware error: Printer was unable to print the file. It may be out of paper."))
							return
				else
					var/contents = {"<h4>Crew Manifest</h4>
									<br>
									[html_crew_manifest()]
									"}
					if(!computer.print_paper(contents, "crew manifest ([stationtime2text()])"))
						to_chat(usr, SPAN_NOTICE("Hardware error: Printer was unable to print the file. It may be out of paper."))
						return
		if("eject")
			var/obj/item/stock_parts/computer/card_slot/card_slot = computer.get_component(PART_CARD)
			if(computer.get_inserted_id())
				card_slot.eject_id(user)
			else
				card_slot.insert_id(user.get_active_hand(), user)
	if(!(computer && can_run(user, 1))) return
	switch(href_list["action"])
		if("search_by_id")
			if(id_card && faction)
				selected_record = faction.GetCrewRecord(id_card.registered_name)
				if(!selected_record)
					return NewRecord(user, id_card.registered_name, faction)
		if("search")
			var/temp_name = input("Enter name to lookup.", "Search by name", "")
			if(computer && can_run(user, 1))
				if(temp_name)
					selected_record = faction.GetCrewRecord(temp_name)
					if(!selected_record)
						return NewRecord(user, temp_name, faction)
		if("assign")
			if(!selected_record) return
			var/datum/assignment/assign = locate(href_list["assign_target"])
			selected_record.curr_assignment = assign
		if("assign_unassign")
			selected_record = locate(href_list["assign_target"]) // html exploit protection, every dangerous proc benefits from at least 1 locate
			selected_record.curr_assignment = null

	if(id_card)
		id_card.SetName(text("[id_card.registered_name]'s ID Card ([id_card.assignment])"))

	SSnano.update_uis(NM)
	return 1

/datum/computer_file/program/assignment/proc/NewRecord(var/mob/user, var/realname, var/datum/WorldFaction/faction)
	var/choice = alert(user, "No record found for '[realname]'. Would you like to create a new record?", "Confirmation","Yes", "No")
	if(choice != "Yes") return
	if(faction.GetCrewRecord(realname)) return
	if(computer && can_run(user, 1))
		var/datum/FactionRecord/new_record = new()
		new_record.set_name(realname)
		selected_record = new_record
		faction.crew_records |= new_record
	return TOPIC_REFRESH
