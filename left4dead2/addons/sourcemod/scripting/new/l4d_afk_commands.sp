#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "L4D2 AFK Commands",
	author = "MasterMe, fdxx",
	description = "Adds commands to let the player spectate and join team. (!join, !afk, !zs, etc.)",
	version = "2.0",
	url = "http://forums.alliedmods.net/showthread.php?t=122476"
}

public OnPluginStart()
{
	AddCommandListener(BlockIdle, "go_away_from_keyboard");
	
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

// Block "go_away_from_keyboard" command.
public Action:BlockIdle(client, const String:command[], argc)
{
	PrintHintText(client, "闲置请用 !away 命令");
}

// To spectate
public Action:AFKTurnClientToSpectate(int client, int args)
{
	CreateTimer(3.0, Timer_CheckAway, client);
	PrintHintText(client, "3秒后进入闲置状态");
}

public Action:Timer_CheckAway(Handle:Timer, any:client)
{
	ChangeClientTeam(client, 1);
}

// To survivors. 
// Taken from https://forums.alliedmods.net/showpost.php?p=2686704&postcount=1365
public Action AFKTurnClientToSurvivors(int client, int args)
{
	SwitchToSurvivors(client);
}

bool PlayerIsAlive(int client)
{
	if (!GetEntProp(client,Prop_Send, "m_lifeState"))
		return true;
	return false;
}

int FindBotToTakeOver()
{
	// First we find a survivor bot
	for (int i = 1; i <= MaxClients;i++)
	{
		// We check if player is in game
		if (!IsClientInGame(i)) continue;
		// Check if client is survivor ...
		if (GetClientTeam(i) == 2)
		{
			// If player is a bot and is alive...
			if (IsFakeClient(i) && PlayerIsAlive(i))
			{
				return i;
			}
		}
	}
	return 0;
}

stock void SwitchToSurvivors(int client)
{
	if (!IsClientInGame(client)) return;
	if (GetClientTeam(client) == 2) return;
	if (IsFakeClient(client)) return;
	
	int bot = FindBotToTakeOver();
	if (bot == 0)
	{
		PrintHintText(client, "No survivor bots to take over.");
		return;
	}
	
	static Handle hSpec;
	if (hSpec == null)
	{
		Handle hGameConf;
		hGameConf = LoadGameConfigFile("l4d_afk_commands");
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "SetHumanSpec");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		hSpec = EndPrepSDKCall();
	}
	
	static Handle hSwitch;
	if (hSwitch == null)
	{
		Handle hGameConf;
		hGameConf = LoadGameConfigFile("l4d_afk_commands");
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "TakeOverBot");
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		hSwitch = EndPrepSDKCall();
	}
	
	SDKCall(hSpec, bot, client);
	SDKCall(hSwitch, client, true);
	return;
}

// suicide
public Action:KillSelf(int client, int args)
{
	if (client && GetClientTeam(client) == 2 && !IsFakeClient(client) && IsPlayerAlive(client))
	{
		ForcePlayerSuicide(client);
	}
}