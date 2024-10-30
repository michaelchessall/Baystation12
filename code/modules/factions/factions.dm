var/global/list/all_world_factions = list()

/proc/GetWorldFactionGlobal(var/uid)
	for(var/datum/WorldFaction/faction in all_world_factions)
		if(faction.uid == uid)
			return faction

/proc/GetValidEDConnections(var/realname)
	var/list/results = list()
	for(var/datum/WorldFaction/faction in all_world_factions)
		var/list/access = faction.GetAccess(realname)
		if(DEFAULT_ACCESS_ENGINEERING in access) results |= faction
	return results

/proc/GetValidAssignments(var/realname)
	var/list/results = list()
	for(var/datum/WorldFaction/faction in all_world_factions)
		var/datum/FactionRecord/record = faction.GetCrewRecord(realname)
		if(record && record.curr_assignment) results[faction] = record
	return results

SAVED_VAR(/datum/WorldFaction, uid)
SAVED_VAR(/datum/WorldFaction, display_name)
SAVED_VAR(/datum/WorldFaction, password)
SAVED_VAR(/datum/WorldFaction, assignment_categories)
SAVED_VAR(/datum/WorldFaction, access)
SAVED_VAR(/datum/WorldFaction, leader_name)
SAVED_VAR(/datum/WorldFaction, network_password)
SAVED_VAR(/datum/WorldFaction, network_visible)
SAVED_VAR(/datum/WorldFaction, crew_records)
SAVED_VAR(/datum/WorldFaction, bank_account)



SAVED_VAR(/datum/FactionRecord, name)
SAVED_VAR(/datum/FactionRecord, curr_assignment)
SAVED_VAR(/datum/FactionRecord, minutesWorked)

/datum/FactionRecord
	var/name
	var/datum/assignment/curr_assignment
	var/minutesWorked

/datum/FactionRecord/proc/get_name()
	return name

/datum/FactionRecord/proc/set_name(nam)
	name = nam


/datum/WorldFaction

/datum/WorldFaction
	var/uid // unchanging unique string identfier
	var/display_name
	var/password // used to access the core faction control
	var/list/assignment_categories = list()
	var/list/access = list()
	var/leader_name = ""
	var/network_password
	var/network_visible = 0
	var/list/crew_records = list()
	var/datum/money_account/bank_account

/datum/WorldFaction/proc/setup()
	bank_account = create_faction_account(display_name, display_name)

/datum/WorldFaction/proc/PayPerson(var/datum/FactionRecord/record)
	var/pay = record.curr_assignment.wage
	if(pay > bank_account.money) return "[display_name] couldn't afford to pay your wage of $[pay]! You should contact your employer immediately!"
	var/datum/money_account/target_account = GetPersonalMoneyAccount(record.get_name())
	if(!target_account) return "Your bank account couldn't be found for your half hourly pay. CONTACT ADMINS TO HAVE THIS FIXED."
	var/datum/transaction/T = new(bank_account, target_account, pay, "Paid for 30 minutes of work as a [record.curr_assignment.name].")
	if(T.perform()) return
	else return "The pay transaction for your half hourly pay has failed. CONTACT ADMINS TO GET THIS FIXED."


/datum/WorldFaction/proc/GetAllAccess()
	var/list/result = default_access_list.Copy()
	for(var/x in access)
		result |= x
	return result


/datum/WorldFaction/proc/GetCrewRecord(var/realname)
	for(var/datum/FactionRecord/record in crew_records)
		if(record.get_name() == realname)
			return record

/datum/WorldFaction/proc/GetAccess(var/realname)
	if(realname == leader_name) return GetAllAccess()
	for(var/datum/FactionRecord/record in crew_records)
		if(record.get_name() == realname)
			if(record.curr_assignment)
				return record.curr_assignment.access
	return list()

/datum/WorldFaction/proc/GetAssignment(var/realname)
	for(var/datum/FactionRecord/record in crew_records)
		if(record.get_name() == realname)
			if(record.curr_assignment)
				return record.curr_assignment

/datum/WorldFaction/proc/GetAssignmentCategory(var/realname)
	var/datum/assignment/assignment
	for(var/datum/FactionRecord/record in crew_records)
		if(record.get_name() == realname)
			if(record.curr_assignment)
				assignment = record.curr_assignment
				break
	if(assignment)
		for(var/datum/assignment_category/category in assignment_categories)
			if(assignment in category.assignments)
				return category


/datum/WorldFaction/proc/IsCommand(var/realname)
	var/datum/assignment/assignment
	for(var/datum/FactionRecord/record in crew_records)
		if(record.get_name() == realname)
			if(record.curr_assignment)
				assignment = record.curr_assignment
				break
	if(assignment)
		for(var/datum/assignment_category/category in assignment_categories)
			if(assignment in category.assignments)
				return category.command

/datum/WorldFaction/New()
	. = ..()
	all_world_factions |= src

/datum/WorldFaction/proc/GetAllAssignments()
	var/list/all = list()
	for(var/datum/assignment_category/cat in assignment_categories)
		for(var/datum/assignment/assign in cat.assignments)
			all |= assign
	return all

SAVED_VAR(/datum/assignment, name)
SAVED_VAR(/datum/assignment, access)
SAVED_VAR(/datum/assignment, task)
SAVED_VAR(/datum/assignment, wage)
SAVED_VAR(/datum/assignment, rank)


/datum/WorldFaction/proc/GetAssignmentCategoryFor(var/datum/assignment/assignment)
	for(var/datum/assignment_category/cat in assignment_categories)
		if(assignment in cat.assignments)
			return cat

/datum/assignment
	var/name
	var/list/access = list()
	var/task = "" // a string description of what this job should be doing.
	var/wage = 0
	var/rank = 1

SAVED_VAR(/datum/assignment_category, name)
SAVED_VAR(/datum/assignment_category, command)
SAVED_VAR(/datum/assignment_category, assignments)

/datum/assignment_category
	var/name
	var/command = 0 // if 1, members of this category can reassign others outside of this category.
	var/list/assignments = list()

/obj/faction_spawner
	name = "Faction Spawner"

/obj/faction_spawner/New()
	var/datum/WorldFaction/faction = new()
	faction.uid = "nanotrasen"
	faction.display_name = "Nanotrasen"
	faction.network_visible = 1
	faction.password = "password"
	all_world_factions |= faction
	loc = null
	qdel_self()
	return
