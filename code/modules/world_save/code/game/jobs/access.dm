//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:31

/obj/var/list/req_access = list()
/obj/var/list/req_one_access = list()
/obj/var/req_access_faction = ""
/obj/var/req_access_personal
/obj/var/list/req_access_personal_list = list()
/obj/var/req_access_business
/obj/var/list/req_access_business_list = list()
/obj/var/list/req_one_access_business_list = list()
//returns 1 if this mob has sufficient access to use this object
/obj/allowed(mob/M)
	//check if it doesn't require any access at all
	if(!istype(M))
		return 0

	if(req_access_personal_list && req_access_personal_list)
		for(var/nam in req_access_personal_list)
			if(M.get_id_name() == nam)
				return 1
	if(req_access_personal)
		if(M.get_id_name() == req_access_personal)
			return 1
		return 0
	if(req_access_business)
		var/datum/small_business/business = get_business(req_access_business)
		if(business)
			if(M.get_id_name() == business.ceo_name) return 1
			var/datum/employee_data/employee = business.get_employee_data(M.get_id_name())
			if(employee)
				var/pass = 1
				var/one_pass = 0
				for(var/x in req_access_business_list)		//needs all
					if(!(x in employee.accesses))
						pass = 0
						break								//Break since we found one required access that we don't have on a list that we need ALL
				if(req_one_access_business_list.len)
					for(var/x in req_one_access_business_list)
						if(x in employee.accesses)
							one_pass = 1
							break

				if(pass && (one_pass || !req_one_access_business_list.len) )
					return 1
			return 0
	if(src.check_access(null))
		return 1


	return check_access_list(M.GetAccess(req_access_faction))

/atom/movable/proc/get_req_access()
	return null

/proc/has_access_pattern(list/access_patterns, access)
	if(!islist(access))
		access = list(access)
	for(var/access_pattern in access_patterns)
		if(has_access(access_pattern, access))
			return 1

/obj/get_req_access()
	return req_access


/atom/movable/proc/check_access_list(list/L)
	var/list/R = get_req_access()

	if(!R)
		R = list()
	if(!istype(L, /list))
		return FALSE

	if(maint_all_access)
		L = L.Copy()
		L |= access_maint_tunnels

	return has_access(R, L)

/proc/get_access_region_by_id(id)
	var/datum/access/AD = get_access_by_id(id)
	return AD.region

//returns 1 if this mob has sufficient access to use this object
/atom/movable/proc/allowed(mob/M)
	//check if it doesn't require any access at all
	if(src.check_access(null))
		return TRUE
	if(!istype(M))
		return FALSE
	return check_access_list(M.GetAccess())

/atom/movable/proc/GetAccess(var/faction_uid)
	var/obj/item/weapon/card/id/id = GetIdCard()
	return id ? id.GetAccess(faction_uid) : list()
/atom/movable/proc/GetFaction()
	var/obj/item/weapon/card/id/id = GetIdCard()
	return id ? id.GetFaction() : ""
/atom/movable/proc/GetIdCard()
	return null

/atom/movable/proc/check_access(obj/item/I)
	return check_access_list(I ? I.GetAccess() : list())


/obj/check_access(obj/item/I)
	return check_access_list(I ? I.GetAccess(req_access_faction) : list())


/obj/check_access_list(var/list/L)
	if(!req_access)		req_access = list()
	if(!req_one_access)	req_one_access = list()
	if(!istype(L, /list))	return 0
	return has_access(req_access, req_one_access, L)

/proc/has_access(var/list/req_access, var/list/req_one_access, var/list/accesses)
	for(var/req in req_access)
		if(!(req in accesses)) //doesn't have this access
			return 0
	if(req_one_access.len)
		for(var/req in req_one_access)
			if(req in accesses) //has an access from the single access list
				return 1
		return 0
	return 1

/proc/get_centcom_access(job)
	switch(job)
		if("VIP Guest")
			return list(access_cent_general)
		if("Custodian")
			return list(access_cent_general, access_cent_living, access_cent_storage)
		if("Thunderdome Overseer")
			return list(access_cent_general, access_cent_thunder)
		if("Intel Officer")
			return list(access_cent_general, access_cent_living)
		if("Medical Officer")
			return list(access_cent_general, access_cent_living, access_cent_medical)
		if("Death Commando")
			return list(access_cent_general, access_cent_specops, access_cent_living, access_cent_storage)
		if("Research Officer")
			return list(access_cent_general, access_cent_specops, access_cent_medical, access_cent_teleporter, access_cent_storage)
		if("BlackOps Commander")
			return list(access_cent_general, access_cent_thunder, access_cent_specops, access_cent_living, access_cent_storage, access_cent_creed)
		if("Supreme Commander")
			return get_all_centcom_access()

/var/list/datum/access/priv_all_access_datums
/proc/get_all_access_datums()
	if(!priv_all_access_datums)
		priv_all_access_datums = init_subtypes(/datum/access)
		priv_all_access_datums = dd_sortedObjectList(priv_all_access_datums)

	return priv_all_access_datums.Copy()

/var/list/datum/access/priv_all_access_datums_id
/proc/get_all_access_datums_by_id()
	if(!priv_all_access_datums_id)
		priv_all_access_datums_id = list()
		for(var/datum/access/A in get_all_access_datums())
			priv_all_access_datums_id["[A.id]"] = A

	return priv_all_access_datums_id.Copy()

/var/list/datum/access/priv_all_access_datums_region
/proc/get_all_access_datums_by_region()
	if(!priv_all_access_datums_region)
		priv_all_access_datums_region = list()
		for(var/datum/access/A in get_all_access_datums())
			if(!priv_all_access_datums_region[A.region])
				priv_all_access_datums_region[A.region] = list()
			priv_all_access_datums_region[A.region] += A

	return priv_all_access_datums_region.Copy()

