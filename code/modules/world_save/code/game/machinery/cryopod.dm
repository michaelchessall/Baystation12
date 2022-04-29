GLOBAL_LIST_EMPTY(cryopods)
#define allowedOccupants list(/mob/living/carbon/human, /mob/living/silicon/robot, /obj/item/organ/internal/stack)



/obj/machinery/computer/cryopod
	name = "cryogenic oversight console"
	desc = "An interface between crew and the cryogenic storage oversight systems."
	icon = 'icons/obj/Cryogenic2.dmi'
	icon_state = "cellconsole"
	density = 0
	interact_offline = 1
	var/mode = null

	//Used for logging people entering cryosleep and important items they are carrying.
	var/list/frozen_crew = list()
	var/list/frozen_items = list()
	var/list/_admin_logs = list() // _ so it shows first in VV

	var/storage_type = "crewmembers"
	var/storage_name = "Cryogenic Oversight Control"
	var/allow_items = 1

/obj/machinery/computer/cryopod/robot
	name = "robotic storage console"
	desc = "An interface between crew and the robotic storage systems."
	icon = 'icons/obj/robot_storage.dmi'
	icon_state = "console"

	storage_type = "cyborgs"
	storage_name = "Robotic Storage Control"
	allow_items = 0


/obj/item/stock_parts/circuitboard/cryopodcontrol
	name = "Circuit board (Cryogenic Oversight Console)"
	build_path = /obj/machinery/computer/cryopod
	origin_tech = list(TECH_DATA = 3)

/obj/item/stock_parts/circuitboard/robotstoragecontrol
	name = "Circuit board (Robotic Storage Console)"
	build_path = /obj/machinery/computer/cryopod/robot
	origin_tech = list(TECH_DATA = 3)

/obj/machinery/cryopod
	name = "cryogenic freezer"
	desc = "A man-sized pod for entering suspended animation."
	icon = 'icons/obj/Cryogenic2.dmi'
	icon_state = "body_scanner_0"
	density = 1
	anchored = 1
	dir = WEST

	var/base_icon_state = "body_scanner_0"
	var/occupied_icon_state = "body_scanner_1"
	var/on_store_message = "has entered long-term storage."
	var/on_store_visible_message = "hums and hisses as it moves $occupant$ into storage." // $occupant$ is automatically converted to the occupant's name
	var/on_store_name = "Cryogenic Oversight"
	var/on_enter_occupant_message = "You feel cool air surround you. You go numb as your senses turn inward."
	var/allow_occupant_types = list(/mob/living/carbon/human)
	var/disallow_occupant_types = list()
	var/network = "default"
	var/mob/occupant = null       // Person waiting to be despawned.
	var/time_till_despawn = 9000  // Down to 15 minutes //30 minutes-ish is too long
	var/time_entered = 0          // Used to keep track of the safe period.
	var/obj/item/device/radio/intercom/announce //
	var/announce_despawn = TRUE

	var/obj/machinery/computer/cryopod/control_computer
	var/last_no_computer_message = 0
	var/applies_stasis = 1
	var/timeEntered = 0
	// These items are preserved when the process() despawn proc occurs.
	var/list/preserve_items = list(
		/obj/item/integrated_circuit/manipulation/bluespace_rift,
		/obj/item/integrated_circuit/input/teleporter_locator,
		/obj/item/card/id/captains_spare,
		/obj/item/aicard,
		/obj/item/device/mmi,
		/obj/item/device/paicard,
		/obj/item/gun,
		/obj/item/pinpointer,
		/obj/item/clothing/suit,
		/obj/item/clothing/shoes/magboots,
		/obj/item/blueprints,
		/obj/item/clothing/head/helmet/space,
		/obj/item/storage/internal
	)

