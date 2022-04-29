
/datum/computer_file/report/crew_record
	var/datum/money_account/linked_account
//	var/list/access = list() // used for factional access
	var/suspended = 0
	var/terminated = 0
	var/assignment_uid
	var/list/promote_votes = list()
	var/list/demote_votes = list()
	var/rank = 0
	var/custom_title
	var/assignment_data = list() // format = list(assignment_uid = rank)
	var/validate_time = 0
	var/worked = 0
	var/expenses = 0
	var/datum/computer_file/data/email_account/email
/datum/computer_file/report/crew_record/proc/try_duty()
	if(suspended > world.realtime || terminated)
		return 0
	else
		return assignment_uid


/datum/computer_file/report/crew_record/proc/load_from_global(var/real_name)
	var/datum/computer_file/report/crew_record/record
	for(var/datum/computer_file/report/crew_record/R in GLOB.all_crew_records)
		if(R.get_name() == real_name)
			record = R
			break
	if(!record)
		record = Retrieve_Record(real_name)
	if(!record)
		return 0
	photo_front = record.photo_front
	photo_side = record.photo_side
	set_name(record.get_name())
	set_job(record.get_job())
	set_sex(record.get_sex())
	set_age(record.get_age())
	set_status(record.get_status())
	set_species(record.get_species())

	// Medical record
	set_bloodtype(record.get_bloodtype())
	set_medRecord("No record supplied")

	// Security record
	set_criminalStatus(GLOB.default_security_status)
	set_dna(record.get_dna())
	set_fingerprint(record.get_fingerprint())
	set_secRecord("No record supplied")

	// Employment record
	set_emplRecord("No record supplied")
	set_homeSystem(record.get_homeSystem())
	set_religion(record.get_religion())
	return 1


/datum/computer_file/report/crew_record/proc/check_rank_change(var/datum/world_faction/faction)
	var/list/all_promotes = list()
	var/list/three_promotes = list()
	var/list/five_promotes = list()
	var/list/all_demotes = list()
	var/list/three_demotes = list()
	var/list/five_demotes = list()
	var/datum/assignment/curr_assignment = faction.get_assignment(assignment_uid)
	if(!curr_assignment) return 0
	for(var/name in promote_votes)
		if(name == faction.leader_name)
			five_promotes |= name
			three_promotes |= name
			all_promotes |= name
			continue
		if(name == get_name()) continue
		var/datum/computer_file/report/crew_record/record = faction.get_record(name)
		if(record)
			var/datum/assignment/assignment = faction.get_assignment(record.assignment_uid)
			if(assignment)
				if(assignment.parent)
					var/promoter_command = (assignment.parent.command_faction)
					var/promoter_head = (assignment.parent.head_position && assignment.parent.head_position.uid == assignment.uid)
					var/curr_command = curr_assignment.parent.command_faction
					var/curr_head = (curr_assignment.parent.head_position && curr_assignment.parent.head_position.uid == curr_assignment.uid)
					var/same_dept = (assignment.parent.name == curr_assignment.parent.name)
					if(promoter_command)
						if(curr_command)
							if(curr_head)
								if(promoter_head)
									if(record.rank <= rank)
										continue
								else
									continue
					else
						if(curr_command) continue
						if(curr_head && !promoter_head) continue
						if(!same_dept) continue
						if(promoter_head)
							if(curr_head)
								if(record.rank <= rank)
									continue
						else
							if(record.rank <= rank)
								continue

		if(record.rank <= 5)
			five_promotes |= record.get_name()
		if(record.rank <= 3)
			three_promotes |= record.get_name()
		all_promotes |= record.get_name()


	if(five_promotes.len >= faction.five_promote_req)
		rank++
		promote_votes.Cut()
		demote_votes.Cut()
		update_ids(get_name())
		return
	if(three_promotes.len >= faction.three_promote_req)
		rank++
		promote_votes.Cut()
		demote_votes.Cut()
		update_ids(get_name())
		return
	if(all_promotes.len >= faction.all_promote_req)
		rank++
		promote_votes.Cut()
		demote_votes.Cut()
		update_ids(get_name())
		return
	for(var/name in demote_votes)

		if(name == faction.leader_name)
			five_promotes |= name
			three_promotes |= name
			all_promotes |= name
			continue
		if(name == get_name()) continue
		var/datum/computer_file/report/crew_record/record = faction.get_record(name)
		if(record)
			var/datum/assignment/assignment = faction.get_assignment(record.assignment_uid)
			if(assignment)
				if(assignment.parent)
					var/promoter_command = (assignment.parent.command_faction)
					var/promoter_head = (assignment.parent.head_position && assignment.parent.head_position.uid == assignment.uid)
					var/curr_command = curr_assignment.parent.command_faction
					var/curr_head = (curr_assignment.parent.head_position && curr_assignment.parent.head_position.uid == curr_assignment.uid)
					var/same_dept = (assignment.parent.name == curr_assignment.parent.name)
					if(promoter_command)
						if(curr_command)
							if(curr_head)
								if(promoter_head)
									if(record.rank <= rank)
										continue
								else
									continue
					else
						if(curr_command) continue
						if(curr_head && !promoter_head) continue
						if(!same_dept) continue
						if(promoter_head)
							if(curr_head)
								if(record.rank <= rank)
									continue
						else
							if(record.rank <= rank)
								continue

		if(record.rank <= 5)
			five_demotes |= record.get_name()
		if(record.rank <= 3)
			three_demotes |= record.get_name()
		all_demotes |= record.get_name()

	if(five_demotes.len >= faction.five_promote_req)
		rank--
		promote_votes.Cut()
		demote_votes.Cut()
		update_ids(get_name())
		return
	if(three_demotes.len >= faction.three_promote_req)
		rank--
		promote_votes.Cut()
		demote_votes.Cut()
		update_ids(get_name())
		return
	if(all_demotes.len >= faction.all_promote_req)
		rank--
		promote_votes.Cut()
		demote_votes.Cut()
		update_ids(get_name())
		return
