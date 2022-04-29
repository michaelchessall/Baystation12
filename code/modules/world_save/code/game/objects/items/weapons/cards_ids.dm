/* Cards
 * Contains:
 *		DATA CARD
 *		ID CARD
 *		FINGERPRINT CARD HOLDER
 *		FINGERPRINT CARD
 */



/*
 * DATA CARDS - Used for the teleporter
 */

GLOBAL_LIST_EMPTY(all_id_cards)
GLOBAL_LIST_EMPTY(all_expense_cards)

/obj/item/card/union
	name = "union card"
	desc = "A card showing membership in the local worker's union."
	icon_state = "union"
	slot_flags = SLOT_ID
	var/signed_by

/obj/item/card/union/examine(mob/user)
	. = ..()
	if(signed_by)
		to_chat(user, "It has been signed by [signed_by].")
	else
		to_chat(user, "It has a blank space for a signature.")

/obj/item/card/union/attackby(var/obj/item/thing, var/mob/user)
	if(istype(thing, /obj/item/pen))
		if(signed_by)
			to_chat(user, SPAN_WARNING("\The [src] has already been signed."))
		else
			var/signature = sanitizeSafe(input("What do you want to sign the card as?", "Union Card") as text, MAX_NAME_LEN)
			if(signature && !signed_by && !user.incapacitated() && Adjacent(user))
				signed_by = signature
				user.visible_message(SPAN_NOTICE("\The [user] signs \the [src] with a flourish."))
		return
	..()

/obj/item/card
	name = "card"
	desc = "Does card things."
	icon = 'icons/obj/card.dmi'
	w_class = ITEM_SIZE_TINY
	slot_flags = SLOT_EARS

	var/list/files = list(  )

/obj/item/card/data
	name = "data disk"
	desc = "A disk of data."
	icon_state = "data"
	var/function = "storage"
	var/data = "null"
	var/special = null
	item_state = "card-id"

/obj/item/card/data/verb/label(t as text)
	set name = "Label Disk"
	set category = "Object"
	set src in usr

	if (t)
		src.name = text("data disk- '[]'", t)
	else
		src.name = "data disk"
	src.add_fingerprint(usr)
	return



/obj/item/card/data/full_color
	desc = "A plastic magstripe card for simple and speedy data storage and transfer. This one has the entire card colored."
	icon_state = "data_2"

/obj/item/card/data/disk
	desc = "A plastic magstripe card for simple and speedy data storage and transfer. This one inexplicibly looks like a floppy disk."
	icon_state = "data_3"

/obj/item/card/data/clown
	name = "\proper the coordinates to clown planet"
	icon_state = "data"
	item_state = "card-id"
	level = 2
	desc = "This card contains coordinates to the fabled Clown Planet. Handle with care."
	function = "teleporter"
	data = "Clown Land"

/*
 * ID CARDS
 */

/obj/item/card/emag_broken
	desc = "It's a card with a magnetic strip attached to some circuitry. It looks too busted to be used for anything but salvage."
	name = "broken cryptographic sequencer"
	icon_state = "emag"
	item_state = "card-id"
	origin_tech = list(TECH_MAGNET = 2, TECH_ILLEGAL = 2)

/obj/item/card/emag
	desc = "It's a card with a magnetic strip attached to some circuitry."
	name = "cryptographic sequencer"
	icon_state = "emag"
	item_state = "card-id"
	origin_tech = list(TECH_MAGNET = 2, TECH_ILLEGAL = 2)
	var/uses = 10

var/const/NO_EMAG_ACT = -50
/obj/item/card/emag/resolve_attackby(atom/A, mob/user)
	var/used_uses = A.emag_act(uses, user, src)
	if(used_uses == NO_EMAG_ACT)
		return ..(A, user)

	uses -= used_uses
	A.add_fingerprint(user)
	if(used_uses)
		log_and_message_admins("emagged \an [A].")

	if(uses<1)
		user.visible_message("<span class='warning'>\The [src] fizzles and sparks - it seems it's been used once too often, and is now spent.</span>")
		user.drop_item()
		var/obj/item/card/emag_broken/junk = new(user.loc)
		junk.add_fingerprint(user)
		qdel(src)

	return 1

