//Shuttle controller computer for shuttles going between sectors
/obj/machinery/computer/shuttle_control/explore
	name = "general shuttle control console"
	ui_template = "shuttle_control_console_exploration.tmpl"
	base_type = /obj/machinery/computer/shuttle_control/explore
	machine_name = "long range shuttle console"
	machine_desc = "Used to control spacecraft that are designed to move between local sectors in open space."

/obj/machinery/computer/shuttle_control/explore/Initialize()
	. = ..()
	set_extension(src, /datum/extension/eye/landing)

/obj/machinery/computer/shuttle_control/explore/is_valid_shuttle(datum/shuttle/shuttle)
	return istype(shuttle, /datum/shuttle/autodock/overmap)


/obj/machinery/computer/shuttle_control/explore/get_ui_data(datum/shuttle/autodock/overmap/shuttle)
	. = ..()
	if(istype(shuttle))
		var/total_gas = 0
		for(var/obj/structure/fuel_port/FP in shuttle.fuel_ports) //loop through fuel ports
			var/obj/item/tank/fuel_tank = locate() in FP
			if(fuel_tank)
				total_gas += fuel_tank.air_contents.total_moles

		var/fuel_span = "good"
		if(total_gas < shuttle.fuel_consumption * 2)
			fuel_span = "bad"

		. += list(
			"destination_name" = shuttle.get_destination_name(),
			"can_pick" = shuttle.moving_status == SHUTTLE_IDLE,
			"fuel_usage" = shuttle.fuel_consumption * 100,
			"remaining_fuel" = round(total_gas, 0.01) * 100,
			"fuel_span" = fuel_span
		)

/obj/machinery/computer/shuttle_control/explore/handle_topic_href(datum/shuttle/autodock/overmap/shuttle, list/href_list)
	if (!shuttle)
		crash_with("Shuttle controller tried to handle topic with no shuttle provided.")
		to_chat(usr, SPAN_DEBUG("Shuttle controller tried to handle topic with no shuttle provided. This is a bug and should be reported immediately, something's probably horribly broken."))
		return TOPIC_HANDLED
	var/mob/user
	if(ismob(usr))
		user = usr
		shuttle.operator_skill = user.get_skill_value(SKILL_PILOT)

	if((. = ..()) != null)
		return

	if(href_list["pick"])
		var/list/possible_d = shuttle.get_possible_destinations()
		var/D
		if(length(possible_d))
			D = input("Choose shuttle destination", "Shuttle Destination") as null|anything in possible_d
		else
			to_chat(usr,SPAN_WARNING("No valid landing sites in range."))
		possible_d = shuttle.get_possible_destinations()
		if(CanInteract(usr, GLOB.default_state) && (D in possible_d))
			shuttle.set_destination(possible_d[D])
		return TOPIC_REFRESH

	if(href_list["manual_landing"])
		var/datum/extension/eye/landing_eye = get_extension(src, /datum/extension/eye)
		if(!landing_eye)
			to_chat(user, SPAN_WARNING("Could not begin landing procedure!"))
			return
		if(landing_eye.current_looker && landing_eye.current_looker != user)
			to_chat(user, SPAN_WARNING("Someone is already performing a landing maneuver!"))
			return TOPIC_HANDLED
		else
			start_landing(user, shuttle)
		return TOPIC_REFRESH
		/**
		if(user.skill_check(SKILL_PILOT, shuttle.landing_skill_needed))
			if(landing_eye.current_looker && landing_eye.current_looker != user)
				to_chat(user, SPAN_WARNING("Someone is already performing a landing maneuver!"))
				return TOPIC_HANDLED
			else
		**/
//			return TOPIC_REFRESH
//		to_chat(usr, SPAN_WARNING("The manual controls look hopelessly complex to you!"))

/obj/machinery/computer/shuttle_control/explore/proc/start_landing(var/mob/user, var/datum/shuttle/autodock/overmap/shuttle)
	var/obj/overmap/visitable/ship/current_sector

	for(var/obj/overmap/visitable/possible in saved_overmap)
		if(z in possible.map_z)
			current_sector = possible
			break

	var/obj/overmap/visitable/target_sector
	if(current_sector && istype(current_sector))

		var/list/available_sectors = list()
		for(var/obj/overmap/visitable/S in range(get_turf(current_sector), shuttle.range))
			if(S.allow_free_landing(shuttle))
				available_sectors += S

		if(LAZYLEN(available_sectors))
			target_sector = input("Choose sector to land in.", "Sectors") as null|anything in available_sectors
		else
			to_chat(user, SPAN_WARNING("No valid landing sites in range!"))
			return
	else
		if(!current_sector)
			to_chat(user, SPAN_WARNING("The computer cannot locate your current location."))
			return
		else
			to_chat(user, SPAN_WARNING("You must be in open space to initiate a landing procedure."))
			return


	if(target_sector && CanInteract(user, GLOB.default_state))
		var/datum/extension/eye/landing_eye = get_extension(src, /datum/extension/eye)
		if(landing_eye)
			if(landing_eye.current_looker) // Double checking in case someone jumped ahead of us.
				to_chat(user, SPAN_WARNING("Someone is already performing a landing maneuver!"))
				return

			var/turf/eye_turf = WORLD_CENTER_TURF(target_sector.map_z[target_sector.map_z.len]) // Center of the top z-level of the target sector.
			if(landing_eye.look(user, list(shuttle_tag, target_sector))) // Placement of the eye was successful
				landing_eye.extension_eye.forceMove(eye_turf)
				return

	to_chat(user, SPAN_WARNING("You are unable to land!"))
	return

/obj/machinery/computer/shuttle_control/explore/proc/finish_landing(var/mob/user)
	var/datum/extension/eye/eye_extension = get_extension(src, /datum/extension/eye/)

	if(!eye_extension)
		return

	var/mob/observer/eye/landing/landing_eye = eye_extension.extension_eye
	var/turf/lz_turf = eye_extension.get_eye_turf()

	var/obj/overmap/visitable/sector = GLOB.known_overmap_sectors[num2text(lz_turf.z)]
	if(!sector.allow_free_landing())	// Additional safety check to ensure the sector permits landing.
		to_chat(user, SPAN_WARNING("Invalid landing zone!"))
		return
	var/datum/shuttle/autodock/overmap/shuttle = SSshuttle.shuttles[shuttle_tag]

	if(landing_eye.check_landing()) // Make sure the landmark is in a valid location.
		var/obj/shuttle_landmark/temporary/lz = new(lz_turf, landing_eye.check_secure_landing())
		if(lz.is_valid(shuttle))	// Make sure the shuttle fits.
			to_chat(user, SPAN_NOTICE("Landing zone set!"))
			shuttle.set_destination(lz)
			eye_extension.unlook()
			return
		else
			qdel(lz)
	to_chat(user, SPAN_WARNING("Invalid landing zone!"))

/obj/machinery/computer/shuttle_control/proc/end_landing()
	var/datum/extension/eye/landing_eye = get_extension(src, /datum/extension/eye/)
	if(landing_eye)
		landing_eye.unlook()

/obj/machinery/computer/shuttle_control/explore/power_change()
	. = ..()
	if(. && (stat & (MACHINE_STAT_NOPOWER)))
		var/datum/extension/eye/landing_eye = get_extension(src, /datum/extension/eye/)
		if(landing_eye)
			landing_eye.unlook()
