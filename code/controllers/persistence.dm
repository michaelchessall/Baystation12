/*
	#TODO: Save system overhaul:
	* Have saving sleeps/stoplag() every bunch of turfs, so connection to clients doesn't cut so easily.
	* Unify the sql serializer stuff, so it's less redundant. (We don't need 2 different serializer objects.)
	* Don't iterate the world 3 times over for no reasons. ( "for(var/atom/thing in somearea)" )
	* Don't access area's contents, behind the scene it just accesses world contents and is massively slow.
	* Don't concatenate strings more than once!! Use a list if you must, but just adding to a string is a hundred time slower
	  than just putting strings in a list and running jointext() on them.
	* Serialize turfs in chunks, and commit after each chunks so we have a coherent set of turfs to work with.
*/

///Init priority for the persistence subsystem
#define SS_INIT_PERSISTENCE 18.5

///Comparison function for sorting the list of atoms that took the longest to save.
/proc/cmp_serialization_stats_dsc(var/datum/serialization_stat/S1, var/datum/serialization_stat/S2)
	return S2.time_spent - S1.time_spent

///Retally all area power on round start
/hook/roundstart/proc/retally_all_power()
	for(var/area/A)
		A.retally_power()
	return TRUE

/**
 * Override of the persistence subsystem for handling saving the entire world.
 */
/datum/controller/subsystem/persistence
	name       = "Persistence"
	init_order = SS_INIT_PERSISTENCE
	flags      = SS_NO_FIRE

	// *** Config ***
	///Whether or not rent will be required for created sectors.
	var/rent_enabled = FALSE
	///If set, we'll do everything we can to generate a valid save even if some things do runtime.
	var/error_tolerance = PERSISTENCE_ERROR_TOLERANCE_NONE

	// *** State ***

	///Whether or not a save exists in the DB. Value is cached when a save did exist at runtime for performance reasons.
	var/save_exists     = FALSE
	///Whether or not we're currently running a loaded save.
	var/in_loaded_world = FALSE
	///Whether we're currently loading a world save.
	var/loading_world = FALSE
	///The time when the currently loaded world save was made if any. NULL means we never loaded a save.
	var/loaded_save_time
	///Save log entry index from the database for the currently running save. Used to fill in the saving result into the db.
	var/save_log_id
	///Holds the previous entering allowed state while we're running a save.
	var/was_entering_allowed

	///Text to log into the database log for the completion/failure of the save
	var/save_complete_text = ""
	///Span class to use for displaying the completion/failure message into chat.
	var/save_complete_span_class = "danger"
	///Amount of z-levels saved
	var/nb_saved_z_levels = 0
	///Amount of atoms saved
	var/nb_saved_atoms    = 0

	//#FIXME: Not sure if keeping a separate list of those here is a very good idea?
	var/list/saved_areas      = list()
	/// Saved levels are saved entirely and optimized with get_base_turf()
	var/list/saved_levels     = list()
	/// Extensions mark themselves to be saved on world save.
	var/list/saved_extensions = list()

	//#FIXME: The idea for having a generic serializer class was that we wouldn't initiate the exact subtype in the var definition.
	//        So that you could just interchangeably use another kind of serializer that saves to json or xml or whatever instead of sql seamlessly.
	//        This implementation completely nullifies the whole point of having a serializer class currently?
	/// The serializer impl for actually saving.
	var/serializer/sql/serializer       = new()
	/// The serializer impl for one off serialization/deserialization.


	/// Some wrapped objects need special behavior post-load. This list is cleared post-atom Init.
	var/list/late_wrappers = list()

	var/list/seen_areas = list()
	var/list/seen_zlevels = list()
	var/list/seen_minds = list()
	var/highest_z = 1

/////////////////////////////////////////////////////////////////
// Accessors
/////////////////////////////////////////////////////////////////

///Prints a description of the tables on the connected database into the chat for the usr calling this proc.
/datum/controller/subsystem/persistence/proc/PrintDBStatus()
	return SQLS_Print_DB_STATUS()

