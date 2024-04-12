//Text helper to avoid copy-pasta
#define __PRINT_STRING_LIST_DETAIL(ID, L) "'[id]'[islist(_list)? ", ref:\ref[_list],length:[length(_list)]" : ""]"
#define __PRINT_KEY_DETAIL(KEY)           "'[KEY]'(ref:\ref[KEY])([KEY.type])"
#define __PRINT_VALUE_DETAIL(VAL)         "'[VAL]'(ref:\ref[VAL])([VAL.type])"

///Call in a catch block for critical/typically unrecoverable errors during load. Filters out the kind of exceptions we let through or not.
/datum/controller/subsystem/persistence/proc/_handle_critical_load_exception(var/exception/E, var/code_location)
	if(error_tolerance < PERSISTENCE_ERROR_TOLERANCE_ANY)
		throw E
	else
		log_warning(EXCEPTION_TEXT(E))
		log_warning("Error tolerance set to 'any', proceeding with load despite critical error in '[code_location]'!")

///Call in a catch block for recoverable or non-critical errors during load. Filters out the kind of exceptions we let through or not.
/datum/controller/subsystem/persistence/proc/_handle_recoverable_load_exception(var/exception/E, var/code_location)
	if(error_tolerance < PERSISTENCE_ERROR_TOLERANCE_RECOVERABLE)
		throw E
	else
		log_warning(EXCEPTION_TEXT(E))
		log_warning("Error tolerance set to 'critical-only', proceeding with load despite error in '[code_location]'!")


// DEPRECIATED.

// Get an object from its p_id via ref tracking. This will not always work if an object is asynchronously deserialized from others.
// This is also quite slow - if you're trying to locate many objects at once, it's best to use a single query for multiple objects.
/datum/controller/subsystem/persistence/proc/get_object_from_p_id(var/target_p_id)
//#TODO: This could be sped up by changing the db structure to use indexes and using stored procedures.
	return
	// // Check to see if the object has been deserialized from limbo and not yet added to the normal tables.
	// if(target_p_id in limbo_refs)
	// 	var/datum/existing = locate(limbo_refs[target_p_id])
	// 	if(existing && !QDELETED(existing) && existing.persistent_id == target_p_id)
	// 		return existing
	// 	limbo_refs -= target_p_id

	// // If it was in limbo_refs we shouldn't find it in the normal tables, but we'll check anyway.
	// var/new_db_connection = FALSE
	// if(!check_save_db_connection())
	// 	if(!establish_save_db_connection())
	// 		CRASH("SSPersistence: Couldn't establish DB connection during Object Lookup!")
	// 	new_db_connection = TRUE
	// var/DBQuery/world_query = dbcon_save.NewQuery("SELECT `p_id`, `ref` FROM `[SQLS_TABLE_DATUM]` WHERE `p_id` = \"[target_p_id]\";")
	// SQLS_EXECUTE_AND_REPORT_ERROR(world_query, "OBTAINING OBJECT FROM P_ID FAILED:")

	// while(world_query.NextRow())
	// 	var/list/items = world_query.GetRowData()
	// 	var/datum/existing = locate(items["ref"])
	// 	if(existing && !QDELETED(existing) && existing.persistent_id == items["p_id"])
	// 		. = existing
	// 	break

	// if(new_db_connection)
	// 	close_save_db_connection()

/datum/controller/subsystem/persistence/proc/clear_late_wrapper_queue()
	if(!length(late_wrappers))
		return
	//#TODO: Move db handling to serializer stuff.
	var/new_db_connection = FALSE
	if(!check_save_db_connection())
		if(!establish_save_db_connection())
			CRASH("SSPersistence: Couldn't establish DB connection while clearing wrapper queue!")
		new_db_connection = TRUE
	for(var/datum/wrapper/late/L as anything in late_wrappers)
		L.on_late_load()

	late_wrappers.Cut()
	if(new_db_connection)
		close_save_db_connection() //#TODO: Move db handling to serializer stuff.

///Handles setting up db connections and etc..
/datum/controller/subsystem/persistence/proc/_before_load()
	try
		//Establish connection mainly
		serializer._before_deserialize()
	catch(var/exception/e)
		_handle_critical_load_exception(e, "establishing db connection before load")

///Assign the right z-level index to the right level.
/datum/controller/subsystem/persistence/proc/_restore_zlevel_structure(var/datum/persistence/load_cache/world/head)
	for(var/datum/persistence/load_cache/z_level/cache in head.z_levels)
		var/height = text2num(cache.height)
		if(height)
			var/turf/T = locate(1,1,text2num(cache.index))
			var/obj/landmark/map_data/data = new(T, height)
			return data

	return

///Runs after deserialize on all the loaded atoms.
/datum/controller/subsystem/persistence/proc/_run_after_deserialize()
	//Run after_deserialize on all datums deserialized.
	for(var/id in serializer.reverse_map)
		var/datum/T
		try
			T = serializer.reverse_map[id]
			T.after_deserialize()
		catch(var/exception/e)
			_handle_recoverable_load_exception(e, "while running after_deserialize() on PID: '[id]'[!isnull(T)? ", '[T]'(\ref[T])([T.type])" : ""]")


