#ifndef T_BOARD
#error T_BOARD macro is not defined but we need it!
#endif

//Stuff that doesn't fit into any category goes here

/**
/obj/item/stock_parts/circuitboard/libraryscanner
	name = T_BOARD("book scanner")
	build_path = /obj/machinery/libraryscanner
	board_type = "machine"
	origin_tech = list(TECH_MATERIAL =1, TECH_DATA = 1)
	req_components = list(
							/obj/item/stock_parts/computer_hardware/hard_drive/portable = 1,
							/obj/item/stock_parts/scanning_module = 1,
							/obj/item/stock_parts/console_screen = 1)

/obj/item/stock_parts/circuitboard/bookbinder
	name = T_BOARD("book binder")
	build_path = /obj/machinery/bookbinder
	board_type = "machine"
	origin_tech = list(TECH_MATERIAL =1, TECH_DATA = 1)
	req_components = list(
							/obj/item/stock_parts/computer_hardware/nano_printer = 1,
							/obj/item/stock_parts/manipulator = 1)
**/
/obj/item/stock_parts/circuitboard/shuttleengine
	name = T_BOARD("shuttle engine")
	build_path = /obj/machinery/shuttleengine
	board_type = "machine"
	origin_tech = list(TECH_ENGINEERING = 4, TECH_POWER = 4)
	req_components = list(
							/obj/item/stack/cable_coil = 30,
							/obj/item/device/assembly/igniter = 1,
							/obj/item/stock_parts/capacitor = 5,
							/obj/item/stack/material/phoron = 5)

/obj/item/stock_parts/circuitboard/bridge_computer
	name = T_BOARD("bridge computer")
	build_path = /obj/machinery/computer/bridge_computer
	origin_tech = list(TECH_DATA = 4, TECH_ENGINEERING = 4)
	board_type = "computer"

/obj/item/stock_parts/circuitboard/docking_beacon
	name = T_BOARD("docking beacon")
	build_path = /obj/machinery/docking_beacon
	board_type = "machine"
	origin_tech = list(TECH_DATA = 4, TECH_ENGINEERING = 4, TECH_BLUESPACE = 4)
	req_components = list(
							/obj/item/stock_parts/manipulator = 2,
							/obj/item/stack/cable_coil = 1,
							/obj/item/stock_parts/subspace/filter = 1)

/obj/item/stock_parts/circuitboard/shuttleengine
	name = T_BOARD("shuttle engine")
	build_path = /obj/machinery/shuttleengine
	board_type = "machine"
	origin_tech = list(TECH_ENGINEERING = 4, TECH_POWER = 4)
	req_components = list(
							/obj/item/stack/cable_coil = 30,
							/obj/item/device/assembly/igniter = 1,
							/obj/item/stock_parts/capacitor = 5,
							/obj/item/stack/material/phoron = 5)