/obj/item/card/attackby(var/obj/item/W, var/mob/user)
	if(isWelder(W))
		var/obj/item/weldingtool/WT = W
		if(WT.remove_fuel(0,user))
			for (var/mob/M in viewers(src))
				M.show_message("<span class='notice'>[src] is melted by [user.name] with the welding tool.</span>", 3, "<span class='notice'>You hear welding.</span>", 2)
			qdel(src)
		return
	if(isWirecutter(W))
		for (var/mob/M in viewers(src))
			M.show_message("<span class='notice'>[src] is sliced up by [user.name] with the wirecutters.</span>", 3, "<span class='notice'>You hear a snipping sound.</span>", 2)
		qdel(src)
		return

/obj/item/card/expense // the fabled expense card
	desc = "This card is used to expense invoices."
	name = "expense card"
	icon_state = "permit"
	item_state = "card-id"
	var/ctype = 1 // 1 = faction, 2 = business
	var/linked = "" // either business or faction
	var/valid = 1

/obj/item/card/expense/New()
	..()
	GLOB.all_expense_cards |= src

/obj/item/card/expense/proc/pay(var/amount, var/mob/user, var/obj/item/paper/invoice/invoice)
	if(!user || !invoice || !valid)
		return 0

	var/username = user.get_id_name("NULL!@#")
	if(username == "NULL!@#")
		to_chat(user, "Invalid ID!")
		return 0


	var/linked_name
	if(istype(invoice, /obj/item/paper/invoice/business))
		var/obj/item/paper/invoice/business/buis_invoice = invoice
		var/datum/small_business/business = get_business(buis_invoice.linked_business)
		linked_name = business.name
	else
		var/datum/world_faction/linked_faction = get_faction(invoice.linked_faction)
		linked_name = linked_faction.name

	if(ctype == 1)
		var/datum/world_faction/faction = get_faction(linked)
		if(!faction)
			message_admins("expense card without valid faction at [loc]")
			return 0
		var/datum/computer_file/report/crew_record/record = faction.get_record(username)
		if(!record)
			return 0
		var/datum/assignment/assignment = faction.get_assignment(record.assignment_uid)
		if(!assignment)
			return 0
		var/datum/accesses/copy = assignment.accesses["[record.rank]"]
		if(!copy)
			return 0
		var/available = copy.expense_limit - record.expenses
		if(available < amount)
			to_chat(user, "This exceeds your expense limit.")
			return 0
		if(faction.central_account.money < amount)
			to_chat(user, "Insufficent funds.")
			return 0

		var/datum/transaction/T = new("[linked_name] (via [username] expense card)", invoice.purpose, -amount, "Digital Invoice")
		faction.central_account.do_transaction(T)
		record.expenses += amount
		return 1
	else
		var/datum/small_business/business = get_business(linked)
		if(!business)
			message_admins("expense card without valid business at [loc]")
			return 0
		var/expenses = business.get_expenses(username)
		var/expense_limit = business.get_expense_limit(username)
		var/available = expense_limit - expenses
		if(available < amount)
			to_chat(user, "This exceeds your expense limit.")
			return 0
		if(business.central_account.money < amount)
			to_chat(user, "Insufficent funds.")
			return 0
		var/datum/transaction/T = new("[linked_name] (via [username] expense card)", invoice.purpose, -amount, "Digital Invoice")
		business.central_account.do_transaction(T)
		business.add_expenses(username, amount)
		return 1



/proc/devalidate_expense_cards(var/stype = 1, var/name)
	for(var/obj/item/card/expense/expense in GLOB.all_expense_cards)
		if(expense.ctype == stype && expense.linked == name)
			expense.name = "devalidated expense card"
			expense.linked = ""
			expense.valid = 0

/proc/update_ids(var/name)
	var/datum/computer_file/report/crew_record/record
	for(var/datum/computer_file/report/crew_record/record2 in GLOB.all_crew_records)
		if(record2.get_name() == name)
			record = record2
			break
	if(!record)
		record = Retrieve_Record(name)
	if(!record)
		message_admins("no record found for [name]")
		return

	for(var/obj/item/card/id/id in GLOB.all_id_cards)
		if(id.registered_name == name)
			if(id.validate_time < record.validate_time)
				id.devalidate()
				continue
			if(id.selected_faction)
				var/datum/world_faction/faction = get_faction(id.selected_faction)
				if(faction)
					var/datum/computer_file/report/crew_record/record2 = faction.get_record(id.registered_name)
					if(record2)
						id.sync_from_record(record2)
					else
						continue
				else
					continue
			else if(id.selected_business)
				if(id.valid)
					var/datum/small_business/business = get_business(id.selected_business)
					if(business)
						if(id.registered_name == business.ceo_name)
							id.assignment = business.ceo_title
							id.rank = 2	//actual job
							id.name = text("[id.registered_name]'s Name Tag ([id.assignment])")
						else
							var/datum/employee_data/employee = business.get_employee_data(id.registered_name)
							if(employee)
								id.assignment = employee.job_title
								id.rank = 1	//actual job
							else
								id.assignment = "Non-employee"
								id.rank = 0	//actual job
							id.name = text("[id.registered_name]'s Name Tag ([id.assignment])")
				else
					id.assignment = "DEVALIDATED"
					id.rank = 0	//actual job
					id.name = text("Devalidated Name Tag")
