SUBSYSTEM_DEF(economy)
	name = "Economy Manager"
	wait = 60 SECONDS
	priority = SS_PRIORITY_EVENT


//Subsystem procs
/datum/controller/subsystem/economy/Initialize(start_uptime)


/datum/controller/subsystem/economy/fire(resumed = FALSE)
	for(var/datum/mind/mind in player_minds)
		if(mind.workingRecord && mind.workingRecord.curr_assignment && mind.current && mind.current.client)
			mind.workingRecord.minutesWorked++
			if(mind.workingRecord.minutesWorked >= 30)
				mind.workingRecord.minutesWorked = 0
				if(mind.workingRecord.curr_assignment.wage > 0)
					var/result = mind.workingFaction.PayPerson(mind.workingRecord)
					if(result)
						to_chat(mind.current, result)
					else
						to_chat(mind.current, SPAN_NOTICE("You have been paid $[mind.workingRecord.curr_assignment.wage] for working as a [mind.workingRecord.curr_assignment.name]."))
				else
					to_chat(mind.current, SPAN_NOTICE("You have been on duty for thirty minutes as a [mind.workingRecord.curr_assignment.name] but recieve no pay because your position is unpaid."))
