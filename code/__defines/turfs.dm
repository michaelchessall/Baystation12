#define TURF_REMOVE_CROWBAR FLAG(0)
#define TURF_REMOVE_SCREWDRIVER FLAG(1)
#define TURF_REMOVE_SHOVEL FLAG(2)
#define TURF_REMOVE_WRENCH FLAG(3)
#define TURF_CAN_BREAK FLAG(4)
#define TURF_CAN_BURN FLAG(5)
#define TURF_HAS_EDGES FLAG(6)
#define TURF_HAS_CORNERS FLAG(7)
#define TURF_HAS_INNER_CORNERS FLAG(8)
#define TURF_IS_FRAGILE FLAG(9)
#define TURF_ACID_IMMUNE FLAG(10)
#define TURF_IS_WET FLAG(11)
#define TURF_HAS_RANDOM_BORDER FLAG(12)
#define TURF_DISALLOW_BLOB FLAG(13)

//Used for floor/wall smoothing
#define SMOOTH_NONE 0	//Smooth only with itself
#define SMOOTH_ALL 1	//Smooth with all of type
#define SMOOTH_WHITELIST 2	//Smooth with a whitelist of subtypes
#define SMOOTH_BLACKLIST 3 //Smooth with all but a blacklist of subtypes

#define RANGE_TURFS(CENTER, RADIUS) block(locate(max(CENTER.x-(RADIUS), 1), max(CENTER.y-(RADIUS),1), CENTER.z), locate(min(CENTER.x+(RADIUS), world.maxx), min(CENTER.y+(RADIUS), world.maxy), CENTER.z))

//Here are a few macros to help with people always forgetting to round the coordinates somewhere, and forgetting that not everything automatically rounds decimals.
///Helper macro for the x coordinate of the turf at the center of the world. Handles rounding.
#define WORLD_CENTER_X CEILING((1 + world.maxx) / 2)
///Helper macro for the y coordinate of the turf at the center of the world. Handles rounding.
#define WORLD_CENTER_Y CEILING((1 + world.maxy) / 2)
///Helper macro for getting the center turf on a given z-level. Handles rounding.
#define WORLD_CENTER_TURF(Z) locate(WORLD_CENTER_X, WORLD_CENTER_Y, Z)
///Helper macro to check if a position is within the world's bounds.
#define IS_WITHIN_WORLD(X, Y) ((X > 0) && (Y > 0) && (X <= world.maxx) && (Y <= world.maxy))
///Helper macro for printing to text the world's x,y,z size to a string.
#define WORLD_SIZE_TO_STRING "[world.maxx]x[world.maxy]x[world.maxz]"