/obj/item/card/id
	name = "identification card"
	desc = "A card used to provide ID and determine access."
	icon_state = "base"
	item_state = "card-id"
	slot_flags = SLOT_ID

	var/list/access = list()
	var/registered_name = "Unknown" // The name registered_name on the card
	var/associated_account_number = 0
	var/list/associated_email_login = list("login" = "", "password" = "")

	var/age = "\[UNSET\]"
	var/blood_type = "\[UNSET\]"
	var/dna_hash = "\[UNSET\]"
	var/fingerprint_hash = "\[UNSET\]"
	var/sex = "\[UNSET\]"
	var/icon/front
	var/icon/side

	//alt titles are handled a bit weirdly in order to unobtrusively integrate into existing ID system
	var/assignment = null	//can be alt title or the actual job
	var/rank = null			//actual job
	var/dorm = 0			// determines if this ID has claimed a dorm already

	var/job_access_type     // Job type to acquire access rights from, if any

	var/datum/mil_branch/military_branch = null //Vars for tracking branches and ranks on multi-crewtype maps
	var/datum/mil_rank/military_rank = null

	var/formal_name_prefix
	var/formal_name_suffix

	var/detail_color
	var/extra_details

	var/selected_faction // faction this ID syncs to.. where should this be set?

	var/selected_business

	var/list/approved_factions = list() // factions that have approved this card for use on their machines. format-- list("[faction.uid]")
	var/validate_time = 0 // this should be set at the time of creation to check if the card is valid
	var/valid = 1
/obj/item/card/id/New()
	..()
	GLOB.all_id_cards |= src
/**	if(job_access_type)
		var/datum/job/j = job_master.GetJobByType(job_access_type)
		if(j)
			rank = j.title
			assignment = rank
			access |= j.get_access()
**/
/obj/item/card/id/examine(mob/user)
	set src in oview(1)
	if(in_range(usr, src))
		show(usr)
		to_chat(usr, desc)
	else
		to_chat(usr, "<span class='warning'>It is too far away.</span>")

/obj/item/card/id/proc/sync_from_record(var/datum/computer_file/report/crew_record/record)
	age = record.get_age()
	blood_type = record.get_bloodtype()
	dna_hash = record.get_dna()
	fingerprint_hash = record.get_fingerprint()
	sex = record.get_sex()
	front = record.photo_front
	side = record.photo_side
	if(record.terminated)
		assignment = "Terminated"
		rank = 0
	if(record.custom_title)
		assignment = record.custom_title	//can be alt title or the actual job
	else
		var/datum/world_faction/faction = get_faction(selected_faction)
		if(!faction) return
		var/datum/assignment/job = faction.get_assignment(record.assignment_uid)
		if(!job)
			assignment = "Unassigned"
			rank = 0
			name = text("[registered_name]'s ID Card [get_faction_tag(selected_faction)]-([assignment])")
			return
		if(record.rank > 1)
			assignment = job.ranks[record.rank-1]
		else
			assignment = job.name
	rank = record.rank	//actual job
	name = text("[registered_name]'s ID Card [get_faction_tag(selected_faction)]-([assignment])")

/obj/item/card/id/proc/prevent_tracking()
	return 0

/obj/item/card/id/proc/devalidate()
	rank = "Devalidated"
	assignment = "Devalidated"
	registered_name = "Devalidated"
	valid = 0
	update_name()

/obj/item/card/id/proc/show(mob/user as mob)
	if(front && side)
		user << browse_rsc(front, "front.png")
		user << browse_rsc(side, "side.png")
	var/datum/browser/popup = new(user, "idcard", name, 600, 250)
	popup.set_content(dat())
	popup.set_title_image(usr.browse_rsc_icon(src.icon, src.icon_state))
	popup.open()
	return

