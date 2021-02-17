
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