///Returns true if a save already exists on the DB
/datum/controller/subsystem/persistence/proc/SaveExists()
	if(!save_exists)

		establish_save_db_connection()
		var/list/combo = serializer.GetLatestWorldid()
		if(!combo || !combo.len > 1)
			return 0

		save_exists = establish_save_db_connection() && serializer.save_exists(combo[2])
		in_loaded_world = save_exists
	return save_exists


///Timestamp of when the currently loaded save was made.
/datum/controller/subsystem/persistence/proc/LoadedSaveTimestamp()
	if(!in_loaded_world)
		return
	if(!length(loaded_save_time))
		loaded_save_time = serializer.last_loaded_save_time()
	return loaded_save_time

///Sets the level of error tolerance to use during saves/loads. Default is PERSISTENCE_ERROR_TOLERANCE_NONE.
/datum/controller/subsystem/persistence/proc/SetErrorTolerance(var/tolerance_level = PERSISTENCE_ERROR_TOLERANCE_NONE)
	if(tolerance_level < PERSISTENCE_ERROR_TOLERANCE_NONE || tolerance_level > PERSISTENCE_ERROR_TOLERANCE_ANY)
		CRASH("Invalid error tolerance value.")
	return (error_tolerance = tolerance_level)

/////////////////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////////////////

//#TODO: Don't cache those on the persistence ss. It's an extra place to look for what levels have that flag.
/datum/controller/subsystem/persistence/proc/AddSavedLevel(var/z)
	GLOB.using_map.player_levels |= z

/datum/controller/subsystem/persistence/proc/RemoveSavedLevel(var/z)
	GLOB.using_map.player_levels -= z

/datum/controller/subsystem/persistence/proc/AddSavedArea(var/area/A)
	saved_areas |= A

/datum/controller/subsystem/persistence/proc/RemoveSavedArea(var/area/A)
	saved_areas -= A

/////////////////////////////////////////////////////////////////
// Save/Load
/////////////////////////////////////////////////////////////////

/datum/controller/subsystem/persistence/proc/AcceptDeath(var/c_id, var/ckey)
	if(ckey)
		if(!serializer.VerifyCharacterOwner(c_id,ckey)) return
	return serializer.AcceptDeath(c_id)

///Causes a character to be saved.
/datum/controller/subsystem/persistence/proc/SaveCharacter(var/mob/target, var/status)
	var/exception/last_except
	var/instanceid
	if(!target || !istype(target) || !target.mind || !target.mind.unique_id)
		return 1
	try

		instanceid = _save_instance()
		var/datum/persistence/load_cache/character/head = new()
		head.target = target
		serializer.SaveCharacter(instanceid, head, status)

	catch(var/exception/e)
		throw e
		//If exceptions end up in here, then we must interrupt saving completely.
		//Exceptions should be filtered in the sub-procs depending on severity and the error tolerance threshold set.
		save_complete_span_class = "danger"
		save_complete_text       = "CHARACTER SAVE FAILED: [EXCEPTION_TEXT(e)]"
		. = FALSE

	//Throw any exception, so it's a bit more obvious to people looking at the runtime log that it actually runtimed and failed
	if(last_except)
		throw last_except
	return 1








///Causes a world save to be started.
/datum/controller/subsystem/persistence/proc/SaveWorld(var/save_initiator)
	//Make sure we log who started the save.
	if(!save_initiator && ismob(usr))
		save_initiator = usr.ckey
	seen_areas = list()

	var/start = REALTIMEOFDAY
	var/exception/last_except

	//Prevent entering
	_block_entering()

	//Saving start event
	RAISE_EVENT(/singleton/observ/world_saving_start_event, src)

	// Do preparation first
	_before_save(save_initiator)

	var/instanceid
	var/datum/persistence/load_cache/world/world_cache = new()
	try

		instanceid = _save_instance()
		for(var/obj/overmap/visitable/overmap_obj in saved_overmap)
			overmap_obj.on_saving_start(instanceid)

		//Prepare z levels structure for saving
		var/list/z_transform = _prepare_zlevels_indexing()

		//Save all individual turfs marked for saving
		_save_turfs(z_transform, instanceid)
		world_cache.highest_z = highest_z
		//Save area related stuff
		for(var/z in seen_zlevels)
			var/datum/persistence/load_cache/z_level/z_level = seen_zlevels[z]
			world_cache.z_levels |= z_level
		for(var/area in seen_areas)
			var/datum/persistence/load_cache/A = seen_areas[area]
			world_cache.areas |= A
		world_cache.all_world_factions = all_world_factions
		world_cache.all_money_accounts = all_money_accounts
		// Now save all the extensions which have marked themselves to be saved.
		// As with areas, we create a dummy wrapper holder to hold these during load etc.