/obj/item/card/id/proc/update_name()
	if(!selected_business || selected_business == "")

		name = "[registered_name]'s ID Card"
		if(military_rank && military_rank.name_short)
			name = military_rank.name_short + " " + name
		if(assignment)
			name = name + " ([assignment])"
	else
		name = "[registered_name]'s Name Tag"
		if(assignment)
			name = name + " ([assignment])"
/obj/item/card/id/proc/set_id_photo(var/mob/M)
	front = getFlatIcon(M, SOUTH, always_use_defdir = 1)
	side = getFlatIcon(M, WEST, always_use_defdir = 1)

/mob/proc/set_id_info(var/obj/item/card/id/id_card)
	id_card.age = 0
	id_card.registered_name		= real_name
	id_card.sex 				= capitalize(gender)
	id_card.set_id_photo(src)

	if(dna)
		id_card.blood_type		= dna.b_type
		id_card.dna_hash		= dna.unique_enzymes
		id_card.fingerprint_hash= md5(dna.uni_identity)
	id_card.update_name()

/mob/living/carbon/human/set_id_info(var/obj/item/card/id/id_card)
	..()
	id_card.age = age

	if(GLOB.using_map.flags & MAP_HAS_BRANCH)
		id_card.military_branch = char_branch

	if(GLOB.using_map.flags & MAP_HAS_RANK)
		id_card.military_rank = char_rank

/obj/item/card/id/proc/dat()
	var/list/dat = list("<table><tr><td>")
	dat += text("Name: []</A><BR>", registered_name)
	dat += text("Sex: []</A><BR>\n", sex)
	dat += text("Age: []</A><BR>\n", age)

	if(GLOB.using_map.flags & MAP_HAS_BRANCH)
		dat += text("Branch: []</A><BR>\n", military_branch ? military_branch.name : "\[UNSET\]")
	if(GLOB.using_map.flags & MAP_HAS_RANK)
		dat += text("Rank: []</A><BR>\n", military_rank ? military_rank.name : "\[UNSET\]")

	dat += text("Assignment: []</A><BR>\n", assignment)
	dat += text("Fingerprint: []</A><BR>\n", fingerprint_hash)
	dat += text("Blood Type: []<BR>\n", blood_type)
	dat += text("DNA Hash: []<BR><BR>\n", dna_hash)
	if(front && side)
		dat +="<td align = center valign = top>Photo:<br><img src=front.png height=80 width=80 border=4><img src=side.png height=80 width=80 border=4></td>"
	dat += "</tr></table>"
	return jointext(dat,null)

/obj/item/card/id/attack_self(mob/user as mob)
	user.visible_message("\The [user] shows you: \icon[src] [src.name]. The assignment on the card: <font color=navy>[get_faction_tag(selected_faction)]</font>-([src.assignment])",\
		"You flash your ID card: \icon[src] [src.name]. The assignment on the card: <font color=navy>[get_faction_tag(selected_faction)]</font>-([src.assignment])")

	src.add_fingerprint(user)
	return
/obj/item/card/id/GetFaction()
	return selected_faction
/obj/item/card/id/GetAccess(var/faction_uid)
	if(!valid) return list()
	if(!faction_uid || faction_uid == "")
		faction_uid = selected_faction
	var/list/final_access[0]
	var/datum/world_faction/faction = get_faction(faction_uid)
	if(faction)
		if(faction.leader_name == registered_name)
			faction.rebuild_all_access()
			for(var/x in faction.all_access)
				final_access |= text2num(x)
			return final_access
		if(faction.allow_unapproved_ids || approved_factions.Find(faction.uid))
			var/datum/computer_file/report/crew_record/record = faction.get_record(registered_name)
			if(record)
				for(var/x in record.access)
					final_access |= text2num(x)
				if(faction.allow_id_access) final_access |= access
				var/datum/assignment/assignment = faction.get_assignment(record.try_duty())
				if(assignment)
					for(var/i=1; i<=record.rank; i++)
						var/datum/accesses/copy = assignment.accesses["[i]"]
						if(copy)
							for(var/x in copy.accesses)
								final_access |= text2num(x)
				return final_access
			else
				if(faction.allow_id_access)
					return access
				else
					return list()
	else
		return access

/obj/item/card/id/GetIdCard()
	return src