/obj/machinery/cryopod/robot
	name = "robotic storage unit"
	desc = "A storage unit for robots."
	icon = 'icons/obj/robot_storage.dmi'
	icon_state = "pod_0"
	base_icon_state = "pod_0"
	occupied_icon_state = "pod_1"
	on_store_message = "has entered robotic storage."
	on_store_name = "Robotic Storage Oversight"
	on_enter_occupant_message = "The storage unit broadcasts a sleep signal to you. Your systems start to shut down, and you enter low-power mode."
	allow_occupant_types = list(/mob/living/silicon/robot)
	disallow_occupant_types = list(/mob/living/silicon/robot/drone)
	applies_stasis = 0

/obj/machinery/cryopod/lifepod
	name = "life pod"
	desc = "A man-sized pod for entering suspended animation. Dubbed 'cryocoffin' by more cynical spacers, it is pretty barebone, counting on stasis system to keep the victim alive rather than packing extended supply of food or air. Can be ordered with symbols of common religious denominations to be used in space funerals too."
	on_store_name = "Life Pod Oversight"
	time_till_despawn = 20 MINUTES
	icon_state = "redpod0"
	base_icon_state = "redpod0"
	occupied_icon_state = "redpod1"
	var/launched = 0
	var/datum/gas_mixture/airtank

/obj/machinery/cryopod/lifepod/Initialize()
	. = ..()
	airtank = new()
	airtank.temperature = T0C
	airtank.adjust_gas(GAS_OXYGEN, MOLES_O2STANDARD, 0)
	airtank.adjust_gas(GAS_NITROGEN, MOLES_N2STANDARD)

/obj/machinery/cryopod/lifepod/return_air()
	return airtank

/obj/machinery/cryopod/lifepod/proc/launch()
	launched = 1
	for(var/d in GLOB.cardinal)
		var/turf/T = get_step(src,d)
		var/obj/machinery/door/blast/B = locate() in T
		if(B && B.density)
			B.force_open()
			break

	var/list/possible_locations = list()
	if(GLOB.using_map.use_overmap)
		var/obj/effect/overmap/visitable/O = map_sectors["[z]"]
		for(var/obj/effect/overmap/visitable/OO in range(O,2))
			if(OO.in_space || istype(OO,/obj/effect/overmap/visitable/sector/exoplanet))
				possible_locations |= text2num(level)

	var/newz = GLOB.using_map.get_empty_zlevel()
	if(possible_locations.len && prob(10))
		newz = pick(possible_locations)
	var/turf/nloc = locate(rand(TRANSITIONEDGE, world.maxx-TRANSITIONEDGE), rand(TRANSITIONEDGE, world.maxy-TRANSITIONEDGE),newz)
	if(!istype(nloc, /turf/space))
		explosion(nloc, 1, 2, 3)
	playsound(loc,'sound/effects/rocket.ogg',100)
	forceMove(nloc)

//Don't use these for in-round leaving
/obj/machinery/cryopod/lifepod/Process()
	if(evacuation_controller && evacuation_controller.state >= EVAC_LAUNCHING)
		if(occupant && !launched)
			launch()
		..()


/obj/machinery/cryopod/New()
	..()
	GLOB.cryopods |= src
	component_parts = list()
//	component_parts += new /obj/item/stock_parts/circuitboard/cryopod(src)
	component_parts += new /obj/item/stock_parts/matter_bin(src)
	component_parts += new /obj/item/stock_parts/scanning_module(src)
	component_parts += new /obj/item/stock_parts/console_screen(src)
	RefreshParts()
	announce = new /obj/item/device/radio/intercom(src)
	..()

/obj/machinery/cryopod/Destroy()
	if(occupant)
		occupant.forceMove(loc)
	. = ..()

/obj/machinery/cryopod/before_save()
	if(occupant)
		despawnOccupant()
	..()

/obj/machinery/cryopod/Initialize()
	. = ..()
	find_control_computer()


