/mob/living/carbon/human
	var/home_spawn		// The object we last safe-slept on. Used for moving characters to safe locations on loads. POINTS TO A UID

/mob/living/carbon/human/before_save()
	. = ..()
	CUSTOM_SV_LIST(\
	"move_intent" = ispath(move_intent)? move_intent : move_intent?.type, \
	"eye_color" = eye_color, \
	"facial_hair_color" = facial_hair_color, \
	"hair_color" = head_hair_color, \
	"skin_color" = skin_color, \
	"skin_tone" = skin_tone, \
	"h_style" = head_hair_style, \
	"f_style" = facial_hair_style, \
	)

/mob/living/carbon/human/after_deserialize()
	backpack_setup = null //Make sure we don't repawn a new backpack
	if(w_uniform)
		w_uniform.hud_layerise()
	if(shoes)
		shoes.hud_layerise()
	if(belt)
		belt.hud_layerise()
	if(gloves)
		gloves.hud_layerise()
	if(glasses)
		glasses.hud_layerise()
	if(head)
		head.hud_layerise()
	if(l_ear)
		l_ear.hud_layerise()
	if(r_ear)
		r_ear.hud_layerise()
	if(wear_id)
		wear_id.hud_layerise()
	if(r_store)
		r_store.hud_layerise()
	if(l_store)
		l_store.hud_layerise()
	if(s_store)
		s_store.hud_layerise()
	if(r_hand)
		r_hand.hud_layerise()
	if(l_hand)
		l_hand.hud_layerise()
	. = ..()
/mob/living/carbon/human/Initialize(mapload, species_name, datum/dna/new_dna, decl/bodytype/new_bodytype)
	. = ..()
	LATE_INIT_IF_SAVED

/mob/living/carbon/human/LateInitialize()
	. = ..()
	if(!persistent_id)
		return

	set_move_intent(GET_DECL(LOAD_CUSTOM_SV("move_intent")))

	//Apply saved appearance (appearance may differ from DNA)
	eye_color         = LOAD_CUSTOM_SV("eye_color")
	facial_hair_color = LOAD_CUSTOM_SV("facial_hair_color")
	head_hair_color        = LOAD_CUSTOM_SV("hair_color")
	skin_color        = LOAD_CUSTOM_SV("skin_color")
	skin_tone          = LOAD_CUSTOM_SV("skin_tone")
	head_hair_style            = LOAD_CUSTOM_SV("h_style")
	facial_hair_style            = LOAD_CUSTOM_SV("f_style")

	//Force equipped items to refresh their held icon
	for(var/obj/item/I in contents)
		I.hud_layerise()

	//Update wounds has to be run this late because it expects the mob to be fully initialized
	for(var/obj/item/organ/external/limb in organs)
		limb.update_wounds()

	CLEAR_ALL_SV //Clear saved vars


// Don't let it update icons during initialize
// Can't avoid upstream code from doing it, so just postpone it
/mob/living/carbon/human/update_icon()
	if(!(atom_flags & ATOM_FLAG_INITIALIZED))
		queue_icon_update() //Queue it later instead
		return
	. = ..()

SAVED_VAR(/mob/living/carbon/human, head_hair_style)
SAVED_VAR(/mob/living/carbon/human, facial_hair_style)
SAVED_VAR(/mob/living/carbon/human, head_hair_color)
SAVED_VAR(/mob/living/carbon/human, facial_hair_color)
SAVED_VAR(/mob/living/carbon/human, skin_color)
SAVED_VAR(/mob/living/carbon/human, eye_color)
SAVED_VAR(/mob/living/carbon/human, skin_tone)
SAVED_VAR(/mob/living/carbon/human, worn_underwear)
SAVED_VAR(/mob/living/carbon/human, cultural_info)
SAVED_VAR(/mob/living/carbon/human, voice)
SAVED_VAR(/mob/living/carbon/human, last_dam)
SAVED_VAR(/mob/living/carbon/human, remoteview_target)
SAVED_VAR(/mob/living/carbon/human, hand_blood_color)
SAVED_VAR(/mob/living/carbon/human, flavor_texts)
SAVED_VAR(/mob/living/carbon/human, pulling_punches)
SAVED_VAR(/mob/living/carbon/human, last_attack)
SAVED_VAR(/mob/living/carbon/human, flash_protection)
SAVED_VAR(/mob/living/carbon/human, equipment_tint_total)
SAVED_VAR(/mob/living/carbon/human, equipment_darkness_modifier)
SAVED_VAR(/mob/living/carbon/human, equipment_vision_flags)
SAVED_VAR(/mob/living/carbon/human, equipment_see_invis)
SAVED_VAR(/mob/living/carbon/human, equipment_prescription)
SAVED_VAR(/mob/living/carbon/human, equipment_light_protection)
SAVED_VAR(/mob/living/carbon/human, char_branch)
SAVED_VAR(/mob/living/carbon/human, char_rank)
SAVED_VAR(/mob/living/carbon/human, stance_damage)
SAVED_VAR(/mob/living/carbon/human, default_attack)
SAVED_VAR(/mob/living/carbon/human, shock_stage)
SAVED_VAR(/mob/living/carbon/human, skin_state)
SAVED_VAR(/mob/living/carbon/human, embedded_flag)
SAVED_VAR(/mob/living/carbon/human, stamina)
SAVED_VAR(/mob/living/carbon/human, vessel)
SAVED_VAR(/mob/living/carbon/human, home_spawn)
SAVED_VAR(/mob/living/carbon/human, organs)
SAVED_VAR(/mob/living/carbon/human, internal_organs)
SAVED_VAR(/mob/living/carbon/human, organs_by_name)
SAVED_VAR(/mob/living/carbon/human, internal_organs_by_name)
SAVED_VAR(/mob/living/carbon/human, wear_suit)
SAVED_VAR(/mob/living/carbon/human, w_uniform)
SAVED_VAR(/mob/living/carbon/human, shoes)
SAVED_VAR(/mob/living/carbon/human, belt)
SAVED_VAR(/mob/living/carbon/human, gloves)
SAVED_VAR(/mob/living/carbon/human, glasses)
SAVED_VAR(/mob/living/carbon/human, head)
SAVED_VAR(/mob/living/carbon/human, l_ear)
SAVED_VAR(/mob/living/carbon/human, r_ear)
SAVED_VAR(/mob/living/carbon/human, wear_id)
SAVED_VAR(/mob/living/carbon/human, r_store)
SAVED_VAR(/mob/living/carbon/human, l_store)
SAVED_VAR(/mob/living/carbon/human, s_store)
SAVED_VAR(/mob/living/carbon/human, r_hand)
SAVED_VAR(/mob/living/carbon/human, l_hand)
