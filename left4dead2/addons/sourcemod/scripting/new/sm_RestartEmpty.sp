#define PLUGIN_VERSION "1.9"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_NOTIFY

char g_sLogPath[PLATFORM_MAX_PATH];

public Plugin myinfo = 
{
	name = "Restart Empty", 
	author = "Alex Dragokas", 
	description = "Restart server when all players leave the game",
	version = PLUGIN_VERSION, 
	url = "https://github.com/dragokas/"
};

/*
	ChangeLog
	1.0
	 - Initial release
	 
	1.1
	 - Added log file
	 
	1.2
	 - Removing crash logs caused by server restart for some reason
	 
	1.3
	 - Added sv_hibernate_when_empty to force server not hibernate allowing this plugin to make its work
	 - Added alternative method for restarting ("crash" command) (thanks to Luckylock)
	 - Added ConVars
	 - Crash logs remover: parser method is replaced by time based method.
	 - Create "CRASH" folder
	 
	1.4
	 - Fixed "Client index 0 is invalid" in IsFakeClient() check.
	 
	1.5
	 - Added change map method. New ConVar "sm_restart_empty_default_map" - Map name to change to when server become empty
	 
	1.6
	 - Added all plugins unload before restarting the server (for safe).
	 
	1.7
	 - Added ConVar: "sm_restart_empty_unload_ext_num". If you have Accelerator extension,
	 you need specify here order number of this extension in the list by executing "sm exts list" command, to prevent creating false crash log.
	 Plugin will automatically unload this extension before restarting the server.
	 - Log path location is changed to logs/restart.log
	 - no more auto-create "CRASH" folder (since it was a speficic of myarena.ru hosting only)
	 - All ConVars are cached.
	 - Some simplifications.
	 
	1.8
	 - Default grace time ConVar is decreased down to 1 sec. to prevent misunderstanding of this feature by server administrators.
	 - Corrected identification of crash log from MyArena.ru server to clear it after server restart.
	 
	1.9
	 - Fixed warnings
*/

ConVar g_ConVarEnable;
ConVar g_ConVarMethod;
ConVar g_ConVarDelay;
ConVar g_ConVarHibernate;
ConVar g_ConVarDefMap;
ConVar g_ConVarUnloadExtNum;

bool g_bCvarEnabled;
int g_iCvarMethod;
int g_iCvarUnloadExtNum;
float g_fCvarDelay;
char g_sCvarDefMap[64];

Handle hPluginMe;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	hPluginMe = myself;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_restart_empty_version", PLUGIN_VERSION, "Plugin Version", CVAR_FLAGS | FCVAR_DONTRECORD);
	g_ConVarEnable = CreateConVar("sm_restart_empty_enable", "1", "Enable plugin (1 - On / 0 - Off)", CVAR_FLAGS);
	g_ConVarMethod = CreateConVar("sm_restart_empty_method", "2", "1 - _restart method, 2 - crash method (use if method # 1 is not work), 3 - change map", CVAR_FLAGS);
	g_ConVarDelay = CreateConVar("sm_restart_empty_delay", "1.0", "Grace period (in sec.) waiting for new player to join until beginning restart the server", CVAR_FLAGS);
	g_ConVarDefMap = CreateConVar("sm_restart_empty_default_map", "", "Map name to change to when server become empty", CVAR_FLAGS);
	g_ConVarUnloadExtNum = CreateConVar("sm_restart_empty_unload_ext_num", "0", "If you have Accelerator extension, you need specify here order number of this extension in the list: sm exts list", CVAR_FLAGS);
	
	AutoExecConfig(true, "sm_restart_empty");
	
	g_ConVarHibernate = FindConVar("sv_hibernate_when_empty");
	
	BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs/restart.log");
	
	RemoveCrashLog(); // if "CRASH" folder exists, removes last crash that happen due to server restart
	
	GetCvars();
	
	g_ConVarEnable.AddChangeHook(OnCvarChanged);
	g_ConVarMethod.AddChangeHook(OnCvarChanged);
	g_ConVarDelay.AddChangeHook(OnCvarChanged);
	g_ConVarDefMap.AddChangeHook(OnCvarChanged);
	g_ConVarUnloadExtNum.AddChangeHook(OnCvarChanged);
}

