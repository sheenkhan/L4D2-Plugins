#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION 	"1.0"
#define PLUGIN_PREFIX "\x05[提示]\x03 "

#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6

new Handle:l4d2_msg_system_zh_heal_info = INVALID_HANDLE;

new Handle: l4d2_msg_system_zh_tank_spawn;
new Handle: l4d2_msg_system_zh_tank_killed;
new Handle: l4d2_msg_system_zh_witch_spawn;
new Handle: l4d2_msg_system_zh_witch_killed;
new Handle: l4d2_msg_system_zh_witch_harasser_set;
new Handle: l4d2_msg_system_zh_player_death;
new Handle: l4d2_msg_system_zh_create_panic_event;
new Handle: l4d2_msg_system_zh_player_incapacitated;
new Handle: l4d2_msg_system_zh_player_in_out;
new Handle: l4d2_msg_system_zh_kill_in;
new Handle: l4d2_msg_system_zh_save_up;
new Handle: l4d2_msg_system_zh_use_def;

public Plugin:myinfo =
{
	name = "消息提示",
	author = "",
	description = "各种类型消息提示.",
	version = "PLUGIN_VERSION",
	url = "#"
}

public OnPluginStart()
{
	CreateConVar("l4d2_msg_system_zh_version", PLUGIN_VERSION,"l4d2_msg_system_zh Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	l4d2_msg_system_zh_heal_info = CreateConVar("l4d2_msg_system_zh_heal_info","1","显示治疗信息");
	l4d2_msg_system_zh_tank_spawn = CreateConVar("l4d2_msg_system_zh_tank_spawn", "1", "开启tank产生提示", FCVAR_PLUGIN);
	l4d2_msg_system_zh_tank_killed = CreateConVar("l4d2_msg_system_zh_tank_killed", "1", "杀死tank提示", FCVAR_PLUGIN);
	l4d2_msg_system_zh_witch_spawn = CreateConVar("l4d2_msg_system_zh_witch_spawn", "1", "开启witch产生提示", FCVAR_PLUGIN);
	l4d2_msg_system_zh_witch_killed = CreateConVar("l4d2_msg_system_zh_witch_killed", "1", "杀死witch提示", FCVAR_PLUGIN);
	l4d2_msg_system_zh_witch_harasser_set = CreateConVar("l4d2_msg_system_zh_witch_harasser_set", "1", "惊动witch提示", FCVAR_PLUGIN);
	l4d2_msg_system_zh_player_death = CreateConVar("l4d2_msg_system_zh_player_death", "1", "玩家死亡提示", FCVAR_PLUGIN);
	l4d2_msg_system_zh_create_panic_event = CreateConVar("l4d2_msg_system_zh_create_panic_event", "1", "触发警报提示", FCVAR_PLUGIN);
	l4d2_msg_system_zh_player_incapacitated = CreateConVar("l4d2_msg_system_zh_player_incapacitated", "1", "倒地提示", FCVAR_PLUGIN);
	l4d2_msg_system_zh_player_in_out = CreateConVar("l4d2_msg_system_zh_player_in_out", "1", "玩家进入退出提示", FCVAR_PLUGIN);
	l4d2_msg_system_zh_kill_in = CreateConVar("l4d2_msg_system_zh_kill_in", "1", "击杀特感提示（聊天框内）", FCVAR_PLUGIN);
	l4d2_msg_system_zh_save_up = CreateConVar("l4d2_msg_system_zh_save_up", "1", "救起玩家提示", FCVAR_PLUGIN);
	l4d2_msg_system_zh_use_def = CreateConVar("l4d2_msg_system_zh_use_def", "1", "复活玩家提示", FCVAR_PLUGIN);
	HookEvent("heal_success", HealSuccess);
	HookEvent("tank_spawn", tankSpawn);
	HookEvent("witch_spawn", witchSpawn);
	HookEvent("witch_killed", witchKilled);
	HookEvent("witch_harasser_set", witchHrasserSet);
	HookEvent("tank_killed", tankKilled);
	HookEvent("player_death", playerDeath);
	HookEvent("player_incapacitated_start", playerIncapacitated);
	HookEvent("revive_success", EventReviveSuccess);
 	HookEvent("defibrillator_used", EventDefiSuccess);
	//HookEvent("player_disconnect", Event_PlayerDisconnect);
	//HookEvent("player_connect", Event_PlayerConnect);
	HookEvent("create_panic_event", createPanicEvent);

	AutoExecConfig( true, "l4d2_msg_system_zh");
}

//治疗信息
public HealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new UserId = GetEventInt(event, "userid")
	new Subject = GetEventInt(event, "subject")
	//new HealthRestored = GetEventInt(event, "health_restored")
	new healee = GetClientOfUserId(Subject)
	new healer = GetClientOfUserId(UserId)
	new String:PName1[64]
	new String:PName2[64]
	if (GetConVarInt(l4d2_msg_system_zh_heal_info) == 1)
	{
		GetClientName(healer, PName1, sizeof(PName1))
		GetClientName(healee, PName2, sizeof(PName2))
		if (StrEqual(PName1,PName2))
		{
			PrintToChatAll("%s\x04%s \x03治疗了自己", PLUGIN_PREFIX, PName1);
		}
		else
		{
			PrintToChatAll("%s\x04%s \x03治疗了\x04 %s\x03", PLUGIN_PREFIX,PName1,PName2);
		}
	}
	return;
}

