
#define PLUGIN_VERSION    "1.2"
#define PLUGIN_NAME       "[L4D2] AFK, Join and kill Commands"

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "MasterMe",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=122476"
};


public OnPluginStart()
{
	CreateConVar("l4d2_afk_commands_version", PLUGIN_VERSION, "Lasersight plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegConsoleCmd("go_away_from_keyboard", BlockIdle);
	RegConsoleCmd("sm_afk", AFKTurnClientToSpectate);
	RegConsoleCmd("sm_away", AFKTurnClientToSpectate);
	RegConsoleCmd("sm_idle", AFKTurnClientToSpectate);
	RegConsoleCmd("sm_spectate", AFKTurnClientToSpectate);
	RegConsoleCmd("sm_spectators", AFKTurnClientToSpectate);
	RegConsoleCmd("sm_joinspectators", AFKTurnClientToSpectate);
	RegConsoleCmd("sm_jointeam1", AFKTurnClientToSpectate);
	RegConsoleCmd("sm_survivors", AFKTurnClientToSurvivors);
	RegConsoleCmd("sm_join", AFKTurnClientToSurvivors);
	RegConsoleCmd("sm_jg", AFKTurnClientToSurvivors);
	RegConsoleCmd("sm_jiaru", AFKTurnClientToSurvivors);
	RegConsoleCmd("sm_jointeam2", AFKTurnClientToSurvivors);
	RegConsoleCmd("sm_kill", KillSelf);
	RegConsoleCmd("sm_zs", KillSelf);

}

public Action:BlockIdle(client, args)
{

	PrintHintText(client, "闲置请用 !away 命令");
	return Plugin_Handled;
}

public Action:AFKTurnClientToSpectate(client, args)
{

	CreateTimer(3.0, Timer_CheckAway, client, 2);
	PrintHintText(client, "3秒后进入闲置状态");

}

public Action:Timer_CheckAway(Handle:Timer, any:client)
{
	ChangeClientTeam(client, 1);
	return Plugin_Handled;
}

public Action:AFKTurnClientToSurvivors(client, args)
{ 
	ClientCommand(client, "jointeam 2");
	return Plugin_Handled;
}

public Action:KillSelf(client, args)
{
	ForcePlayerSuicide(client);
	return Plugin_Handled;
}