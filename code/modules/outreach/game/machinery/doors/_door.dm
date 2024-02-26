
/obj/machinery/door/LateInitialize(mapload, dir=0, populate_parts=TRUE)
	// Don't populate parts if this is a saved door
	if(persistent_id)
		return ..(mapload, dir, FALSE)
	return ..()

/obj/machinery/door/update_connections(propagate)
	if(!persistent_id) //Don't let it do this when loading from save
		. = ..()