public void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bCvarEnabled = g_ConVarEnable.BoolValue;
	g_iCvarMethod = g_ConVarMethod.IntValue;
	g_fCvarDelay = g_ConVarDelay.FloatValue;
	g_ConVarDefMap.GetString(g_sCvarDefMap, sizeof g_sCvarDefMap);
	g_iCvarUnloadExtNum = g_ConVarUnloadExtNum.IntValue;
	
	InitHook();
}

void InitHook()
{
	static bool bHooked;
	
	if( g_bCvarEnabled )
	{
		if( !bHooked )
		{
			HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);	
			bHooked = true;
		}
	} else {
		if( bHooked )
		{
			UnhookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);	
			bHooked = false;
		}
	}
}

public void OnAutoConfigsBuffered()
{
	g_ConVarHibernate.SetInt(0);
}

public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if( (client == 0 || !IsFakeClient(client)) && !RealPlayerExist(client) )
	{
		g_ConVarHibernate.SetInt(0);
		CreateTimer(g_fCvarDelay, Timer_CheckPlayers);
	}
	return Plugin_Continue;
}

public Action Timer_CheckPlayers(Handle timer, int UserId)
{
	if( !RealPlayerExist() )
	{
		UnloadAccelerator();
		UnloadPluginsExcludeMe();
		
		switch(g_iCvarMethod)
		{
			case 1: {
				LogToFileEx(g_sLogPath, "Sending '_restart'... Reason: no players.");
				ServerCommand("_restart");
			}
			case 2: {
				LogToFileEx(g_sLogPath, "Sending 'crash'... Reason: no players.");
				SetCommandFlags("crash", GetCommandFlags("crash") &~ FCVAR_CHEAT);
				ServerCommand("crash");
			}
			case 3: {
				if( g_sCvarDefMap[0] )
				{
					if( IsMapValid(g_sCvarDefMap) )
					{
						LogToFileEx(g_sLogPath, "Changing to default map: %s... Reason: no players.", g_sCvarDefMap);
						ForceChangeLevel(g_sCvarDefMap, "no players");
					}
					else {
						LogToFileEx(g_sLogPath, "ERROR. Can't change map to: %s. This map is invalid or not exist.", g_sCvarDefMap);
					}
				}
				else {
					LogToFileEx(g_sLogPath, "ERROR. Can't change map: sm_restart_empty_default_map ConVar is empty!");
				}
				CreateTimer(15.0, Timer_DoHybernate);
			}
		}
		
		/* P.S. Other commands seen:
			- "quit"
			- "exit"
		*/
	}
}

void UnloadPluginsExcludeMe()
{
	Handle iter = GetPluginIterator();
	Handle pl;
	char buffer[64];
	
	while( MorePlugins(iter) )
	{
		pl = ReadPlugin(iter);
		
		if( pl != hPluginMe )
		{
			GetPluginFilename(pl, buffer, sizeof(buffer));
			ServerCommand("sm plugins unload \"%s\"", buffer);
			ServerExecute();
		}
	}
	CloseHandle(iter);
}

void UnloadAccelerator()
{
	if( g_iCvarUnloadExtNum )
	{
		ServerCommand("sm exts unload %i 0", g_iCvarUnloadExtNum);
		ServerExecute();
	}
}

public Action Timer_DoHybernate(Handle timer)
{
	if ( !RealPlayerExist() )
	{
		g_ConVarHibernate.SetInt(1);
	}
}

bool RealPlayerExist(int iExclude = 0)
{
	for( int client = 1; client < MaxClients; client++ )
	{
		if( client != iExclude && IsClientConnected(client) )
		{
			if( !IsFakeClient(client) )
			{
				return true;
			}
		}
	}
	return false;
}

void RemoveCrashLog()
{
	if( !FileExists(g_sLogPath) )
	{
		return;
	}

	char sFile[PLATFORM_MAX_PATH];
	int ft, ftReport = GetFileTime(g_sLogPath, FileTime_LastChange);
	
	if( DirExists("CRASH") )
	{
		DirectoryListing hDir = OpenDirectory("CRASH");
		if( hDir != null )
		{
			while( hDir.GetNext(sFile, sizeof(sFile)) )
			{
				TrimString(sFile);
				if( StrContains(sFile, "crash-") != -1 )
				{
					Format(sFile, sizeof(sFile), "CRASH/%s", sFile);
					ft = GetFileTime(sFile, FileTime_Created);
					
					if( 0 <= ft - ftReport < 10 ) // fresh crash?
					{
						DeleteFile(sFile);
					}
				}
			}
			delete hDir;
		}
	}
}