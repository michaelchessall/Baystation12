/obj/item/stock_parts/computer/network_card
	var/connected = 0
	var/connected_to = ""
	var/password = ""
	var/datum/ntnet/connected_network
	var/locked = 0

/obj/item/stock_parts/computer/network_card/proc/get_faction()
	get_network()
	if(connected && connected_network)
		return connected_network.holder

/obj/item/stock_parts/computer/network_card/proc/get_network()
	if(connected_network && connected_network.net_uid == connected_to)
		connected = 1
		return connected_network
	else
		connected_network = null
		for(var/datum/world_faction/fact in GLOB.all_world_factions)
			if(fact.network)
				if(fact.network.net_uid == connected_to)
					if(!fact.network.secured || fact.network.password == password)
						connected_network = fact.network
						connected = 1
						return connected_network
	connected = 0

/obj/item/stock_parts/computer/network_card/after_load()
	..()
	get_network()


/obj/item/stock_parts/computer/network_card/proc/disconnect()
	connected = 0
	connected_to = ""
	password = ""
	connected_network = null
