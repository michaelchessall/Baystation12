#ifndef T_BOARD
#error T_BOARD macro is not defined but we need it!
#endif
/**
/obj/item/stock_parts/circuitboard/recycler
	name = T_BOARD("Recycler")
	build_path = /obj/machinery/recycler
	board_type = "machine"
	origin_tech = "materials=2;engineering=2"
	req_components = list(
		/obj/item/stock_parts/matter_bin = 1,
		/obj/item/stock_parts/manipulator = 1)
**/
/obj/item/stock_parts/circuitboard/telepad
	name = T_BOARD("Telepad")
	build_path = /obj/machinery/telepad_cargo
	board_type = "machine"
	origin_tech = "bluespace=1"
	req_components = list(
		/obj/item/stock_parts/matter_bin = 1,
		/obj/item/stock_parts/manipulator = 1,
		/obj/item/stock_parts/scanning_module = 1,
		/obj/item/stock_parts/capacitor = 1)