/obj/machinery/cryopod/proc/find_control_computer(urgent=0)
	// Workaround for http://www.byond.com/forum/?post=2007448
	for(var/obj/machinery/computer/cryopod/C in src.loc.loc)
		control_computer = C
		break
	// control_computer = locate(/obj/machinery/computer/cryopod) in src.loc.loc

	// Don't send messages unless we *need* the computer, and less than five minutes have passed since last time we messaged
	if(!control_computer && urgent && last_no_computer_message + 5*60*10 < world.time)
		log_and_message_admins("Cryopod in [src.loc.loc] could not find control computer!")
		last_no_computer_message = world.time

	return control_computer != null

/obj/machinery/cryopod/proc/check_occupant_allowed(mob/M)
	var/correct_type = 0
	for(var/type in allow_occupant_types)
		if(istype(M, type))
			correct_type = 1
			break

	if(!correct_type) return 0

	for(var/type in disallow_occupant_types)
		if(istype(M, type))
			return 0

	return 1

/obj/machinery/cryopod/examine(mob/user)
	. = ..()
	if (occupant && user.Adjacent(src))
		occupant.examine(arglist(args))


/obj/machinery/cryopod/attackby(var/obj/item/O, var/mob/user = usr)
	src.add_fingerprint(user)

	if(!req_access_faction)
		to_chat(user, "<span class='notice'>\The [src] hasn't been connected to a faction.</span>")
		return

	if(occupant)
		to_chat(user, "<span class='notice'>\The [src] is in use.</span>")
		return

	if(istype(O, /obj/item/grab))
		var/obj/item/grab/G = O
		if(checkOccupantAllowed(G.affecting))
			user.visible_message("<span class='notice'>\The [user] begins placing \the [G.affecting] into \the [src].</span>", "<span class='notice'>You start placing \the [G.affecting] into \the [src].</span>")
			if(do_after(user, 20, src))
				if(!G || !G.affecting) return
			insertOccupant(G.affecting, user)
			return

	if(istype(O, /obj/item/organ/internal/stack))
		insertOccupant(O, user)
		return

	if(InsertedContents())
		to_chat(user, "<span class='notice'>\The [src] must be emptied of all stored users first.</span>")
		return

/obj/machinery/cryopod/attack_hand(var/mob/user = usr)
	if(stat)	// If there are any status flags, it shouldn't be opperable
		return

	user.set_machine(src)
	src.add_fingerprint(user)

	var/datum/world_faction/faction = get_faction(req_access_faction)

	var/data[]
	data += "<hr><br><b>Cryopod Control</b></br>"
	data += "This cryopod is [faction ? "connected to " + faction.name : "Not Connected"]<br><hr>"
	if(faction)
		data += "It's cryopod network is set to [network]<br><br>"
		data += "<a href='?src=\ref[src];enter=1'>Enter Pod</a><br>"
		data += "<a href='?src=\ref[src];eject=1'>Eject Occupant</a><br><br>"
		data += "Those authorized can <a href='?src=\ref[src];disconnect=1'>disconnect this pod from the logistics network</a> or <a href='?src=\ref[src];connect_net=1'>connect to a different cryonetwork</a>."
	else
		data += "Those authorized can <a href='?src=\ref[src];connect=1'>connect this pod to a network</a>"

	show_browser(user, data, "window=cryopod")
	onclose(user, "cryopod")

/obj/machinery/cryopod/MouseDrop_T(var/mob/target, var/mob/user)
	if(!CanMouseDrop(target, user))
		return

	if(occupant)
		to_chat(user, "<span class='notice'>\The [src] is in use.</span>")
		return

	if(checkOccupantAllowed(target))
		user.visible_message("<span class='notice'>\The [user] begins placing \the [target] into \the [src].</span>", "<span class='notice'>You start placing \the [target] into \the [src].</span>")
		if(do_after(user, 30, src))
			insertOccupant(target, user)

