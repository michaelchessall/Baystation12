/datum/computer_file/program/card_mod
	filename = "cardmod"
	filedesc = "Account modification program"
	nanomodule_path = /datum/nano_module/program/card_mod
	program_icon_state = "id"
	program_menu_icon = "key"
	extended_desc = "Program for programming crew ."
	required_access = core_access_reassignment
	requires_ntnet = 1
	size = 8
	category = PROG_COMMAND
	usage_flags = PROGRAM_ALL
/datum/computer_file/program/card_mod/can_run(var/mob/living/user, var/loud = 0, var/access_to_check, var/obj/item/stock_parts/computer/network_card/network_card)
	// Defaults to required_access
	if(!access_to_check)
		access_to_check = required_access
	if(!access_to_check) // No required_access, allow it.
		return 1
	var/list/accesses_to_check = list()
	accesses_to_check |= access_to_check
	accesses_to_check |= core_access_promotion
	accesses_to_check |= core_access_employee_records
	accesses_to_check |= core_access_expenses
	accesses_to_check |= core_access_termination
	// Admin override - allows operation of any computer as aghosted admin, as if you had any required access.
	if(isghost(user) && check_rights(R_ADMIN, 0, user))
		return 1

	if(!istype(user))
		return 0
	if(computer && !network_card)
		network_card = computer.get_component(PART_NETWORK)
	var/obj/item/card/id/I = user.GetIdCard()
	if(!I)
		if(loud)
			to_chat(user, "<span class='notice'>\The [computer] flashes an \"RFID Error - Unable to scan ID\" warning.</span>")
		return 0
	if(network_card && network_card.connected_network && network_card.connected_network.holder)

		for(var/access in accesses_to_check)
			if(access in I.GetAccess(network_card.connected_network.holder.uid))
				return 1
		if(loud)
			to_chat(user, "<span class='notice'>\The [computer] flashes an \"Access Denied\" warning.</span>")
	else
		for(var/access in accesses_to_check)
			if(access in I.access)
				return 1
			else if(loud)
				to_chat(user, "<span class='notice'>\The [computer] flashes an \"Access Denied\" warning.</span>")

/datum/nano_module/program/card_mod
	name = "Account modification program"
	var/mod_mode = 1
	var/is_centcom = 0
	var/show_assignments = 0
	var/show_record = 0
	var/datum/computer_file/report/crew_record/record
	var/manifest_setting = 1
	var/submode = 0
