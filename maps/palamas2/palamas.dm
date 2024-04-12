#if !defined(using_map_DATUM)

	#include "../../packs/deepmaint/_pack.dm"
	#include "../../packs/event_2022jul30/_pack.dm"

	#include "../../packs/factions/commonwealth/_pack.dm"
	#include "../../packs/factions/fa/_pack.dm"
	#include "../../packs/factions/iccgn/_pack.dm"
	#include "../../packs/factions/scga/_pack.dm"
	#include "../../packs/factions/scgec/_pack.dm"

	#include "palamas_lobby.dm"
	#include "palamas_overmap.dm"

	#include "palamas_simplemobs.dm"


	#include "items/coins.dm"
	#include "items/selection.dm"
	#include "items/items.dm"
	#include "items/manuals.dm"
	#include "items/stamps.dm"
	#include "items/rigs.dm"
	#include "items/solbanner.dm"
	#include "items/explo_shotgun.dm"
	#include "items/mecha.dm"
	#include "items/memos.dm"

	#include "items/clothing/ec_skillbadges.dm"
	#include "items/clothing/solgov-accessory.dm"
	#include "items/clothing/solgov-armor.dm"
	#include "items/clothing/solgov-feet.dm"
	#include "items/clothing/solgov-hands.dm"
	#include "items/clothing/solgov-head.dm"
	#include "items/clothing/solgov-suit.dm"
	#include "items/clothing/solgov-under.dm"

	#include "items/wallets.dm"
	#include "items/weapons.dm"

	#include "language/human/euro.dm"
	#include "language/human/misc/spacer.dm"


	#include "structures/memorabilia.dm"
	#include "structures/posters.dm"
	#include "structures/signs.dm"


	#include "overmap.dmm"


	#define using_map_DATUM /datum/map/palamas

#elif !defined(MAP_OVERRIDE)

	#warn A map has already been included, ignoring Palamas

#endif