/obj/machinery/cryopod/OnTopic(var/mob/user = usr, href_list)
	if(href_list["enter"])
		insertOccupant(user, user)
	if(href_list["eject"])
		ejectOccupant()
	if(href_list["connect"])
		req_access_faction = user.GetFaction()
		if(!allowed(user))
			req_access_faction = ""
	if(href_list["disconnect"])
		if(allowed(user))
			req_access_faction = ""
	if(href_list["connect_net"])
		if(allowed(user))
			var/list/choices = get_faction(req_access_faction).cryo_networks.Copy()
			choices |= "default"
			var/choice = input(usr,"Choose which cryo network [src] should use.","Choose Cryo-net",null) as null|anything in choices
			if(choice)
				network = choice

/obj/machinery/cryopod/Process()
	if(occupant)
		if(world.time - timeEntered >= 1 MINUTE)
			despawnOccupant()

/obj/machinery/cryopod/verb/EjectPod()
	set name = "Eject Pod"
	set category = "Object"
	set src in oview(1)

	if(usr.stat)
		return

	ejectOccupant()




// This function can not be undone; do not call this unless you are sure
// Also make sure there is a valid control computer
/obj/machinery/cryopod/proc/despawn_occupant()
	if (!occupant)
		log_and_message_admins("A mob was deleted while in a cryopod. This may cause errors!")
		return

	//Drop all items into the pod.
	for(var/obj/item/W in occupant)
		occupant.drop_from_inventory(W)
		W.forceMove(src)

		if(W.contents.len) //Make sure we catch anything not handled by qdel() on the items.
			for(var/obj/item/O in W.contents)
				if(istype(O,/obj/item/storage/internal)) //Stop eating pockets, you fuck!
					continue
				O.forceMove(src)

	//Delete all items not on the preservation list.
	var/list/items = src.contents.Copy()
	items -= occupant // Don't delete the occupant
	items -= announce // or the autosay radio.
	items -= component_parts

	for(var/obj/item/W in items)

		var/preserve = null
		// Snowflaaaake.
		if(istype(W, /obj/item/device/mmi))
			var/obj/item/device/mmi/brain = W
			if(brain.brainmob && brain.brainmob.client && brain.brainmob.key)
				preserve = 1
			else
				continue
		else
			for(var/T in preserve_items)
				if(istype(W,T))
					preserve = 1
					break

		if(!preserve)
			qdel(W)
		else
			if(control_computer && control_computer.allow_items)
				control_computer.frozen_items += W
				W.forceMove(null)
			else
				W.forceMove(src.loc)

	//Update any existing objectives involving this mob.
	for(var/datum/objective/O in all_objectives)
		// We don't want revs to get objectives that aren't for heads of staff. Letting
		// them win or lose based on cryo is silly so we remove the objective.
		if(O.target == occupant.mind)
			if(O.owner && O.owner.current)
				to_chat(O.owner.current, "<span class='warning'>You get the feeling your target is no longer within your reach...</span>")
			qdel(O)

	//Handle job slot/tater cleanup.
	if(occupant.mind)
		if(occupant.mind.assigned_job)
			occupant.mind.assigned_job.clear_slot()

		if(occupant.mind.objectives.len)
			occupant.mind.objectives = null
			occupant.mind.special_role = null

	// Delete them from datacore.
	var/sanitized_name = occupant.real_name
	sanitized_name = sanitize(sanitized_name)
	var/datum/computer_file/report/crew_record/R = get_crewmember_record(sanitized_name)
	if(R)
		qdel(R)

	icon_state = base_icon_state

	//TODO: Check objectives/mode, update new targets if this mob is the target, spawn new antags?


	//Make an announcement and log the person entering storage.

	// Titles should really be fetched from data records
	//  and records should not be fetched by name as there is no guarantee names are unique
	var/role_alt_title = occupant.mind ? occupant.mind.role_alt_title : "Unknown"

	if(control_computer)
		control_computer.frozen_crew += "[occupant.real_name], [role_alt_title] - [stationtime2text()]"
		control_computer._admin_logs += "[key_name(occupant)] ([role_alt_title]) at [stationtime2text()]"
	log_and_message_admins("[key_name(occupant)] ([role_alt_title]) entered cryostorage.")

	if(announce_despawn)
		announce.autosay("[occupant.real_name], [role_alt_title], [on_store_message]", "[on_store_name]")

	var/despawnmessage = replacetext(on_store_visible_message, "$occupant$", occupant.real_name)
	visible_message(SPAN_NOTICE("\The [initial(name)] " + despawnmessage), range = 3)

	//This should guarantee that ghosts don't spawn.
	occupant.ckey = null

	// Delete the mob.
	qdel(occupant)
	set_occupant(null)

