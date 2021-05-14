s
/obj/item/weapon/gun/projectile/revolver
	name = "revolver"
	desc = "The al-Maliki & Mosley Magnum Double Action is a choice revolver for when you absolutely, positively need to put a hole in the other guy. (Chambered in 15mm)"
	icon = 'icons/obj/guns/revolvers.dmi'
	icon_state = "revolver"
	item_state = "revolver"
	caliber = CALIBER_PISTOL_MAGNUM
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)
	handle_casings = CYCLE_CASINGS
	max_shells = 6
	fire_delay = 12 //Revolvers are naturally slower-firing
	ammo_type = /obj/item/ammo_casing/pistol/magnum
	var/chamber_offset = 0 //how many empty chambers in the cylinder until you hit a round
	mag_insert_sound = 'sound/weapons/guns/interaction/rev_magin.ogg'
	mag_remove_sound = 'sound/weapons/guns/interaction/rev_magout.ogg'
	accuracy = 2
	accuracy_power = 8
	one_hand_penalty = 2
	bulk = 3

/obj/item/weapon/gun/projectile/revolver/AltClick()
	if(CanPhysicallyInteract(usr))
		spin_cylinder()

/obj/item/weapon/gun/projectile/revolver/verb/spin_cylinder()
	set name = "Spin cylinder"
	set desc = "Fun when you're bored out of your skull."
	set category = "Object"

	chamber_offset = 0
	visible_message("<span class='warning'>\The [usr] spins the cylinder of \the [src]!</span>", \
	"<span class='notice'>You hear something metallic spin and click.</span>")
	playsound(src.loc, 'sound/weapons/revolver_spin.ogg', 100, 1)
	loaded = shuffle(loaded)
	if(rand(1,max_shells) > loaded.len)
		chamber_offset = rand(0,max_shells - loaded.len)

/obj/item/weapon/gun/projectile/revolver/consume_next_projectile()
	if(chamber_offset)
		chamber_offset--
		return
	return ..()

/obj/item/weapon/gun/projectile/revolver/load_ammo(var/obj/item/A, mob/user)
	chamber_offset = 0
	return ..()

/obj/item/weapon/gun/projectile/revolver/medium
	name = "revolver"
	icon_state = "medium"
	safety_icon = "medium_safety"
	caliber = CALIBER_REVOLVER
	ammo_type = /obj/item/ammo_casing/revolver
	desc = "The Lumoco Arms' Solid is a rugged revolver for people who don't keep their guns well-maintained. (Chambered in .38)"
	accuracy = 1
	bulk = 0
	fire_delay = 9

/obj/item/weapon/gun/projectile/revolver/snakister
	name = "snakister revolver"
	icon = 'icons/obj/guns/revolvers.dmi'
	icon_state = "snakeister"
	item_state = "revolver"
	caliber = CALIBER_REVOLVER_SMALL
	ammo_type = /obj/item/ammo_casing/smallrevolver
	max_shells = 4
	desc = "The shellguard B-62 (snakister) revolver is a very fine revolver for people who wants style. (Chambered in .32)"
	accuracy = 1
	bulk = 0
	fire_delay = 9

/obj/item/weapon/gun/projectile/revolver/webly
	name = "Webly revolver"
	icon_state = "webly"
	item_state = "revolver"
	caliber = CALIBER_REVOLVER_MEDIUM
	ammo_type = /obj/item/ammo_casing/mediumrevolver
	desc = "The Webly is commonly sold on the black market as one of the finest revolvers. You can kick some ass with this one. (Chambered in .44)"
	accuracy = 1
	bulk = 0
	fire_delay = 5

/obj/item/weapon/gun/projectile/revolver/blade
	name = "Blade revolver"
	icon_state = "blade"
	item_state = "blade"
	caliber = CALIBER_PISTOL_MAGNUM
	ammo_type = /obj/item/ammo_casing/pistol/magnum
	desc = "A vintage revolver. It has some rust on the barrel. (Chambered in 15mm)"
	accuracy = 1
	bulk = 0
	fire_delay = 14

/obj/item/weapon/gun/projectile/revolver/snobnose
	name = "snobnose revolver"
	icon = 'icons/obj/guns/revolvers.dmi'
	icon_state = "snobnose"
	item_state = "revolver"
	caliber = CALIBER_REVOLVER_SMALL
	ammo_type = /obj/item/ammo_casing/smallrevolver
	max_shells = 6
	desc = "The snobnose revolver. Where is the whisky and cigars at. (Chambered in .32)"
	accuracy = 1
	bulk = 0
	fire_delay = 7

/obj/item/weapon/gun/projectile/revolver/snobnosetactical
	name = "snobnose MK2 revolver"
	icon = 'icons/obj/guns/revolvers.dmi'
	icon_state = "snobnose_tactical"
	item_state = "revolver"
	caliber = CALIBER_REVOLVER_SMALL
	ammo_type = /obj/item/ammo_casing/smallrevolver
	max_shells = 6
	desc = "A snobnose revolver which seems to be heavily modified to suit the situation. (Chambered in .32)"
	accuracy = 1
	bulk = 0
	fire_delay = 7

