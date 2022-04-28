#include "lost_supply_base_areas.dm"
#include "../mining/mining_areas.dm"

/obj/effect/overmap/visitable/sector/lost_supply_base
	name = "supply station"
	desc = "This looks like abandoned and heavy damaged supply station."
	icon_state = "object"
	known = FALSE

	initial_generic_waypoints = list(
		"nav_lost_supply_base_1",
		"nav_lost_supply_base_2",
		"nav_lost_supply_base_3",
		"nav_lost_supply_base_antag"
	)

/datum/map_template/ruin/away_site/lost_supply_base
	name = "Lost Supply Base"
	id = "awaysite_lost_supply_base"
	description = "An abandoned supply base."
	suffixes = list("lost_supply_base/lost_supply_base.dmm")
	spawn_cost = 1
	generate_mining_by_z = 1
	area_usage_test_exempted_root_areas = list(/area/lost_supply_base)
	apc_test_exempt_areas = list(
		/area/lost_supply_base/solar = NO_SCRUBBER|NO_VENT
	)

/obj/effect/shuttle_landmark/nav_lost_supply_base/nav1
	name = "Abandoned Supply Base Navpoint #1"
	landmark_tag = "nav_lost_supply_base_1"

/obj/effect/shuttle_landmark/nav_lost_supply_base/nav2
	name = "Abandoned Supply Base Navpoint #2"
	landmark_tag = "nav_lost_supply_base_2"

/obj/effect/shuttle_landmark/nav_lost_supply_base/nav3
	name = "Abandoned Supply Base Navpoint #3"
	landmark_tag = "nav_lost_supply_base_3"

/obj/effect/shuttle_landmark/nav_lost_supply_base/navantag
	name = "Abandoned Supply Base Navpoint #4"
	landmark_tag = "nav_lost_supply_base_antag"