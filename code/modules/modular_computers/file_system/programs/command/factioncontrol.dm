#define MENU_LOGIN 0
#define MENU_ASSIGNMENTSEL 1
#define MENU_ASSIGNMENT 2
#define MENU_ACCESS 3
#define MENU_NETWORK 4
#define MENU_ASSIGNMENTCATSEL 5
#define MENU_FACTION 6


/datum/computer_file/program/factioncontrol
	filename = "factioncontrol"
	filedesc = "Faction Control Program"
	nanomodule_path = /datum/nano_module/program/factioncontrol
	program_icon_state = "id"
	program_key_state = "id_key"
	program_menu_icon = "key"
	extended_desc = "Program for managing Factions. No network card required."
	requires_ntnet = FALSE
	size = 8
	category = PROG_COMMAND

/datum/nano_module/program/factioncontrol
	name = "Faction Control Program"
	var/menu = MENU_LOGIN
	var/uid = ""
	var/password = ""
	var/datum/assignment/sel_assignment
	var/datum/assignment_category/sel_assigncat
	var/access_desc = ""

/datum/nano_module/program/factioncontrol/ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = 1, datum/topic_state/state = GLOB.default_state)
	var/list/data = host.initial_data()

	var/datum/WorldFaction/faction = GetWorldFactionGlobal(uid)
	if(!faction || faction.password != password) menu = MENU_LOGIN
	switch(menu)
		if(MENU_LOGIN)
			data["faction_uid"] = uid ? uid : "*UNSET*"
			data["faction_password"] = password ? password : "*UNSET*"
		if(MENU_ASSIGNMENTSEL)
			if(!sel_assignment) menu = MENU_ASSIGNMENT
			else
				data["assign_name"] = sel_assignment.name
				data["assign_rank"] = sel_assignment.rank
				data["assign_wage"] = sel_assignment.wage
				var/list/faction_access[0]
				for(var/access in default_access_list)
					var/selected
					if(access in sel_assignment.access) selected = 1
					faction_access.Add(list(list(
					"name" = access,
					"selected" = selected
					)))
				for(var/access in faction.access)
					var/selected
					if(access in sel_assignment.access) selected = 1
					faction_access.Add(list(list(
					"name" = access,
					"selected" = selected
					)))
				data["faction_access"] = faction_access

		if(MENU_ASSIGNMENT)
			var/list/assignment_categories[0]
			for(var/datum/assignment_category/category in faction.assignment_categories)
				assignment_categories.Add(list(list(
				"name" = category.name,
				"ref" = "\ref[category]",
				"num_assign" = category.assignments.len
				)))
			data["assignment_categories"] = assignment_categories
		if(MENU_ACCESS)
			var/list/default_access[0]
			for(var/access in default_access_list)
				default_access.Add(list(list(
				"name" = access
				)))
			var/list/faction_access[0]
			for(var/access in faction.access)
				faction_access.Add(list(list(
				"name" = access
				)))
			data["default_access"] = default_access
			data["faction_access"] = faction_access
			data["default_desc"] = access_desc
		if(MENU_NETWORK)
			data["isVisible"] = faction.network_visible
			data["network_pass"] = faction.network_password ? faction.network_password : "*Unset*"
		if(MENU_ASSIGNMENTCATSEL)
			if(!sel_assigncat) menu = MENU_ASSIGNMENT
			else
				data["assigncat_name"] = sel_assigncat.name
				var/list/ranks = list()
				for(var/datum/assignment/assign in sel_assigncat.assignments)
					ranks |= assign.rank
				var/list/assign_ranks[0]
				ranks = reverselist(ranks)
				for(var/rank in ranks)
					var/list/include_assign = list()
					for(var/datum/assignment/assign in sel_assigncat.assignments)
						if(assign.rank == rank) include_assign |= assign
					var/list/assignments[0]
					for(var/datum/assignment/assign in include_assign)
						assignments.Add(list(list(
						"assign_name" = assign.name,
						"assign_ref" = "\ref[assign]"
						)))
					assign_ranks.Add(list(list(
						"rank" = rank,
						"assignments" = assignments
						)))
				data["ranks"] = assign_ranks
				data["isCommand"] = sel_assigncat.command
		if(MENU_FACTION)
			data["faction_pass"] = faction.password
			data["faction_leader"] = faction.leader_name

	if(faction)
		data["faction_name"] = faction.display_name
	data["menu"] = menu
	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "factioncontrol.tmpl", name, 600, 700, state = state)
		ui.auto_update_layout = 1
		ui.set_initial_data(data)
		ui.open()

