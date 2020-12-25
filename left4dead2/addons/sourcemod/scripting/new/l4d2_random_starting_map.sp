#include <sourcemod>
#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "L4D2 Random starting map",
	author = "fdxx",
	description = "L4D2 Random starting map",
	version = PLUGIN_VERSION,
	url = ""
}

public void OnPluginStart()
{
	CreateConVar("l4d2_random_starting_map_version", PLUGIN_VERSION, "Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	int randommap = GetRandomInt(1, 14);
	switch (randommap)
	{
		case 1: ServerCommand("sm_map c1m1_hotel");
		case 2: ServerCommand("sm_map c2m1_highway");
		case 3: ServerCommand("sm_map c3m1_plankcountry");
		case 4: ServerCommand("sm_map c4m1_milltown_a");
		case 5: ServerCommand("sm_map c5m1_waterfront");
		case 6: ServerCommand("sm_map c6m1_riverbank");
		case 7: ServerCommand("sm_map c7m1_docks");
		case 8: ServerCommand("sm_map c8m1_apartment");
		case 9: ServerCommand("sm_map c9m1_alleys");
		case 10: ServerCommand("sm_map c10m1_caves");
		case 11: ServerCommand("sm_map c11m1_greenhouse");
		case 12: ServerCommand("sm_map c12m1_hilltop");
		case 13: ServerCommand("sm_map c13m1_alpinecreek");
		case 14: ServerCommand("sm_map c14m1_junkyard");
	}
}
