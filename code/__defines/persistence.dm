#define TOPIC_UPDATE_PREVIEW 4
#define TOPIC_HARD_REFRESH   8 // use to force a browse() call, unblocking some rsc operations
#define TOPIC_REFRESH_UPDATE_PREVIEW (TOPIC_HARD_REFRESH|TOPIC_UPDATE_PREVIEW)