/obj/item/weapon/gun/projectile/revolver/mateba
	name = "Mateba revolver"
	icon = 'icons/obj/guns/revolvers.dmi'
	icon_state = "mateba"
	item_state = "revolver"
	caliber = CALIBER_PISTOL_MAGNUM
	ammo_type = /obj/item/ammo_casing/pistol/magnum
	max_shells = 6
	handle_casings = EJECT_CASINGS
	desc = "The mateba is a rare revolver mostly seen by space pirates. it seems to have a auto ejecter mechanism that ejects casings. (Chambered in 15mm)"
	accuracy = 1
	bulk = 0
	fire_delay = 4

/obj/item/weapon/gun/projectile/revolver/vermint
	name = "vermint rifle"
	icon = 'icons/obj/guns/vermint.dmi'
	icon_state = "vermint"
	item_state = "dshotgun"
	caliber = CALIBER_REVOLVER_SMALL
	w_class = ITEM_SIZE_HUGE
	ammo_type = /obj/item/ammo_casing/smallrevolver
	max_shells = 12
	desc = "The vermint is commonly used on the frontier as a self defense firearm against xeno lifeforms. (Chambered in .32)"
	one_hand_penalty = 8
	accuracy = 1
	bulk = 0
	fire_delay = 16

/obj/item/weapon/gun/projectile/revolver/vermintv2
	name = "vermint-V2 rifle"
	icon = 'icons/obj/guns/vermint.dmi'
	icon_state = "vermintv2"
	item_state = "dshotgun"
	w_class = ITEM_SIZE_HUGE
	caliber = CALIBER_REVOLVER_SMALL
	ammo_type = /obj/item/ammo_casing/smallrevolver
	max_shells = 14
	desc = "The vermint V2 is a newer model used on the frontier as a self defense firearm against xeno lifeforms. This one seems to have more storage for bullets. (Chambered in .32)"
	one_hand_penalty = 8
	accuracy = 1
	bulk = 0
	fire_delay = 16

/obj/item/weapon/gun/projectile/revolver/lever
	name = "lever-action rifle"
	icon = 'icons/obj/guns/vermint.dmi'
	icon_state = "lever"
	item_state = "shotgun"
	caliber = CALIBER_RIFLE_SMALL
	w_class = ITEM_SIZE_HUGE
	ammo_type = /obj/item/ammo_casing/smallrifle
	max_shells = 7
	desc = "A fine lever action with a gold plated top and redwood parts. (Chambered in .223)"
	one_hand_penalty = 9
	accuracy = 1
	bulk = 0
	fire_delay = 13

/obj/item/weapon/gun/projectile/revolver/spring
	name = "spring rifle"
	icon = 'icons/obj/guns/vermint.dmi'
	icon_state = "spring"
	item_state = "dshotgun"
	caliber = CALIBER_REVOLVER_SMALL
	ammo_type = /obj/item/ammo_casing/smallrevolver
	max_shells = 3
	desc = "A very very old rifle seems to be from a forgotten time. (Chambered in .32)"
	accuracy = 1
	bulk = 0
	fire_delay = 40

/obj/item/weapon/gun/projectile/revolver/holdout
	name = "holdout revolver"
	desc = "The al-Maliki & Mosley Partner is a concealed-carry revolver made for people who do not trust automatic pistols any more than the people they're dealing with. (Chambered in .32)"
	icon_state = "holdout"
	item_state = "pen"
	caliber = CALIBER_REVOLVER_SMALL
	ammo_type = /obj/item/ammo_casing/smallrevolver
	w_class = ITEM_SIZE_SMALL
	accuracy = 1
	max_shells = 2
	one_hand_penalty = 0
	bulk = 0
	fire_delay = 7

/obj/item/weapon/gun/projectile/revolver/derringer
	name = "derringer revolver"
	desc = "The derringer is a iconic small revolver used by spies mostly. (Chambered in .32)"
	icon_state = "derringer"
	item_state = "pen"
	caliber = CALIBER_REVOLVER_SMALL
	ammo_type = /obj/item/ammo_casing/smallrevolver
	w_class = ITEM_SIZE_SMALL
	accuracy = 1
	max_shells = 2
	one_hand_penalty = 0
	bulk = 0
	fire_delay = 7

/obj/item/weapon/gun/projectile/revolver/derringerlux
	name = "derringer revolver"
	desc = "This derringer seems to have a fancy marble grip and made of hard steel. (Chambered in .32)"
	icon_state = "derringer"
	item_state = "pen"
	caliber = CALIBER_REVOLVER_SMALL
	ammo_type = /obj/item/ammo_casing/smallrevolver
	w_class = ITEM_SIZE_SMALL
	accuracy = 1
	max_shells = 2
	one_hand_penalty = 0
	bulk = 0
	fire_delay = 6

/obj/item/weapon/gun/projectile/revolver/capgun
	name = "cap gun"
	desc = "Looks almost like the real thing! Ages 8 and up."
	icon_state = "revolver-toy"
	caliber = CALIBER_CAPS
	origin_tech = list(TECH_COMBAT = 1, TECH_MATERIAL = 1)
	ammo_type = /obj/item/ammo_casing/cap

/obj/item/weapon/gun/projectile/revolver/capgun/attackby(obj/item/weapon/wirecutters/W, mob/user)
	if(!istype(W) || icon_state == "revolver")
		return ..()
	to_chat(user, "<span class='notice'>You snip off the toy markings off the [src].</span>")
	name = "revolver"
	icon_state = "revolver"
	desc += " Someone snipped off the barrel's toy mark. How dastardly."
	return 1
