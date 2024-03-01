
/obj/item/work_controller
	icon = 'icons/obj/workcontroller.dmi'
	icon_state = "off"
	name = "Work Status: Off Duty"
	action_button_name = "Open Character Menu"
	should_save = 0
/obj/item/work_controller/attack_self(mob/living/user)
	ui_interact(user)

/obj/item/work_controller/ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, force_open = 1)
	var/list/data = list()
	var/mob/living/M = loc
	if(!M || !istype(M) || !M.mind) return
	var/datum/mind/mind = M.mind
	if(mind.workingFaction && (!mind.workingRecord || !mind.workingRecord.curr_assignment))
		mind.workingFaction = null
	if(mind.workingFaction)
		data["working"] = 1
		data["work_status"] = "On Duty as a [mind.workingRecord.curr_assignment.name] for [mind.workingFaction.display_name]."
		data["pay"] = mind.workingRecord.curr_assignment.wage
		data["time"] = 30 - mind.workingRecord.minutesWorked
		icon_state = "on"
	else
		data["work_status"] = "Off Duty"
		icon_state = "off"
	var/realname = mind.current.real_name
	var/list/choices = GetValidAssignments(realname)
	var/list/assignments[0]
	if(istype(M, /mob/living/carbon/human))
		for(var/datum/WorldFaction/faction in choices)
			var/datum/FactionRecord/record = choices[faction]
			assignments.Add(list(list(
				"name" = "[record.curr_assignment.name] for [faction.display_name] at $[record.curr_assignment.wage]",
				"faction_ref" = "\ref[faction]",
				"record_ref" = "\ref[record]",
				"active" = (mind.workingRecord == record)
			)))
	data["assignments"] = assignments
	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "work_controller.tmpl", "[M.real_name] Menu", 500, 400)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(TRUE)


/obj/item/work_controller/OnTopic(mob/user, list/href_list, state)
	var/mob/living/M = loc
	if(!M || !istype(M) || !M.mind) return
	if (href_list["select_assignment"])
		if(!istype(M, /mob/living/carbon/human)) return
		M.mind.workingFaction = locate(href_list["select_assignment"])
		M.mind.workingRecord = locate(href_list["record_ref"])
		icon_state = "on"
		name = "Work Status: On Duty"
		M.update_action_buttons()
		return TOPIC_REFRESH
	if (href_list["disconnect"])
		M.mind.workingFaction = null
		M.mind.workingRecord = null
		icon_state = "off"
		name = "Work Status: Off Duty"
		M.update_action_buttons()
		return TOPIC_REFRESH
	if (href_list["refresh"])
		return TOPIC_REFRESH
	return TOPIC_REFRESH
