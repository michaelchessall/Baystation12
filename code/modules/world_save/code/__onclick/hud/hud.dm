/datum/hud/proc/hands_inventory_update()
	if(!mymob)
		return

	if(ishuman(mymob))
		var/mob/living/carbon/human/H = mymob
		if(H.l_hand) H.l_hand.screen_loc = ui_lhand
		if(H.r_hand) H.r_hand.screen_loc = ui_rhand