/obj/item/card/id/verb/read()
	set name = "Read ID Card"
	set category = "Object"
	set src in usr

	to_chat(usr, text("\icon[] []: The current assignment on the card is [].", src, src.name, src.assignment))
	to_chat(usr, "The blood type on the card is [blood_type].")
	to_chat(usr, "The DNA hash on the card is [dna_hash].")
	to_chat(usr, "The fingerprint hash on the card is [fingerprint_hash].")
	return

/obj/item/card/id/silver
	name = "identification card"
	desc = "A silver card which shows honour and dedication."
	item_state = "silver_id"
	job_access_type = /datum/job/hop

/obj/item/card/id/gold
	name = "identification card"
	desc = "A golden card which shows power and might."
	job_access_type = /datum/job/captain
	color = "#d4c780"
	extra_details = list("goldstripe")

/obj/item/card/id/syndicate_command
	name = "syndicate ID card"
	desc = "An ID straight from the Syndicate."
	registered_name = "Syndicate"
	assignment = "Syndicate Overlord"
	access = list(access_syndicate, access_external_airlocks)
	color = COLOR_RED_GRAY
	detail_color = COLOR_GRAY40

/obj/item/card/id/captains_spare
	name = "captain's spare ID"
	desc = "The spare ID of the High Lord himself."
	item_state = "gold_id"
	registered_name = "Captain"
	assignment = "Captain"
	detail_color = COLOR_AMBER

/obj/item/card/id/captains_spare/New()
	access = get_all_station_access()
	..()

/obj/item/card/id/synthetic
	name = "\improper Synthetic ID"
	desc = "Access module for lawed synthetics."
	icon_state = "robot_base"
	assignment = "Synthetic"
	detail_color = COLOR_AMBER

/obj/item/card/id/synthetic/New()
	access = get_all_station_access() + access_synth
	..()

/obj/item/card/id/centcom
	name = "\improper CentCom. ID"
	desc = "An ID straight from Cent. Com."
	registered_name = "Central Command"
	assignment = "General"
	color = COLOR_GRAY40
	detail_color = COLOR_COMMAND_BLUE
	extra_details = list("goldstripe")

/obj/item/card/id/centcom/New()
	access = get_all_centcom_access()
	..()

/obj/item/card/id/centcom/station/New()
	..()
	access |= get_all_station_access()

/obj/item/card/id/centcom/ERT
	name = "\improper Emergency Response Team ID"
	assignment = "Emergency Response Team"

/obj/item/card/id/centcom/ERT/New()
	..()
	access |= get_all_station_access()

/obj/item/card/id/foundation_civilian
	name = "operant registration card"
	desc = "A registration card in a faux-leather case. It marks the named individual as a registered, law-abiding psionic."
	icon_state = "warrantcard_civ"

/obj/item/card/id/foundation_civilian/on_update_icon()
	return

/obj/item/card/id/foundation
	name = "\improper Foundation warrant card"
	desc = "A warrant card in a handsome leather case."
	assignment = "Field Agent"
	icon_state = "warrantcard"

/obj/item/card/id/foundation/examine(mob/user, distance)
	. = ..()
	if(distance <= 1 && isliving(user))
		var/mob/living/M = user
		if(M.psi)
			to_chat(user, SPAN_WARNING("There is a psionic compulsion surrounding \the [src], forcing anyone who reads it to perceive it as a legitimate document of authority. The actual text just reads 'I can do what I want.'"))
		else
			to_chat(user, SPAN_NOTICE("This is the real deal, stamped by [GLOB.using_map.boss_name]. It gives the holder the full authority to pursue their goals. You believe it implicitly."))

/obj/item/card/id/foundation/attack_self(var/mob/living/user)
	. = ..()
	if(istype(user))
		for(var/mob/M in viewers(world.view, get_turf(user))-user)
			if(user.psi && isliving(M))
				var/mob/living/L = M
				if(!L.psi)
					to_chat(L, SPAN_NOTICE("This is the real deal, stamped by [GLOB.using_map.boss_name]. It gives the holder the full authority to pursue their goals. You believe \the [user] implicitly."))
					continue
			to_chat(M, SPAN_WARNING("There is a psionic compulsion surrounding \the [src] in a flicker of indescribable light."))

/obj/item/card/id/foundation/on_update_icon()
	return

/obj/item/card/id/foundation/New()
	..()
	access |= get_all_station_access()

