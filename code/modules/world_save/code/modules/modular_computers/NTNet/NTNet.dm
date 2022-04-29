
// This is the NTNet datum. There can be only one NTNet datum in game at once. Modular computers read data from this.
/datum/ntnet/
	var/datum/world_faction/holder
	var/net_uid = "" // the thing the cards connect to, this is DANGEROUS TO CHANGE, BREAKING ALL CONNECTED MACHINES, also their can only be ONE NETWORK OF EACH TYPE
	var/invisible = 0
	var/secured = 0
	var/password = "password"
	var/name = ""