//		_save_extensions(instanceid)

	catch(var/exception/e)
		throw e
		//If exceptions end up in here, then we must interrupt saving completely.
		//Exceptions should be filtered in the sub-procs depending on severity and the error tolerance threshold set.
		save_complete_span_class = "danger"
		save_complete_text       = "SAVE FAILED: [EXCEPTION_TEXT(e)]"
		. = FALSE
		last_except = e

	//Set our success text if we didn't hit any exceptions
	if(!length(save_complete_text))
		save_complete_span_class = "serializer"
		save_complete_text       = "Save complete! Took [REALTIMEOFDAY2SEC(start)]s to save world."
		. = TRUE


	_finish_save_world(instanceid, world_cache)
	//Handle post-save cleanup and such
	_after_save()

	// Launch event for anything that needs to do cleanup post save.
	RAISE_EVENT_REPEAT(/singleton/observ/world_saving_finish_event, src)
	for(var/obj/overmap/visitable/overmap_obj in saved_overmap)
		overmap_obj.on_saving_end()
	//Resume all subsystems
	_resume_subsystems()
	// Reallow people in
	_restore_entering()

	//Throw any exception, so it's a bit more obvious to people looking at the runtime log that it actually runtimed and failed
	if(last_except)
		throw last_except


///Save Character
/datum/controller/subsystem/persistence/proc/NewCharacter(var/realname, var/ckey, var/slot, var/mob/target)

	var/c_id = serializer.NewCharacter(realname,ckey,slot,target)
	var/cs_id = SaveCharacter(target, SQLS_CHAR_STATUS_FIRST)
	serializer.UpdateCharacterOriginalSave(c_id, cs_id)
	return




/datum/controller/subsystem/persistence/proc/LoadCharacter(var/c_id)
	var/instanceid
	var/datum/persistence/load_cache/character/head
	var/exception/first_except
	try
		//Establish connection and etc..
		_before_load()
		var/list/id_combo = serializer.GetLatestCharacterSave(c_id)
//		worldid = text2num(id_combo[1])
		instanceid = text2num(id_combo[2])

		serializer.resolver.load_cache(instanceid) //This is entirely unrecoverable if it throws and exception.
		head = serializer.GetHead(instanceid)
	catch(var/exception/e_load)
		//Don't return in here, we need to let the code try to run cleanup below!
		to_world_log("Load failed: [EXCEPTION_TEXT(e_load)].")
		first_except = e_load
	try
		_run_after_deserialize()
		serializer.Clear()
		serializer.resolver.clear_cache()
		serializer._after_deserialize()
	catch(var/exception/e_cleanup)
		to_world_log("Load cleanup failed: [EXCEPTION_TEXT(e_cleanup)]")
		if(!first_except)
			first_except = e_cleanup
	//Throw any exception that were allowed, so it's a bit more obvious to people looking at the runtime log that it actually runtimed and failed
	if(first_except)
		throw first_except

	if(head)
		return head.target

/datum/controller/subsystem/persistence/proc/ClearName(var/realname)
	return serializer.ClearName(realname)

///Load the last saved world.
/datum/controller/subsystem/persistence/proc/LoadWorld()
	var/time_total       = REALTIMEOFDAY
	var/exception/first_except
	loading_world  = TRUE
	SSatoms.map_loader_begin()
	world.maxy = 200
	world.maxx = 200
	var/instanceid

	try
		//Establish connection and etc..
		_before_load()
		var/list/id_combo = serializer.GetLatestWorldid()

