//I'll just define a new "machine" instead
/obj/machinery/shuttleengine
	name = "propulsion"
	density = 1
	anchored = 1.0
	icon = 'icons/turf/shuttle.dmi'
	icon_state = "propulsion"
	opacity = 1
	CanPass(atom/movable/mover, turf/target, height, air_group)
		if(!height || air_group) return 0
		else return ..()

/obj/machinery/shuttleengine/New()
	..()
	component_parts = list()
//	component_parts += new /obj/item/stock_parts/circuitboard/shuttleengine(src)
	component_parts += new /obj/item/device/assembly/igniter(src)
	component_parts += new /obj/item/stock_parts/capacitor(src)
	component_parts += new /obj/item/stock_parts/capacitor(src)
	component_parts += new /obj/item/stock_parts/capacitor(src)
	component_parts += new /obj/item/stock_parts/capacitor(src)
	component_parts += new /obj/item/stock_parts/capacitor(src)
	component_parts += new /obj/item/stack/cable_coil(src, 30)
	component_parts += new /obj/item/stack/material/phoron(src, 5)
	RefreshParts()

/obj/machinery/shuttleengine/attackby(var/obj/O as obj, var/mob/user as mob)
	if(isWrench(O))
		if(permaanchor)
			to_chat(user, "The engine is wired in to an active shuttle and cannot be wrenched.")
			return
		anchored = !anchored
		playsound(src.loc, 'sound/items/Ratchet.ogg', 75, 1)
		if(anchored)
			user.visible_message("[user.name] secures [src.name] to the floor.", \
				"You secure the [src.name] to the floor.", \
				"You hear a ratchet")
		else
			user.visible_message("[user.name] unsecures [src.name] from the floor.", \
				"You unsecure the [src.name] from the floor.", \
				"You hear a ratchet")
		return
	if(permaanchor)
		to_chat(user, "The engine is wired in to an active shuttle and cannot be modified.")
		return

	..()

/obj/machinery/shuttleengine/AltClick()
	rotate()
/obj/machinery/shuttleengine/verb/rotateccw()
	set name = "Rotate Counter Clockwise"
	set category = "Object"
	set src in oview(1)

	if (src.anchored || usr:stat)
		to_chat(usr, "It is fastened to the floor!")
		return 0
	src.set_dir(turn(src.dir, 90))
	return 1
