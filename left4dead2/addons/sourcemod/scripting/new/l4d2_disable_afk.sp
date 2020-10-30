#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_NAME "l4d2 disable afk"
#define PLUGIN_VERSION "0.1"
#define TEAM_SPECTATOR 1

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = "linux_canadajeff, Dustin",
	description = "disable go_away_from_keyboard command",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2711822"
};

ConVar g_cBlockIdle = null;

public void OnPluginStart()
{
	/**
	 * @note For the love of god, please stop using FCVAR_PLUGIN.
	 * Console.inc even explains this above the entry for the FCVAR_PLUGIN define.
	 * "No logic using this flag ever existed in a released game. It only ever appeared in the first hl2sdk."
	 */
	CreateConVar("l4d2_disable_afk_version", PLUGIN_VERSION, "Standard plugin version ConVar. Please don't change me!", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cBlockIdle = CreateConVar("command_hooker_block_idle", "1", "Block \"go_away_from_keyboard\"?", _, true, 0.0, true, 1.0);
	AddCommandListener(Command_Calback, "");
}

public void OnMapStart()
{
	/**
	 * @note Precache your models, sounds, etc. here!
	 * Not in OnConfigsExecuted! Doing so leads to issues.
	 */
}

public Action Command_Calback(int client, const char[] command, int argc)
{
	
	if(g_cBlockIdle.BoolValue)
	{
		if (StrEqual(command, "wait") || StrEqual(command, "go_away_from_keyboard"))
		{
			PrintHintText(client, "闲置请用 !away 命令",client);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