//tank产生
public Action:tankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d2_msg_system_zh_tank_spawn)==1) 
	{
		PrintHintTextToAll("tank已经重生!");
	}
	return Plugin_Continue;
}

//杀死tank
public Action:tankKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d2_msg_system_zh_tank_killed)==1) 
	{	
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
	 	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if(class == 8 && attacker != 0 && GetClientTeam(attacker) == 2) //8是tank
		{	
			PrintToChatAll("%s\x04%N \x03的致命一击结束了 \x04%N \x03的性命！", PLUGIN_PREFIX, attacker, client);
		}
		
	}
	return Plugin_Continue;
}

//witch产生
  public Action:witchSpawn(Handle:event, const String:name[], 
  bool dontBroadcast)
  {
  if(GetConVarInt(l4d2_msg_system_zh_witch_spawn)==1) 
	{	
      PrintHintTextToAll("witch已经重生！");
    }
	return Plugin_Continue;
}

//杀死witch
public Action:witchKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d2_msg_system_zh_witch_killed)==1) 
	{	
		new player = GetClientOfUserId(GetEventInt(event, "userid"));
		if(player != 0 && IsClientInGame(player))
		{
			PrintToChatAll("%s\x04%N \x03的致命一击结束了 \x04Witch \x03的性命！", PLUGIN_PREFIX, player);
		}
	}
	return Plugin_Continue;
}

//惊动witch
public Action:witchHrasserSet(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d2_msg_system_zh_witch_harasser_set)==1) 
	{
		new player = GetClientOfUserId(GetEventInt(event, "userid"));
		PrintHintTextToAll("%N 惊扰了Witch",  player);
		PrintToChatAll("%s\x04%N \x03嫖妹不给钱 被追杀中！", PLUGIN_PREFIX, player);
	}
	return Plugin_Continue;
}


//玩家死亡
public Action:playerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{	
	if(GetConVarInt(l4d2_msg_system_zh_player_death)==1) 
	{
		new player = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if(player && GetClientTeam(player) == 2)
		{	
			if(attacker && player != attacker)
			{
				PrintToChatAll("%s\x04%N \x03杀死了 \x04%N\x03", PLUGIN_PREFIX, attacker, player);
				PrintHintTextToAll("%N 已经死亡",  player);
			}
			else 
			{
				PrintToChatAll("%s\x04%N\x03 已经死亡",PLUGIN_PREFIX, player);
				PrintHintTextToAll("%N 已经死亡",  player);
			}
		} 
		else if (GetConVarInt(l4d2_msg_system_zh_kill_in) == 1 && player && GetClientTeam(player) == 3)
		{	
			new class = GetEntProp(player, Prop_Send, "m_zombieClass");
			if(class == ZOMBIECLASS_SMOKER)
			{
				PrintToChat(attacker, "\x03击杀 Smoker");
			} 
			else if(class == ZOMBIECLASS_BOOMER)
			{
				PrintToChat(attacker, "\x03击杀 Boomer");
			} 
			else if(class == ZOMBIECLASS_HUNTER)
			{
				PrintToChat(attacker, "\x03击杀 Hunter");
			}
			else if(class == ZOMBIECLASS_SPITTER)
			{
				PrintToChat(attacker, "\x03击杀 Spitter");
			}
			else if(class == ZOMBIECLASS_JOCKEY)
			{
				PrintToChat(attacker, "\x03击杀 Jockey");
			}
			else if(class == ZOMBIECLASS_CHARGER)
			{
				PrintToChat(attacker, "\x03击杀 Charger");
			}
		}


	}
	return Plugin_Continue;
}

