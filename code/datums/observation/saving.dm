//	Observer Pattern Implementation: World Saving
//		Registration type: /datum
//
//		Raised when: Persistence is starting the saving process for the world.
//
//		Arguments that the called proc should expect:
//		None

/singleton/observ/world_saving_start_event
	name = "World Saving Start"
	expected_type = /datum

/singleton/observ/world_saving_finish_event
	name = "World Saving Finish"
	expected_type = /datum