///Deserialize cached top level wrapper datum/turf exclusively from the db cache.
/datum/controller/subsystem/persistence/proc/_deserialize_turfs()
	var/list/turfs_loaded = list()
	var/time_start        = REALTIMEOFDAY

	report_progress_serializer("Deserializing [LAZYLEN(serializer.resolver.things)] cached atoms...")
	sleep(5)
	for(var/TKEY in serializer.resolver.things)
		var/datum/persistence/load_cache/thing/T
		try
			T = serializer.resolver.things[TKEY]
			if(ispath(T.thing_type, /datum/wrapper_holder)) // Special handling for wrapper holders since they don't have another reference.
				serializer.DeserializeDatum(T)
				continue
			if(!T.x || !T.y || !T.z)
				if (ispath(T.thing_type, /turf))
					to_world("CRITICAL  FAIL! INVALID TURF [T.x] [T.y] [T.z] [T.p_id]")
					return
				continue // This isn't a turf or a wrapper holder. We can skip it.
			serializer.DeserializeDatum(T)
			turfs_loaded["([T.x], [T.y], [T.z])"] = TRUE
		catch(var/exception/E)
			to_world("Failed to load turf '[T]'!: [EXCEPTION_TEXT(E)]")
			to_world_log("Failed to load turf '[T]'!: [EXCEPTION_TEXT(E)]")

	in_loaded_world = LAZYLEN(turfs_loaded) > 0
	. = turfs_loaded
	report_progress_serializer("Deserialized [LAZYLEN(turfs_loaded)] turfs and their contents in [REALTIMEOFDAY2SEC(time_start)]s.")
	sleep(5)
/**
if(ambient_bitflag) //Should remove everything about current bitflag, let it be recalculated by SS later
    SSambient_lighting.clean_turf(src)

if (!mapload ||  is_outside()))
    SSambient_lighting.queued += src

**/


/// TODO
/datum/controller/subsystem/persistence/proc/_setup_default_turfs(var/list/turfs_loaded)
	var/time_start = REALTIMEOFDAY
	for(var/datum/persistence/load_cache/z_level/z_level in serializer.resolver.z_levels)

		var/change_turf = z_level.default_turf && !ispath(z_level.default_turf, /turf/space)
		if(change_turf)
			GLOB.using_map.base_turf_by_z[text2num(z_level.index)] = z_level.default_turf
		for(var/turf/T in block(locate(1, 1, z_level.new_index), locate(world.maxx, world.maxy, z_level.new_index)))
			try

				if(change_turf && !turfs_loaded["([T.x], [T.y], [T.z])"])
					T.ChangeTurf(z_level.default_turf)
			catch(var/exception/e_changeturf)
				_handle_recoverable_load_exception(e_changeturf, "changing base turf/area")

	report_progress_serializer("Applied default turfs in [REALTIMEOFDAY2SEC(time_start)]s!")
	sleep(5)

///Applies areas to both loaded and default turfs inside the regions they cover.
/datum/controller/subsystem/persistence/proc/_apply_area_chunks()
	report_progress_serializer("Applying area chunks...")
	var/time_start = REALTIMEOFDAY
	for(var/datum/persistence/load_cache/area_chunk/area_chunk in serializer.resolver.area_chunks)
		try
			var/area/new_area = global.area_dictionary["[area_chunk.area_type], [area_chunk.name]"]
			if(!new_area)
				new area_chunk.area_type(null, area_chunk.name)

			for(var/turf_chunk in area_chunk.turfs)
				var/list/coords = splittext(turf_chunk, ",")
				// Adjust to new index.
				coords[3] = serializer.z_map[coords[3]]
				var/turf/T = locate(text2num(coords[1]), text2num(coords[2]), coords[3])
				new_area.contents += T //#FIXME: Accessing contents directly is dangerous. It's better to set loc instead.
		catch(var/exception/e)
			//Keep going if we're tolerating critical exceptions
			_handle_critical_load_exception(e, "applying area for area chunk '[area_chunk?.name]'")

	report_progress_serializer("Applied area chunks completed! Took [REALTIMEOFDAY2SEC(time_start)]s.")
	sleep(5)

/area/var/a_id = ""

/datum/controller/subsystem/persistence/proc/SetupAreas(var/datum/persistence/load_cache/world/head)
	for(var/datum/persistence/load_cache/area/Ar in head.areas)
		var/area/A
		A = new Ar.area_type()
		A.SetName(Ar.name)
		A.a_id = Ar.a_id
		A.power_equip = 0
		A.power_light = 0
		A.power_environ = 0
		A.always_unpowered = 0
		A.always_unpowered = 0
		for(var/T in Ar.turfs)
			var/list/ex = splittext(T, ",")
			var/turf/turf = locate(text2num(ex[1]), text2num(ex[2]), text2num(ex[3]))
			ChangeArea(turf, A)


#undef __PRINT_STRING_LIST_DETAIL
#undef __PRINT_KEY_DETAIL
#undef __PRINT_VALUE_DETAIL