/datum/nano_module/program/factioncontrol/Topic(href, href_list)
	. = ..()
	if (.)
		return
	var/mob/user = usr
	var/datum/WorldFaction/faction = GetWorldFactionGlobal(uid)
	if(!faction || faction.password != password) menu = MENU_LOGIN

	switch(href_list["action"])
		if("login_uid")
			var/temp_name = input("Enter Faction UID.", "Faction UID", "")
			if(program.computer && program.can_run(user, 1))
				if(temp_name)
					uid = temp_name
					faction = GetWorldFactionGlobal(uid)
					if(faction && faction.password == password) menu = MENU_ASSIGNMENTSEL
					return TOPIC_REFRESH
		if("login_password")
			var/temp_name = input("Enter Faction Password.", "Faction Password", "")
			if(program.computer && program.can_run(user, 1))
				if(temp_name)
					password = temp_name
					faction = GetWorldFactionGlobal(uid)
					if(faction && faction.password == password) menu = MENU_ASSIGNMENTSEL
					return TOPIC_REFRESH
	if(!faction) return

	switch(href_list["action"])
		if("menu")
			menu = text2num(href_list["menu"])
			sel_assignment = null
			sel_assigncat = null
		if("assign_back")
			menu = MENU_ASSIGNMENTCATSEL
		if("assigncat")
			sel_assigncat = locate(href_list["assign_target"])
			menu = MENU_ASSIGNMENTCATSEL
		if("assigncat_new")
			var/temp_name = input("Enter Assignment Category Name", "Assignment Category Name", "")
			if(program.computer && program.can_run(user, 1))
				if(temp_name)
					var/datum/assignment_category/category = new()
					category.name = temp_name
					faction.assignment_categories |= category
					sel_assigncat = category
					menu = MENU_ASSIGNMENTCATSEL
		if("access_default")
			var/access = href_list["target"]
			switch(access)
				if(DEFAULT_ACCESS_ASSIGNMENT)
					access_desc = "With the 'Assignment' access you can reassign anyone of a lower rank to you to any assignment of a lower rank than you."
				if(DEFAULT_ACCESS_ENGINEERING)
					access_desc = "With the 'Engineering Devices' access you can unlock APCs and other engineering devices that are connected to this faction."

		if("access_delete")
			var/del_access = href_list["target"]
			faction.access -= del_access
		if("access_new")
			var/temp_name = input("Enter Access Name", "Access Name", "")
			if(program.computer && program.can_run(user, 1))
				if(temp_name)
					faction.access |= temp_name
		if("network_vis_on")
			faction.network_visible = 1
		if("network_vis_off")
			faction.network_visible = 0
		if("network_pass")
			var/temp_name = input("Enter Network Password", "Network Password", "")
			if(program.computer && program.can_run(user, 1))
				if(temp_name)
					if(temp_name != "") faction.network_password = temp_name
					else faction.network_password = null
				else faction.network_password = null
		if("assign_changename")
			var/temp_name = input("Enter Assignment Name", "Assignment Name", "")
			if(program.computer && program.can_run(user, 1))
				if(temp_name)
					sel_assignment.name = temp_name

		if("assign_rank")
			var/temp_name = input("Enter Rank") as num|null
			if(program.computer && program.can_run(user, 1))
				if(temp_name && temp_name >= 0)
					var/datum/assignment_category/cat = faction.GetAssignmentCategoryFor(sel_assignment)
					if(cat && cat.assignments.len > 1)
						cat.assignments -= sel_assignment
						var/i = 0
						var/found = 0
						for(var/datum/assignment/compare in cat.assignments)
							i++
							if(compare.rank >= temp_name)
								cat.assignments.Insert(i, sel_assignment)
								found = 1
								break
						if(!found)
							cat.assignments |= sel_assignment
					sel_assignment.rank = temp_name
		if("assign_wage")
			var/temp_name = input("Enter Wage") as num|null
			if(program.computer && program.can_run(user, 1))
				if(temp_name && temp_name >= 0)
					sel_assignment.wage = temp_name

		if("assign_access")
			var/access = href_list["target"]
			if(access in sel_assignment.access) sel_assignment.access -= access
			else sel_assignment.access |= access
		if("assigncat_changename")
			var/temp_name = input("Enter Assignment Category Name", "Assignment Category Name", "")
			if(program.computer && program.can_run(user, 1))
				if(temp_name)
					sel_assigncat.name = temp_name

		if("assign")
			sel_assignment = locate(href_list["assign_target"])
			menu = MENU_ASSIGNMENTSEL

		if("assign_new")
			var/temp_name = input("Enter Assignment Name", "Assignment Name", "")
			if(program.computer && program.can_run(user, 1))
				if(temp_name)
					var/datum/assignment/assign = new()
					assign.name = temp_name
					sel_assigncat.assignments.Insert(1, assign)
					sel_assignment = assign
					menu = MENU_ASSIGNMENTSEL
		if("command_on")
			sel_assigncat.command = 1
		if("command_off")
			sel_assigncat.command = 0
		if("faction_name")
			var/temp_name = input("Enter Faction Name", "Faction Display Name", "")
			if(program.computer && program.can_run(user, 1))
				if(temp_name)
					faction.display_name = temp_name
		if("faction_pass")
			var/temp_name = input("Enter Faction Password", "Faction Control Password", "")
			if(program.computer && program.can_run(user, 1))
				if(temp_name)
					faction.password = temp_name
					to_chat(user, "You changed the faction control password to [temp_name]")
		if("faction_leader")
			var/temp_name = input("Enter Faction Leader Name", "Faction Leader", "")
			if(program.computer && program.can_run(user, 1))
				if(temp_name)
					faction.leader_name = temp_name
		if("assign_delete")
			var/choice = alert(user, "Are you sure you want to delete [sel_assignment.name]?", "Confirmation","Yes", "No")
			if(choice != "Yes")
				return
			if(program.computer && program.can_run(user, 1))
				var/datum/assignment_category/cat = faction.GetAssignmentCategoryFor(sel_assignment)
				cat.assignments -= sel_assignment
		if("assigncat_delete")
			if(sel_assigncat.assignments.len)
				to_chat(user, "You cannot delete a category that has assignments under it.")
				return TOPIC_REFRESH
			var/choice = alert(user, "Are you sure you want to delete [sel_assigncat.name]?", "Confirmation","Yes", "No")
			if(choice != "Yes")
				return
			if(program.computer && program.can_run(user, 1))
				faction.assignment_categories -= sel_assigncat

	return TOPIC_REFRESH

#undef MENU_LOGIN
#undef MENU_ASSIGNMENTSEL
#undef MENU_ASSIGNMENT
#undef MENU_ACCESS
#undef MENU_NETWORK
#undef MENU_ASSIGNMENTCATSEL
#undef MENU_FACTION