/obj/item/card/id/all_access
	name = "\improper Administrator's spare ID"
	desc = "The spare ID of the Lord of Lords himself."
	registered_name = "Administrator"
	assignment = "Administrator"
	detail_color = COLOR_MAROON
	extra_details = list("goldstripe")

/obj/item/card/id/all_access/New()
	access = get_access_ids()
	..()

// Department-flavor IDs
/obj/item/card/id/medical
	name = "identification card"
	desc = "A card issued to medical staff."
	job_access_type = /datum/job/doctor
	detail_color = COLOR_PALE_BLUE_GRAY

/obj/item/card/id/medical/chemist
	job_access_type = /datum/job/chemist

/obj/item/card/id/medical/geneticist
	job_access_type = /datum/job/geneticist

/obj/item/card/id/medical/psychiatrist
	job_access_type = /datum/job/psychiatrist

/obj/item/card/id/medical/paramedic
	job_access_type = /datum/job/Paramedic

/obj/item/card/id/medical/head
	name = "identification card"
	desc = "A card which represents care and compassion."
	job_access_type = /datum/job/cmo
	extra_details = list("goldstripe")

/obj/item/card/id/security
	name = "identification card"
	desc = "A card issued to security staff."
	job_access_type = /datum/job/officer
	color = COLOR_OFF_WHITE
	detail_color = COLOR_MAROON

/obj/item/card/id/security/warden
	job_access_type = /datum/job/warden

/obj/item/card/id/security/detective
	job_access_type = /datum/job/detective

/obj/item/card/id/security/head
	name = "identification card"
	desc = "A card which represents honor and protection."
	job_access_type = /datum/job/hos
	extra_details = list("goldstripe")

/obj/item/card/id/engineering
	name = "identification card"
	desc = "A card issued to engineering staff."
	job_access_type = /datum/job/engineer
	detail_color = COLOR_SUN

/obj/item/card/id/engineering/head
	name = "identification card"
	desc = "A card which represents creativity and ingenuity."
	job_access_type = /datum/job/chief_engineer
	extra_details = list("goldstripe")

/obj/item/card/id/science
	name = "identification card"
	desc = "A card issued to science staff."
	job_access_type = /datum/job/scientist
	detail_color = COLOR_PALE_PURPLE_GRAY

/obj/item/card/id/science/xenobiologist
	job_access_type = /datum/job/xenobiologist

/obj/item/card/id/science/roboticist
	job_access_type = /datum/job/roboticist

/obj/item/card/id/science/head
	name = "identification card"
	desc = "A card which represents knowledge and reasoning."
	job_access_type = /datum/job/rd
	extra_details = list("goldstripe")

/obj/item/card/id/cargo
	name = "identification card"
	desc = "A card issued to cargo staff."
	job_access_type = /datum/job/cargo_tech
	detail_color = COLOR_BROWN

/obj/item/card/id/cargo/mining
	job_access_type = /datum/job/mining

/obj/item/card/id/cargo/head
	name = "identification card"
	desc = "A card which represents service and planning."
	job_access_type = /datum/job/qm
	extra_details = list("goldstripe")

/obj/item/card/id/civilian
	name = "identification card"
	desc = "A card issued to civilian staff."
	job_access_type = DEFAULT_JOB_TYPE
	detail_color = COLOR_CIVIE_GREEN

//	/obj/item/card/id/civilian/bartender
//		job_access_type = /datum/job/bartender

/obj/item/card/id/civilian/chef
	job_access_type = /datum/job/chef

/obj/item/card/id/civilian/botanist
	job_access_type = /datum/job/hydro

/obj/item/card/id/civilian/janitor
	job_access_type = /datum/job/janitor

/obj/item/card/id/civilian/librarian
	job_access_type = /datum/job/librarian

/obj/item/card/id/civilian/internal_affairs_agent
	job_access_type = /datum/job/lawyer
	detail_color = COLOR_NAVY_BLUE

/obj/item/card/id/civilian/chaplain
	job_access_type = /datum/job/chaplain

/obj/item/card/id/civilian/head //This is not the HoP. There's no position that uses this right now.
	name = "identification card"
	desc = "A card which represents common sense and responsibility."
	extra_details = list("goldstripe")

/obj/item/card/id/merchant
	name = "identification card"
	desc = "A card issued to Merchants, indicating their right to sell and buy goods."
	access = list(access_merchant)
	color = COLOR_OFF_WHITE
	detail_color = COLOR_BEIGE