/datum/nano_module/program/card_mod/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1, var/datum/topic_state/state = GLOB.default_state)

	var/list/data = host.initial_data()
	var/obj/item/card/id/user_id_card = user.GetIdCard()
	var/obj/item/stock_parts/computer/card_slot/card_slot = program.computer.get_component(PART_CARD)
	data["src"] = "\ref[src]"
	data["station_name"] = station_name()
	data["assignments"] = show_assignments
	var/datum/world_faction/connected_faction
	var/obj/item/stock_parts/computer/network_card/network_card = program.computer.get_component(PART_NETWORK)
	if(network_card && network_card.connected_network)
		connected_faction = network_card.connected_network.holder
	if(connected_faction)
		data["found_faction"] = 1
		data["faction_name"] = connected_faction.name
		data["manifest"] = html_crew_manifest_faction(null, null, connected_faction, manifest_setting)

	if(program && program.computer)
		data["have_id_slot"] = !!card_slot
		data["have_printer"] = program.computer.has_component(PART_PRINTER)
		data["authenticated"] = program.can_run(user)
	else
		data["have_id_slot"] = 0
		data["have_printer"] = 0
		data["authenticated"] = 0
	data["mmode"] = mod_mode
	data["submode"] = submode
	if(!mod_mode && !submode)
		data["manifest_button"] = 1
	data["centcom_access"] = is_centcom

	if(card_slot)
		var/obj/item/card/id/id_card = card_slot.stored_card
		data["has_id"] = !!id_card
		data["id_account_number"] = id_card ? id_card.associated_account_number : null
		data["id_rank"] = id_card && id_card.assignment ? id_card.assignment : "Unassigned"
		data["id_owner"] = id_card && id_card.registered_name ? id_card.registered_name : "-----"
		data["id_name"] = id_card ? id_card.name : "-----"
	data["has_record"] = !!record
	data["record_name"] = record ? record.get_name() : "-Search by name-"
	if(record)
		if(record.terminated)
			data["duty_status"] = "Terminated"
			data["terminated"] = 1
		else if(record.suspended > world.realtime)
			data["duty_status"] = "Suspended"
			data["suspended"] = 1
		else
			switch(connected_faction.get_duty_status(record.get_name()))
				if(0)
					data["duty_status"] = "Off network"
				if(1)
					data["duty_status"] = "On network, Off duty"
				if(2)
					data["duty_status"] = "On duty"
		var/datum/assignment/assignment = connected_faction.get_assignment(record.assignment_uid)
		if(assignment)
			data["assignment_uid"] = assignment.uid
			data["current_rank"] = record.rank
			var/promote_button = 0
			var/demote_button = 0
			var/max_rank = assignment.ranks.len + 1
			if(user_id_card)
				for(var/name in record.promote_votes)
					if(name == user_id_card.registered_name)
						promote_button = 2
						break
				for(var/name in record.demote_votes)
					if(name == user_id_card.registered_name)
						demote_button = 2
						break
				if(!promote_button)
					for(var/name in record.demote_votes)
						if(name == user_id_card.registered_name)
							demote_button = 2
							break
				if(!promote_button)
					if(record.rank < max_rank)
						promote_button = 1
				if(!demote_button)
					if(record.rank != 1)
						demote_button = 1
			data["promote_button"] = promote_button
			data["demote_button"] = demote_button
			var/expense_limit = 0
			var/datum/accesses/expenses = assignment.accesses["[record.rank]"]
			if(expenses)
				expense_limit = expenses.expense_limit
			data["expense_limit"] = expense_limit
			data["expenses"] = record.expenses
			if(record.rank == 1)
				data["title"] = assignment.name
			else
				var/use_rank = record.rank
				if(record.rank-1 > assignment.ranks.len)
					use_rank = assignment.ranks.len+1
				data["title"] = assignment.ranks[use_rank-1]
			if(record.custom_title)
				data["custom_title"] = record.custom_title
			else
				data["custom_title"] = "None"
		else
			data["assignment_uid"] = "None"
			data["current_rank"] = "None"
			data["promote_button"] = 0
			data["demote_button"] = 0
			data["title"] = "None"
			data["custom_title"] = "None"
		var/list/assignment_categories[0]
		var/none_select = 1
		for(var/datum/assignment_category/category in connected_faction.assignment_categories)
			assignment_categories[++assignment_categories.len] = list("name" = category.name, "assignments" = list())
			for(var/datum/assignment/assignmentz in category.assignments)
				var/selected = 0
				var/x = text2num(record.assignment_data[assignmentz.uid])
				var/title = ""
				if(x && x > 1 && assignmentz.ranks.len >= x-1)
					title = assignmentz.ranks[x-1]
				else
					title = assignmentz.name
				if(assignment && assignment.uid == assignmentz.uid)
					selected = 1
					none_select = 0
				assignment_categories[assignment_categories.len]["assignments"] += list(list(
				"name" = title,
				"ref" = "\ref[assignmentz]",
				"selected" = selected
				))
		data["none_select"] = none_select
		data["assignment_categories"] = assignment_categories
		data["record_val"] = pencode2html(record.get_emplRecord())
		data["record"] = show_record
	if(card_slot.stored_card)
		var/obj/item/card/id/id_card = card_slot.stored_card
		if(is_centcom)
			var/list/all_centcom_access = list()
			for(var/access in get_all_centcom_access())
				all_centcom_access.Add(list(list(
					"desc" = replacetext(get_centcom_access_desc(access), " ", "&nbsp"),
					"ref" = access,
					"allowed" = (access in id_card.access) ? 1 : 0)))
			data["all_centcom_access"] = all_centcom_access
		else
			var/list/regions = list()
			for(var/i = 1; i <= 7; i++)
				var/list/accesses = list()
				for(var/access in get_region_accesses(i))
					if (get_access_desc(access))
						accesses.Add(list(list(
							"desc" = replacetext(get_access_desc(access), " ", "&nbsp"),
							"ref" = access,
							"allowed" = (access in id_card.access) ? 1 : 0)))

				regions.Add(list(list(
					"name" = get_region_accesses_name(i),
					"accesses" = accesses)))
			data["regions"] = regions

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "identification_computer2Z.tmpl", name, 600, 700, state = state)
		ui.auto_update_layout = 1
		ui.set_initial_data(data)
		ui.open()