//触发警报
public Action:createPanicEvent(Handle:event, const String:name[], bool:dontBroadcast)
{	
	if(GetConVarInt(l4d2_msg_system_zh_create_panic_event)==1) 
	{
		new player = GetClientOfUserId(GetEventInt(event, "userid"));
		if(player && !IsFakeClient(player) && IsClientInGame(player))
		{
			PrintHintTextToAll("%N 触发了警报！",  player);
			PrintToChatAll("%s\x04%N\x03 这个蠢货又双叒叕触发了警报！！！", PLUGIN_PREFIX, player);
		}		
		
	}
	return Plugin_Continue;
}

//玩家倒地
public Action:playerIncapacitated(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{

	if(GetConVarInt(l4d2_msg_system_zh_player_incapacitated)==0)
	{
		return Plugin_Continue;
	}

	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	decl String:player_name[65];
	GetClientName(client, player_name, sizeof(player_name));

	decl String:buff[165];

 	new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
 	
	if (attacker != 0 )
	{
		decl String:player_name2[65];
		GetClientName(attacker, player_name2, sizeof(player_name2));
		if( GetClientTeam(attacker) ==2 || GetClientTeam(attacker) ==3) 
		{
			Format(buff, sizeof(buff), "%s\x04%s \x03制服了\x04 %s", PLUGIN_PREFIX, player_name2, player_name);
			PrintToChatAll(buff);

		}
	}
	else
	{
 			Format(buff, sizeof(buff), "%s\x04%s \x03倒下了", PLUGIN_PREFIX, player_name);
			PrintToChatAll(buff);
	}
	return Plugin_Continue;
}

//救起提示
public EventReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	new target = GetClientOfUserId(GetEventInt(event, "subject"));

 	decl String:targetName[64];
 	decl String:palyerName[64];
 
	GetClientName(target, targetName, sizeof(targetName));
	GetClientName(player, palyerName, sizeof(palyerName));
	
	if(player!=target )
	{
		if(GetConVarInt(l4d2_msg_system_zh_save_up)==1) PrintToChatAll("%s\x04%s \x03救起了 \x04%s ", PLUGIN_PREFIX, palyerName, targetName);
	}
	return;
}

public EventDefiSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	new target = GetClientOfUserId(GetEventInt(event, "subject"));
	
 	decl String:targetName[64];
 	decl String:palyerName[64];
 
	GetClientName(target, targetName, sizeof(targetName));
	GetClientName(player, palyerName, sizeof(palyerName));
	
	if(player!=target )
	{
		if(GetConVarInt(l4d2_msg_system_zh_use_def)==1) 
		{
			PrintToChatAll("%s\x04 %s \x03复活了 \x04%s ", PLUGIN_PREFIX, palyerName, targetName);
			PrintHintTextToAll("%s 复活了 %s", palyerName, targetName);
		}
	}
	return;
}



//玩家连接
public OnClientConnected(client)
{

	if (GetConVarInt(l4d2_msg_system_zh_player_in_out) == 1 && IsValidPlayer(client)) {
		if (!IsFakeClient(client)) {
			PrintToChatAll("%s\x04%N \x03正在连接服务器", PLUGIN_PREFIX, client, getCurPlayerCount());
		}
	}
}



public Action:Event_PlayerDisconnect(Handle:event, const String:strName[], bool:bDontBroadcast)
{	
	PrintToChatAll("\x04[提示]\x03  有人离开了游戏");
}

public Action:Event_PlayerConnect(Handle:event, const String:strName[], bool:bDontBroadcast)
{
	PrintToChatAll("\x04[提示]\x03  有人进入了游戏");
}

//玩家离开
public OnClientDisconnect(client)
{


	if (GetConVarInt(l4d2_msg_system_zh_player_in_out) == 1 && IsValidPlayer(client) && !IsFakeClient(client)) 
	{
		PrintToChatAll("%s\x04%N \x03离开了服务器", PLUGIN_PREFIX, client, getCurPlayerCount() - 1);
	}
}


static bool:IsValidPlayer(client) {
	if (0 < client <= MaxClients)
		return true;
	return false;
}

getCurPlayerCount() 
{
	new j = 0;
	for (new i=1; i<=MaxClients; i++) 
	{
		if (IsClientConnected(i) && !IsFakeClient(i)) {
			j++;
		}
	}
	return j;
}