//		worldid = text2num(id_combo[1])
		instanceid = text2num(id_combo[2])


		// We start by loading the cache. This will load everything from SQL into an object structure
		// and is much faster than live-querying for information.
		serializer.resolver.load_cache(instanceid) //This is entirely unrecoverable if it throws and exception.
		var/datum/persistence/load_cache/world/world_cache = serializer.GetHead(instanceid)
		serializer.resolver.z_levels = world_cache.z_levels
		serializer.resolver.area_chunks = world_cache.area_chunks
		if(world.maxz < world_cache.highest_z)
			while(world.maxz < world_cache.highest_z)
				INCREMENT_WORLD_Z_SIZE
		all_world_factions = world_cache.all_world_factions
		all_money_accounts = world_cache.all_money_accounts
		SetupAreas(world_cache)

		report_progress_serializer("Cached DB data in [REALTIMEOFDAY2SEC(time_total)]s.")
		sleep(5)

		//Properly restore and assign z-level structure.
		_restore_zlevel_structure(world_cache)

		//Now we're going to load the actual data from the save.
		var/list/turfs_loaded = _deserialize_turfs()

		//Make sure all turfs we didn't load have the right base type and area
		_setup_default_turfs(turfs_loaded)

		//Apply the right area to any unsaved and saved turfs within it's area.
	//	_apply_area_chunks()

		//Try to run after_deserialize on the loaded atoms
		_run_after_deserialize()


	catch(var/exception/e_load)
		//Don't return in here, we need to let the code try to run cleanup below!
		to_world("Load failed: [EXCEPTION_TEXT(e_load)].")
		first_except = e_load

	//Now attempt cleanup. This should be attempted even after an exception!!
	var/time_cleanup = REALTIMEOFDAY
	try
		serializer.Clear()
		serializer.resolver.clear_cache()
		serializer._after_deserialize()
	catch(var/exception/e_cleanup)
		to_world_log("Load cleanup failed: [EXCEPTION_TEXT(e_cleanup)]")
		if(!first_except)
			first_except = e_cleanup
	report_progress_serializer("Cache cleanup done in [REALTIMEOFDAY2SEC(time_cleanup)]s!")

	SSatoms.map_loader_stop()
	SSatoms.InitializeAtoms()
	SSmachines.makepowernets()
	SSmachines.setup_atmos_machinery(SSmachines.machinery)
	create_all_lighting_overlays()
	//Be sure to set this to false even on exceptions
	loading_world = FALSE
	report_progress_serializer("World Load completed in [REALTIMEOFDAY2SEC(time_total)] seconds.[first_except? SPAN_RED("Some errors were encountered!!") : ""]")

	//Throw any exception that were allowed, so it's a bit more obvious to people looking at the runtime log that it actually runtimed and failed
	if(first_except)
		throw first_except

/////////////////////////////////////////////////////////////////
// Base Persistence Subsystem Overrides
/////////////////////////////////////////////////////////////////
/datum/controller/subsystem/persistence/Shutdown()
	return
/datum/controller/subsystem/persistence/track_value()
	return
// /datum/controller/subsystem/persistence/is_tracking()
// 	return
/datum/controller/subsystem/persistence/forget_value()
	return
/datum/controller/subsystem/persistence/show_info(mob/user)
	to_chat(user, SPAN_INFO("Disabled with persistence modpack (how ironic)..."))
	return

//Display to any server staff the timestamp of the currently loaded save in the status panel.
/mob/Stat()
	..()
	. = (is_client_active(10 MINUTES))
	if(!.)
		return

	if(statpanel("Status"))
		if((check_rights(R_DEBUG, FALSE, client) || check_rights(R_SERVER, FALSE, client) || check_rights(R_ADMIN, FALSE, client)))
			stat("Loaded Save", (SSpersistence.in_loaded_world? "[SSpersistence.LoadedSaveTimestamp()]": "NONE"))