/datum/nano_module/program/card_mod/proc/format_jobs(list/jobs)
	var/obj/item/stock_parts/computer/card_slot/card_slot
	var/obj/item/card/id/id_card = card_slot ? card_slot.stored_card : null
	var/list/formatted = list()
	for(var/job in jobs)
		formatted.Add(list(list(
			"display_name" = replacetext(job, " ", "&nbsp"),
			"target_rank" = id_card && id_card.assignment ? id_card.assignment : "Unassigned",
			"job" = job)))

	return formatted

/datum/nano_module/program/card_mod/proc/get_accesses(var/is_centcom = 0)
	return null


/datum/computer_file/program/card_mod/Topic(href, href_list)
	if(..())
		return 1
	var/isleader = 0
	var/mob/user = usr
	var/obj/item/card/id/user_id_card = user.GetIdCard()
	if(!user_id_card || !user_id_card.valid)
		return 0
	var/obj/item/card/id/id_card
	var/datum/computer_file/report/crew_record/user_record
	var/list/user_accesses = list()
	var/obj/item/stock_parts/computer/card_slot/card_slot = computer.get_component(PART_CARD)
	if (card_slot)
		id_card = card_slot.stored_card
	var/datum/world_faction/connected_faction
	var/obj/item/stock_parts/computer/network_card/network_card = computer.get_component(PART_NETWORK)
	if(network_card && network_card.connected_network)
		connected_faction = network_card.connected_network.holder

	if(connected_faction)
		user_record = connected_faction.get_record(user_id_card.registered_name)
		if(user_record)
			user_accesses = user_id_card.GetAccess(connected_faction.uid)
		if(connected_faction.leader_name == user_id_card.registered_name)
			isleader = 1
	else
		return 0
	var/datum/nano_module/program/card_mod/module = NM
	switch(href_list["action"])
		if("scan_id")
			if(!id_card)
				return
			module.record = null
			var/datum/computer_file/report/crew_record/record = connected_faction.get_record(id_card.registered_name)
			if(!record && id_card.registered_name)
				if(!user_id_card) return
				if(!(isghost(user) && check_rights(R_ADMIN, 0, user)) && !isleader && !(core_access_reassignment in user_accesses))
					to_chat(usr, "No record is on file for [id_card.registered_name]. Insufficent access to add new members.")
					return 0
				if(!connected_faction.hiring_policy)
					if(!(isghost(user) && check_rights(R_ADMIN, 0, user)) && !isleader && !connected_faction.in_command(user_id_card.registered_name))
						to_chat(usr, "No record is on file for [id_card.registered_name]. Only members of Command categories can add new names to the records.")
						return 0
				var/choice = input(usr,"No record is on file for [id_card.registered_name]. Would you like to create a new record for [id_card.registered_name] based on information found in public records?") in list("Create", "Cancel")
				if(choice == "Cancel") return 1
				if(!connected_faction.get_record(id_card.registered_name) && module)
					record = new()
					if(!record.load_from_global(id_card.registered_name))
						to_chat(user, "No public records have been found for [id_card.registered_name]. Record creation aborted.")
						return 0
					connected_faction.records.faction_records |= record
					module.record = record
			else
				module.record = record
		if("search_name")
			module.record = null
			var/select_name = input(usr,"Enter the name of the record to search for.","Record Search", "") as null|text
			if(select_name)
				var/datum/computer_file/report/crew_record/record = connected_faction.get_record(select_name)
				if(!record)
					if(!user_id_card) return
					if(!(isghost(user) && check_rights(R_ADMIN, 0, user)) && !isleader && !(core_access_reassignment in user_accesses))
						to_chat(usr, "No record is on file for [select_name]. Insufficent access to add new members.")
						return 0
					if(!connected_faction.hiring_policy)
						if(!(isghost(user) && check_rights(R_ADMIN, 0, user)) && !isleader && !connected_faction.in_command(user_id_card.registered_name))
							to_chat(usr, "No record is on file for [select_name]. Only members of Command categories can add new names to the records.")
							return 0
					var/choice = input(usr,"No record is on file for [select_name]. Would you like to create a new record for [select_name] based on information found in public records?") in list("Create", "Cancel")
					if(choice == "Cancel") return 1
					if(!connected_faction.get_record(select_name) && module)
						record = new()
						if(!record.load_from_global(select_name))
							to_chat(user, "No public records have been found for [select_name]. Record creation aborted.")
							return 0
						connected_faction.records.faction_records |= record
						module.record = record
				else
					module.record = record

		if("switchm")
			if(href_list["target"] == "mod")
				module.mod_mode = 1
				module.submode = 0
			else if (href_list["target"] == "manifest")
				module.mod_mode = 0
				module.submode = 0
			else if (href_list["target"] == "id")
				module.mod_mode = 0
				module.submode = 1
		if("togglea")
			if(module.show_assignments)
				module.show_assignments = 0
			else
				module.show_assignments = 1
				module.show_record = 0
		if("toggler")
			if(module.show_record)
				module.show_record = 0
			else
				module.show_assignments = 0
				module.show_record = 1
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
							to_chat(usr, "<span class='notice'>Hardware error: Printer was unable to print the file. It may be out of paper.</span>")
							return
				else
					var/contents = {"<h4>Crew Manifest</h4>
									<br>
									[html_crew_manifest_faction()]
									"}
					if(!computer.print_paper(contents, "crew manifest ([stationtime2text()])"))
						to_chat(usr, "<span class='notice'>Hardware error: Printer was unable to print the file. It may be out of paper.</span>")
						return
		if("eject")
			if(computer.get_inserted_id())
				card_slot.eject_id(user)
			else
				card_slot.insert_id(user.get_active_hand(), user)
		if("terminate")
			if(computer && can_run(user, 1))
				if(!(isghost(user) && check_rights(R_ADMIN, 0, user)) && !isleader && !(core_access_termination in user_accesses))
					to_chat(usr, "Access Denied.")
					return 0
				if(!(isghost(user) && check_rights(R_ADMIN, 0, user)) && !isleader && !connected_faction.outranks(user_id_card.registered_name, module.record.get_name()))
					to_chat(usr, "Insufficent Rank.")
					return 0
				module.record.terminated = 1
				update_ids(module.record.get_name())
		if("unterminate")
			if(computer && can_run(user, 1))
				if(!(isghost(user) && check_rights(R_ADMIN, 0, user)) && !isleader && !(core_access_termination in user_accesses))
					to_chat(usr, "Access Denied.")
					return 0
				if(!(isghost(user) && check_rights(R_ADMIN, 0, user)) && !isleader && !connected_faction.outranks(user_id_card.registered_name, module.record.get_name()))
					to_chat(usr, "Insufficent Rank.")
					return 0
				module.record.terminated = 0
				update_ids(module.record.get_name())
		if("reset_expenses")
			if(computer && can_run(user, 1))
				if(!(isghost(user) && check_rights(R_ADMIN, 0, user)) && !isleader && !(core_access_expenses in user_accesses))
					to_chat(usr, "Access Denied.")
					return 0
				module.record.expenses = 0
		if("assign")
			if(computer && can_run(user, 1))
				if(!user_id_card) return
				if(!(isghost(user) && check_rights(R_ADMIN, 0, user)) && !isleader && !(core_access_reassignment in user_accesses))
					to_chat(usr, "Access Denied.")
					return 0
				if(!(isghost(user) && check_rights(R_ADMIN, 0, user)) && !isleader && !connected_faction.outranks(user_id_card.registered_name, module.record.get_name()))
					to_chat(usr, "Insufficent Rank.")
					return 0
				var/t1 = href_list["assign_target"]
				if(t1 == "Custom")
					if( check_rights(R_ADMIN, 0, user) || isleader || connected_faction.in_command(user_id_card.registered_name))
						var/temp_t = sanitize(input("Enter a custom title.","Assignment", module.record.custom_title), 45)
						//let custom jobs function as an impromptu alt title, mainly for sechuds
						if(temp_t)
							module.record.custom_title = temp_t
					else
						to_chat(usr, "Only command staff can grant custom titles.")
						return 0
				else
					var/datum/computer_file/report/crew_record/record = connected_faction.get_record(user_id_card.registered_name)
					var/datum/assignment/user_assignment = null
					if(!isghost(user))
						user_assignment = connected_faction.get_assignment(record.assignment_uid)
					var/datum/assignment/assignment = locate(href_list["assign_target"])
					if(!assignment) return 0
					if(check_rights(R_ADMIN, 0, user) || connected_faction.in_command(user_id_card.registered_name) || (user_assignment && user_assignment.parent.name == assignment.parent.name) || isleader)
						module.record.assignment_data[module.record.assignment_uid] = "[module.record.rank]"
						module.record.assignment_uid = assignment.uid
						module.record.rank = text2num(module.record.assignment_data[assignment.uid])
						if(!module.record.rank)
							module.record.rank = 1
						module.record.custom_title = null
					else
						to_chat(usr, "You can only make assignments in your own category.")
						return 0
					update_ids(module.record.get_name())
		if("access")
			if(href_list["allowed"] && computer && can_run(user, 1))
				var/access_type = text2num(href_list["access_target"])
				var/access_allowed = text2num(href_list["allowed"])
				if(access_type in get_access_ids(ACCESS_TYPE_STATION|ACCESS_TYPE_CENTCOM))
					id_card.access -= access_type
					if(!access_allowed)
						id_card.access += access_type
		if("promote")
			if(!user_id_card) return
			if(!(isghost(user) && check_rights(R_ADMIN, 0, user)) && !isleader && !(core_access_promotion in user_accesses))
				to_chat(usr, "Access Denied.")
				return 0
			if(!(isghost(user) && check_rights(R_ADMIN, 0, user)) && !isleader && !connected_faction.outranks(user_id_card.registered_name, module.record.get_name()))
				to_chat(usr, "Insufficent Rank.")
				return 0
			module.record.promote_votes |= user_id_card.registered_name
			module.record.check_rank_change(connected_faction)
		if("demote")
			if(!user_id_card) return
			if(!(isghost(user) && check_rights(R_ADMIN, 0, user)) && !isleader && !(core_access_promotion in user_accesses))
				to_chat(usr, "Access Denied.")
				return 0
			if(!(isghost(user) && check_rights(R_ADMIN, 0, user)) && !isleader && !connected_faction.outranks(user_id_card.registered_name, module.record.get_name()))
				to_chat(usr, "Insufficent Rank.")
				return 0
			module.record.demote_votes |= user_id_card.registered_name
			module.record.check_rank_change(connected_faction)
		if("promote_cancel")
			if(!user_id_card) return
			module.record.promote_votes -= user_id_card.registered_name
		if("demote_cancel")
			if(!user_id_card) return
			module.record.promote_votes -= user_id_card.registered_name
		if("register_id")
			id_card.approved_factions |= connected_faction.uid
			to_chat(user, "Card successfully approved for [connected_faction.name]")
		if("resync_id")
			id_card.approved_factions |= connected_faction.uid
			id_card.selected_faction = connected_faction.uid
			to_chat(user, "Card successfully resynced to [connected_faction.name]")
			update_ids(id_card.registered_name)
		if("edit_record")
			if(!(isghost(user) && check_rights(R_ADMIN, 0, user)) && !isleader && !(core_access_employee_records in user_accesses))
				to_chat(usr, "Access Denied.")
				return 0
			if(!(isghost(user) && check_rights(R_ADMIN, 0, user)) && !isleader && !connected_faction.outranks(user_id_card.registered_name, module.record.get_name()))
				to_chat(usr, "Insufficent Rank.")
				return 0
			var/newValue
			newValue = replacetext(input(usr, "Edit the employee record. You may use HTML paper formatting tags:", "Record edit", replacetext(html_decode(module.record.get_emplRecord()), "\[br\]", "\n")) as null|message, "\n", "\[br\]")
			if(newValue)
				module.record.set_emplRecord(newValue)
	if(id_card)
		id_card.name = text("[id_card.registered_name]'s ID Card [get_faction_tag(id_card.selected_faction)]-([id_card.assignment])")

	SSnano.update_uis(NM)
	return 1

/datum/computer_file/program/card_mod/proc/remove_nt_access(var/obj/item/card/id/id_card)
	id_card.access -= get_access_ids(ACCESS_TYPE_STATION|ACCESS_TYPE_CENTCOM)

/datum/computer_file/program/card_mod/proc/apply_access(var/obj/item/card/id/id_card, var/list/accesses)
	id_card.access |= accesses



/proc/html_crew_manifest_faction(var/monochrome, var/OOC, var/datum/world_faction/connected_faction, var/setting = 1) // setting 1 = online members, setting 2 = all members
	if(!connected_faction) return
	var/list/dept_data[0]
	for(var/datum/assignment_category/category in connected_faction.assignment_categories)
		dept_data += "0"
		dept_data[dept_data.len] = list("names" = list(), "header" = category.name, "flag" = category.name)
	dept_data += "0"
	dept_data[dept_data.len] = list("names" = list(), "header" = "Miscellaneous", "flag" = MSC)
	dept_data += "0"
	dept_data[dept_data.len] = list("names" = list(), "header" = "Off duty", "flag" = "Off duty")
	var/list/misc //Special departments for easier access
	for(var/list/department in dept_data)
		if(department["flag"] == MSC)
			misc = department["names"]

	var/list/isactive = new()
	var/list/mil_ranks = list() // HTML to prepend to name
	var/dat = {"
	<head><style>
		.manifest {border-collapse:collapse;}
		.manifest td, th {border:1px solid [monochrome?"black":"[OOC?"black; background-color:#272727; color:white":"#DEF; background-color:white; color:black"]"]; padding:.25em}
		.manifest th {height: 2em; [monochrome?"border-top-width: 3px":"background-color: [OOC?"#40628a":"#48c"]; color:white"]}
		.manifest tr.head th { [monochrome?"border-top-width: 1px":"background-color: [OOC?"#013D3B;":"#488;"]"] }
		.manifest td:first-child {text-align:right}
		.manifest tr.alt td {[monochrome?"border-top-width: 2px":"background-color: [OOC?"#373737; color:white":"#DEF"]"]}
	</style></head>
	<table class="manifest" width='350px'>
	<tr class='head'><th>Name</th><th>Position</th><th>Activity</th></tr>
	"}
	// sort mobs
	var/list/records = list()
	var/list/offduty = list()
	if(setting == 1)
		for(var/obj/item/organ/internal/stack/stack in connected_faction.connected_laces)
			var/datum/computer_file/report/crew_record/record = connected_faction.get_record(stack.get_owner_name())
			if(!record)
				continue
			if(stack.duty_status)
				records |= record
			else
				offduty |= record
	else
		for(var/datum/computer_file/report/crew_record/R in connected_faction.records.faction_records)
			records |= R

	for(var/datum/computer_file/report/crew_record/CR in records)
		var/name = CR.get_name()
		var/datum/assignment/assignment = connected_faction.get_assignment(CR.assignment_uid)
		var/rank
		if(CR.custom_title)
			rank = CR.custom_title
		if(assignment)
			if(!rank)
				var/x = text2num(CR.assignment_data[assignment.uid])
				if(x && x > 1)
					rank = assignment.ranks[x-1]
				else
					rank = assignment.name
			var/found_place = 0
			var/datum/assignment_category/category = assignment.parent
			if(category)
				for(var/list/department in dept_data)
					var/list/names = department["names"]
					if(category.name == department["flag"])
						names[name] = rank
						found_place = 1
			if(!found_place)
				var/list/names = misc["names"]
				names[name] = rank
		else
			if(!rank) rank = "Unset"
			var/list/names = misc["names"]
			names[name] = rank
		mil_ranks[name] = ""

//		if(GLOB.using_map.flags & MAP_HAS_RANK)
		//	var/datum/mil_branch/branch_obj = mil_branches.get_branch(CR.get_branch())
		//	var/datum/mil_rank/rank_obj = mil_branches.get_rank(CR.get_branch(), CR.get_rank())

		//	if(branch_obj && rank_obj)
		//		mil_ranks[name] = "<abbr title=\"[rank_obj.name], [branch_obj.name]\">[rank_obj.name_short]</abbr> "

		var/active = 0
		for(var/mob/M in GLOB.player_list)
			if(M.real_name == name && M.client && M.client.inactivity <= 10 * 60 * 10)
				active = 1
				break
		isactive[name] = active ? "Active" : "Inactive"
	for(var/datum/computer_file/report/crew_record/CR in offduty)
		var/name = CR.get_name()
		var/datum/assignment/assignment = connected_faction.get_assignment(CR.assignment_uid)
		var/rank
		if(CR.custom_title)
			rank = CR.custom_title
		if(assignment)
			if(!rank)
				var/x = text2num(CR.assignment_data[assignment.uid])
				if(x && x > 1)
					rank = assignment.ranks[x-1]
				else
					rank = assignment.name
		if(!rank) rank = "Unset"
		for(var/list/department in dept_data)
			var/list/names = department["names"]
			if(department["flag"] == "Off duty")
				names[name] = rank
		mil_ranks[name] = ""

//		if(GLOB.using_map.flags & MAP_HAS_RANK)
//			var/datum/mil_branch/branch_obj = mil_branches.get_branch(CR.get_branch())
//			var/datum/mil_rank/rank_obj = mil_branches.get_rank(CR.get_branch(), CR.get_rank())

//			if(branch_obj && rank_obj)
//				mil_ranks[name] = "<abbr title=\"[rank_obj.name], [branch_obj.name]\">[rank_obj.name_short]</abbr> "

		var/active = 0
		for(var/mob/M in GLOB.player_list)
			if(M.real_name == name && M.client && M.client.inactivity <= 10 * 60 * 10)
				active = 1
				break
		isactive[name] = active ? "Active" : "Inactive"
	for(var/list/department in dept_data)
		var/list/names = department["names"]
		if(names.len > 0)
			dat += "<tr><th colspan=3>[department["header"]]</th></tr>"
			for(var/name in names)
				if(isactive[name] != "Inactive")
					dat += "<tr class='candystripe'><td>[mil_ranks[name]][name]</td><td>[names[name]]</td><td>[isactive[name]]</td></tr>"

	dat += "</table>"
	dat = replacetext(dat, "\n", "") // so it can be placed on paper correctly
	dat = replacetext(dat, "\t", "")
	return dat