/proc/get_access_ids(var/access_types = ACCESS_TYPE_ALL)
	var/list/L = new()
	for(var/datum/access/A in get_all_access_datums())
		if(A.access_type & access_types)
			L += A.id
	return L

/var/list/priv_all_access
/proc/get_all_accesses()
	if(!priv_all_access)
		priv_all_access = get_access_ids()

	return priv_all_access.Copy()

/var/list/priv_station_access
/proc/get_all_station_access()
	if(!priv_station_access)
		priv_station_access = get_access_ids(ACCESS_TYPE_STATION)

	return priv_station_access.Copy()

/var/list/priv_centcom_access
/proc/get_all_centcom_access()
	if(!priv_centcom_access)
		priv_centcom_access = get_access_ids(ACCESS_TYPE_CENTCOM)

	return priv_centcom_access.Copy()

/var/list/priv_syndicate_access
/proc/get_all_syndicate_access()
	if(!priv_syndicate_access)
		priv_syndicate_access = get_access_ids(ACCESS_TYPE_SYNDICATE)

	return priv_syndicate_access.Copy()

/var/list/priv_region_access
/proc/get_region_accesses(var/code)
	if(code == ACCESS_REGION_ALL)
		return get_all_station_access()

	if(!priv_region_access)
		priv_region_access = list()
		for(var/datum/access/A in get_all_access_datums())
			if(!priv_region_access["[A.region]"])
				priv_region_access["[A.region]"] = list()
			priv_region_access["[A.region]"] += A.id

	var/list/region = priv_region_access["[code]"]
	return region.Copy()

/proc/get_region_accesses_name(var/code)
	switch(code)
		if(ACCESS_REGION_ALL)
			return "All"
		if(ACCESS_REGION_SECURITY) //security
			return "Security"
		if(ACCESS_REGION_MEDBAY) //medbay
			return "Medbay"
		if(ACCESS_REGION_RESEARCH) //research
			return "Research"
		if(ACCESS_REGION_ENGINEERING) //engineering and maintenance
			return "Engineering"
		if(ACCESS_REGION_COMMAND) //command
			return "Command"
		if(ACCESS_REGION_GENERAL) //station general
			return "General"
		if(ACCESS_REGION_SUPPLY) //supply
			return "Supply"

/proc/get_access_desc(id)
	var/list/AS = priv_all_access_datums_id || get_all_access_datums_by_id()
	var/datum/access/A = AS["[id]"]

	return A ? A.desc : ""

/proc/get_centcom_access_desc(A)
	return get_access_desc(A)

/proc/get_access_by_id(id)
	var/list/AS = priv_all_access_datums_id || get_all_access_datums_by_id()
	return AS[num2text(id)]

/proc/get_all_jobs()
	var/list/all_jobs = list()
	var/list/all_datums = typesof(/datum/job)
//	all_datums -= exclude_jobs
	var/datum/job/jobdatum
	for(var/jobtype in all_datums)
		jobdatum = new jobtype
		all_jobs.Add(jobdatum.title)
	return all_jobs

/proc/get_all_centcom_jobs()
	return list("VIP Guest",
		"Custodian",
		"Thunderdome Overseer",
		"Intel Officer",
		"Medical Officer",
		"Death Commando",
		"Research Officer",
		"BlackOps Commander",
		"Supreme Commander",
		"Emergency Response Team",
		"Emergency Response Team Leader")

/mob/observer/ghost
	var/static/obj/item/weapon/card/id/all_access/ghost_all_access

/mob/observer/ghost/GetIdCard()
	if(!is_admin(src))
		return

	if(!ghost_all_access)
		ghost_all_access = new()
	return ghost_all_access

/mob/living/bot/GetIdCard()
	return botcard

#define HUMAN_ID_CARDS list(get_active_hand(), wear_id, get_inactive_hand())
/mob/living/carbon/human/GetIdCard()
	for(var/item_slot in HUMAN_ID_CARDS)
		var/obj/item/I = item_slot
		var/obj/item/weapon/card/id = I ? I.GetIdCard() : null
		if(id)
			return id

/mob/living/carbon/human/GetAccess(var/faction_uid)
	. = list()
	for(var/item_slot in HUMAN_ID_CARDS)
		var/obj/item/I = item_slot
		if(I)
			. |= I.GetAccess(faction_uid)
#undef HUMAN_ID_CARDS

/mob/living/silicon/GetIdCard()
	if(stat || (ckey && !client))
		return // Unconscious, dead or once possessed but now client-less silicons are not considered to have id access.
	if(idcard)
		idcard.registered_name = real_name
	return idcard

/proc/FindNameFromID(var/mob/M, var/missing_id_name = "Unknown")
	var/obj/item/weapon/card/id/C = M.GetIdCard()
	if(C)
		return C.registered_name
	return missing_id_name


/proc/get_all_job_icons() //For all existing HUD icons
	return SSjobs.titles_to_datums + list("Prisoner")


/obj/proc/GetJobName() //Used in secHUD icon generation
	var/obj/item/weapon/card/id/I = GetIdCard()

	if(I)
		var/job_icons = get_all_job_icons()
		if(I.assignment	in job_icons) //Check if the job has a hud icon
			return I.assignment
		if(I.rank in job_icons)
			return I.rank

		var/centcom = get_all_centcom_jobs()
		if(I.assignment	in centcom) //Return with the NT logo if it is a Centcom job
			return "Centcom"
		if(I.rank in centcom)
			return "Centcom"
	else
		return

	return "Unknown" //Return unknown if none of the above apply