//Decorative structures to go alongside cryopods.
/obj/structure/cryofeed

	name = "cryogenic feed"
	desc = "A bewildering tangle of machinery and pipes."
	icon = 'icons/obj/Cryogenic2.dmi'
	icon_state = "cryo_rear"
	anchored = 1
	dir = WEST



/obj/machinery/cryopod/proc/set_occupant(var/mob/living/carbon/occupant, var/silent)
	src.occupant = occupant
	if(!occupant)
		SetName(initial(name))
		return

	occupant.stop_pulling()
	if(occupant.client)
		if(!silent)
			to_chat(occupant, "<span class='notice'>[on_enter_occupant_message]</span>")
			to_chat(occupant, "<span class='notice'><b>If you ghost, log out or close your client now, your character will shortly be permanently removed from the round.</b></span>")
		occupant.client.perspective = EYE_PERSPECTIVE
		occupant.client.eye = src
	occupant.forceMove(src)
	time_entered = world.time

	SetName("[name] ([occupant])")
	icon_state = occupied_icon_state



/obj/machinery/cryopod/verb/EnterPod()
	set name = "Enter Pod"
	set category = "Object"
	set src in oview(1)

	if(usr.stat)
		return

	if(checkOccupantAllowed(usr))
		visible_message("[usr] starts climbing into \the [src].", 3)
		if(do_after(usr, 20, src))
			insertOccupant(usr, usr)

/obj/machinery/cryopod/proc/checkOccupantAllowed(var/atom/A)
	for(var/type in allowedOccupants)
		if(istype(A, type))
			return 1
	return 0


/obj/machinery/cryopod/proc/insertOccupant(var/atom/movable/A, var/mob/user = usr)
	if(!req_access_faction)
		to_chat(user, "<span class='notice'>\The [src] hasn't been connected to a faction.</span>")
		return 0

	if(occupant)
		to_chat(user, "<span class='notice'>\The [src] is in use.</span>")
		return 0

	if(!checkOccupantAllowed(A))
		to_chat(user, "<span class='notice'>\The [A] cannot be inserted into \the [src].</span>")
		return 0

	var/mob/M
	if(istype(A, /mob))
		M = A
		if(M.buckled)
			to_chat(user, "<span class='warning'>Unbuckle the subject before attempting to move them.</span>")
			return 0

		src.add_fingerprint(M)
		M.stop_pulling()
		to_chat(M, "<span class='notice'><b>Simply wait one full minute to be sent back to the lobby where you can switch characters.</b></span>")

	if(istype(A, /obj/item/organ/internal/stack))
		var/obj/item/organ/internal/stack/S = A
		if(!S.lacemob)
			to_chat(user, "<span class='notice'>\The [S] is inert.</span>")
			return 0
		M = S.lacemob
		user.drop_from_inventory(A)

	name = "[initial(name)] ([M.real_name])"
	icon_state = "body_scanner_1"

	occupant = A
	A.forceMove(src)
	timeEntered = world.time

	src.add_fingerprint(user)

/obj/machinery/cryopod/proc/ejectOccupant()
	name = initial(name)
	icon_state = initial(icon_state)

	if(occupant)
		occupant.forceMove(get_turf(src))
		occupant = null

/obj/machinery/cryopod/proc/despawnOccupant(var/autocryo = 0)
	if(!occupant)
		return 0

	var/mob/new_player/player = new(locate(100,100,51))
	var/mob/character
	var/key
	var/name = ""
	var/dir = 0

	if(istype(occupant, /obj/item/organ/internal/stack))
		var/obj/item/organ/internal/stack/S = occupant
		if(S.lacemob.ckey)
			S.lacemob.stored_ckey = S.lacemob.ckey
			key = S.lacemob.ckey
			player.ckey = S.lacemob.ckey
		else
			key = S.lacemob.stored_ckey
			player.ckey = S.lacemob.stored_ckey
		name = S.get_owner_name()
		character = S.lacemob
		dir = S.lacemob.save_slot
		S.lacemob.spawn_loc = req_access_faction
		S.lacemob.spawn_loc_2 = network
		S.lacemob.spawn_type = 1
		S.loc = null

	else
		var/mob/M = occupant
		if(M.ckey)
			M.stored_ckey = M.ckey
			key = M.ckey
			player.ckey = M.ckey
		else
			key = M.stored_ckey
			player.ckey = M.stored_ckey
		name = M.real_name
		character = M
		dir = M.save_slot
		if(!autocryo)
			M.spawn_loc = req_access_faction
			M.spawn_loc_2 = network
			M.spawn_type = 1
			M.loc = null

	key = copytext(key, max(findtext(key, "@"), 1))

	if(!dir)
		log_and_message_admins("Warning! [key]'s [occupant] failed to find a save_slot, and is picking one!")
		for(var/file in flist(load_path(key, "")))
			var/firstNumber = text2num(copytext(file, 1, 2))
			if(firstNumber)
				var/storedName = CharacterName(firstNumber, key)
				if(storedName == name)
					dir = firstNumber
					log_and_message_admins("[key]'s [occupant] found a savefile with it's realname [file]")
					break
		if(!dir)
			dir++
			while(fexists(load_path(key, "[dir].sav")))
				dir++


	var/savefile/F = new(load_path(key, "[dir].sav"))
	to_file(F["name"], name)
	to_file(F["mob"], character)
	if(req_access_faction == "betaquad")
		var/savefile/E = new(beta_path(key, "[dir].sav"))
		to_file(E["name"], name)
		to_file(E["mob"], character)
		to_file(E["records"], Retrieve_Record(name))
	if(req_access_faction == "exiting")
		var/savefile/E = new(beta_path(key, "[dir].sav"))
		to_file(E["name"], name)
		to_file(E["mob"], character)
		to_file(E["records"], Retrieve_Record(name))

	src.name = initial(src.name)
	icon_state = initial(icon_state)
	occupant.loc = null
	QDEL_NULL(occupant)



/obj/structure/broken_cryo
	name = "broken cryo sleeper"
	desc = "Whoever was inside isn't going to wake up now. It looks like you could pry it open with a crowbar."
	icon = 'icons/obj/Cryogenic2.dmi'
	icon_state = "broken_cryo"
	anchored = 1
	density = 1
	var/closed = 1
	var/busy = 0
	var/remains_type = /obj/item/remains/human

/obj/structure/broken_cryo/attack_hand(mob/user)
	..()
	if (closed)
		to_chat(user, "<span class='notice'>You tug at the glass but can't open it with your hands alone.</span>")
	else
		to_chat(user, "<span class='notice'>The glass is already open.</span>")

/obj/structure/broken_cryo/attackby(obj/item/W as obj, mob/user as mob)
	if (busy)
		to_chat(user, "<span class='notice'>Someone else is attempting to open this.</span>")
		return
	if (closed)
		if (isCrowbar(W))
			busy = 1
			visible_message("[user] starts to pry the glass cover off of \the [src].")
			if (!do_after(user, 50, src))
				visible_message("[user] stops trying to pry the glass off of \the [src].")
				busy = 0
				return
			closed = 0
			busy = 0
			icon_state = "broken_cryo_open"
			var/obj/dead = new remains_type(loc)
			dead.dir = src.dir//skeleton is oriented as cryo
	else
		to_chat(user, "<span class='notice'>The glass cover is already open.</span>")


#undef allowedOccupants