#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#define SCORE_DELAY_EMPTY_SERVER 3.0
#define ZOMBIECLASS_SMOKER 1
#define ZOMBIECLASS_BOOMER 2
#define ZOMBIECLASS_HUNTER 3
#define ZOMBIECLASS_SPITTER 4
#define ZOMBIECLASS_JOCKEY 5
#define ZOMBIECLASS_CHARGER 6
#define ZOMBIECLASS_TANK 8
#define MaxHealth 100
#define VOTE_NO "no"
#define VOTE_YES "yes"
#define L4D_MAXCLIENTS_PLUS1 (MaxClients+1)
new Votey = 0;
new Voten = 0;
new bool: game_l4d2 = false;
//new String:ReadyMode[64];
//new String:Label[16];//ready 开启/关闭
//new String:VotensReady_ED[32];
new String:VotensHp_ED[32];
new String:VotensMap_ED[32];
new String:kickplayer[MAX_NAME_LENGTH];
new String:kickplayername[MAX_NAME_LENGTH];
new String:votesmaps[MAX_NAME_LENGTH];
new String:votesmapsname[MAX_NAME_LENGTH];
new Handle:g_hVoteMenu = INVALID_HANDLE;

new Handle:g_Cvar_Limits;
//new Handle:cvarFullResetOnEmpty;
//new Handle:VotensReadyED;
new Handle:VotensHpED;
new Handle:VotensMapED;
new Handle:VotensED;
new Float:lastDisconnectTime;
 
enum voteType
{
	//ready,
	hp,
	map,
	kicks
}
new voteType:g_voteType = voteType;
public Plugin:myinfo =
{
	name = "投票菜单插件",
	author = "fenghf",
	description = "Votes Commands",
	version = "1.2.2a",
	url = "http://bbs.3dmgame.com/l4d"
};
public OnPluginStart()
{
	decl String: game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead", false) && !StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("只能在left4dead1&2使用.");
	}
	if (StrEqual(game_name, "left4dead2", false))
	{
		game_l4d2 = true;
	}
	//RegAdminCmd("sm_voter", Command_Vote, ADMFLAG_KICK|ADMFLAG_VOTE|ADMFLAG_GENERIC|ADMFLAG_BAN|ADMFLAG_CHANGEMAP, "投票开启ready插件");S
	//RegConsoleCmd("votesready", Command_Voter);
	RegConsoleCmd("voteshp", Command_VoteHp);
	RegConsoleCmd("votesmapsmenu", Command_VotemapsMenu);
	RegConsoleCmd("voteskick", Command_Voteskick);
	RegConsoleCmd("sm_v", Command_Votes, "打开投票菜单");

	g_Cvar_Limits = CreateConVar("sm_v_s", "0.60", "百分比.", 0, true, 0.05, true, 1.0);
	//cvarFullResetOnEmpty = CreateConVar("l4d_full_reset_on_empty", "1", " 当服务器没有人的时候关闭ready插件", FCVAR_PLUGIN|FCVAR_NOTIFY);
	//VotensReadyED = CreateConVar("l4d_VotensreadyED", "0", " 启用、关闭 投票ready功能", FCVAR_PLUGIN|FCVAR_NOTIFY);
	VotensHpED = CreateConVar("l4d_VotenshpED", "1", " 启用、关闭 投票回血功能", FCVAR_PLUGIN|FCVAR_NOTIFY);
	VotensMapED = CreateConVar("l4d_VotensmapED", "1", " 启用、关闭 投票换图功能", FCVAR_PLUGIN|FCVAR_NOTIFY);
	VotensED = CreateConVar("l4d_Votens", "1", " 启用、关闭 插件", FCVAR_PLUGIN|FCVAR_NOTIFY);
}
/*
public OnMapStart()
{
	new Handle:currentReadyMode = FindConVar("l4d_ready_enabled");
	GetConVarString(currentReadyMode, ReadyMode, sizeof(ReadyMode));
	
	if (strcmp(ReadyMode, "0", false) == 0)
	{
		Format(Label, sizeof(Label), "开启");
	}
	else if (strcmp(ReadyMode, "1", false) == 0)
	{
		Format(Label, sizeof(Label), "关闭");
	}
}*/
public Action:Command_Votes(client, args) 
{ 
	if(GetConVarInt(VotensED) == 1)
	{
		//new VotensReadyE_D = GetConVarInt(VotensReadyED); 
		new VotensHpE_D = GetConVarInt(VotensHpED); 
		new VotensMapE_D = GetConVarInt(VotensMapED);
		/*
		if(VotensReadyE_D == 0)
		{
			VotensReady_ED = "开启";
		}
		else if(VotensReadyE_D == 1)
		{
			VotensReady_ED = "禁用";
		}*/
		if(VotensHpE_D == 0)
		{
			VotensHp_ED = "开启";
		}
		else if(VotensHpE_D == 1)
		{
			VotensHp_ED = "禁用";
		}
		
		if(VotensMapE_D == 0)
		{
			VotensMap_ED = "开启";
		}
		else if(VotensMapE_D == 1)
		{
			VotensMap_ED = "禁用";
		}
		new Handle:menu = CreatePanel();
		new String:Value[64];
		SetPanelTitle(menu, "投票菜单");
		/*
		if (VotensReadyE_D == 0)
		{
			DrawPanelItem(menu, "禁用投票ready插件");
		}
		else if(VotensReadyE_D == 1)
		{
			Format(Value, sizeof(Value), "投票%s ready插件", Label);
			DrawPanelItem(menu, Value);
		}*/
		if (VotensHpE_D == 0)
		{
			DrawPanelItem(menu, "禁用投票回血");
		}
		else if (VotensHpE_D == 1)
		{
			DrawPanelItem(menu, "投票回血");
		}
		if (VotensMapE_D == 0)
		{
			DrawPanelItem(menu, "禁用投票换图");
		}
		else if (VotensMapE_D == 1)
		{
			DrawPanelItem(menu, "投票换图");
		}
		DrawPanelItem(menu, "投票踢人");//常用,不添加开启关闭
		if (GetUserFlagBits(client)&ADMFLAG_ROOT || GetUserFlagBits(client)&ADMFLAG_CONVARS)
		{
			DrawPanelText(menu, "管理员选项");
			/*
			Format(Value, sizeof(Value), "%s 投票ready插件", VotensReady_ED);
			DrawPanelItem(menu, Value);
			*/
			Format(Value, sizeof(Value), "%s 投票回血", VotensHp_ED);
			DrawPanelItem(menu, Value);
			Format(Value, sizeof(Value), "%s 投票换图", VotensMap_ED);
			DrawPanelItem(menu, Value);
		}
		DrawPanelText(menu, " \n");
		DrawPanelItem(menu, "关闭");
		//SetMenuExitButton(menu, true);
		SendPanelToClient(menu, client,Votes_Menu, MENU_TIME_FOREVER);
		return Plugin_Handled;
	}
	else if(GetConVarInt(VotensED) == 0)
	{}
	return Plugin_Stop;
}
public Votes_Menu(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select ) 
	{
		//new VotensReadyE_D = GetConVarInt(VotensReadyED); 
		new VotensHpE_D = GetConVarInt(VotensHpED); 
		new VotensMapE_D = GetConVarInt(VotensMapED);
		switch (itemNum)
		{
		/*
			case 1: 
			{
				if (VotensReadyE_D == 0)
				{
					FakeClientCommand(client,"sm_v");
					PrintToChat(client, "[提示] 禁用投票ready插件");
					return ;
				}
				else if (VotensReadyE_D == 1)
				{
					FakeClientCommand(client,"votesready");
				}
			}
			*/
			case 1: 
			{
				if (VotensHpE_D == 0)
				{
					FakeClientCommand(client,"sm_v");
					PrintToChat(client, "[提示] 禁用投票回血");
					return;
				}
				else if (VotensHpE_D == 1)
				{
					FakeClientCommand(client,"voteshp");
				}
			}
			case 2: 
			{
				if (VotensMapE_D == 0)
				{
					FakeClientCommand(client,"sm_v");
					PrintToChat(client, "[提示] 禁用投票换图");
					return ;
				}
				else if (VotensMapE_D == 1)
				{
					FakeClientCommand(client,"votesmapsmenu");
				}
			}
			case 3: 
			{
				FakeClientCommand(client,"voteskick");
			}/*
			case 5: 
			{
				if (VotensReadyE_D == 0 && GetUserFlagBits(client)&ADMFLAG_ROOT || GetUserFlagBits(client)&ADMFLAG_CONVARS && VotensReadyE_D == 0)
				{
					SetConVarInt(FindConVar("l4d_VotensreadyED"), 1);
					PrintToChatAll("\x05[提示] \x04管理员 开启投票ready插件");
				}
				else if (VotensReadyE_D == 1 && GetUserFlagBits(client)&ADMFLAG_ROOT || GetUserFlagBits(client)&ADMFLAG_CONVARS && VotensReadyE_D == 1)
				{
					SetConVarInt(FindConVar("l4d_VotensreadyED"), 0);
					PrintToChatAll("\x05[提示] \x04管理员 禁用投票ready插件");
				}
			}*/
			case 4: 
			{
				if (VotensHpE_D == 0 && GetUserFlagBits(client)&ADMFLAG_ROOT || GetUserFlagBits(client)&ADMFLAG_CONVARS && VotensHpE_D == 0)
				{
					SetConVarInt(FindConVar("l4d_VotenshpED"), 1);
					PrintToChatAll("\x05[提示] \x04管理员 开启投票回血");
				}
				else if (VotensHpE_D == 1 && GetUserFlagBits(client)&ADMFLAG_ROOT || GetUserFlagBits(client)&ADMFLAG_CONVARS && VotensHpE_D == 1)
				{
					SetConVarInt(FindConVar("l4d_VotenshpED"), 0);
					PrintToChatAll("\x05[提示] \x04管理员 禁用投票回血");
				}
			}
			case 5: 
			{
				if (VotensMapE_D == 0 && GetUserFlagBits(client)&ADMFLAG_ROOT || GetUserFlagBits(client)&ADMFLAG_CONVARS && VotensMapE_D == 0)
				{
					SetConVarInt(FindConVar("l4d_VotensmapED"), 1);
					PrintToChatAll("\x05[提示] \x04管理员 开启投票换图");
				}
				else if (VotensMapE_D == 1 && GetUserFlagBits(client)&ADMFLAG_ROOT || GetUserFlagBits(client)&ADMFLAG_CONVARS && VotensMapE_D == 1)
				{
					SetConVarInt(FindConVar("l4d_VotensmapED"), 0);
					PrintToChatAll("\x05[提示] \x04管理员 禁用投票换图");
				}
			}
		}
	}
}

/*
public Action:Command_Voter(client, args)
{
	if(GetConVarInt(VotensED) == 1 && GetConVarInt(VotensReadyED) == 1)
	{
		if (IsVoteInProgress())
		{
			ReplyToCommand(client, "[提示] 已有投票在进行中");
			return Plugin_Handled;
		}
		if (!TestVoteDelay(client))
		{
			return Plugin_Handled;
		}
			
		PrintToChatAll("\x05[提示] \x04%N \x03发起投票 \x05%s \x03ready插件", client, Label);
		PrintToChatAll("\x05[提示] \x04服务器没有玩家的时候,ready插件自动关闭");
		
		g_voteType = voteType:ready;
		decl String:SteamId[35];
		GetClientAuthString(client, SteamId, sizeof(SteamId));
		LogMessage("%N %s发起投票%s ready插件!",  client, SteamId, Label);//记录在log文件
		
		g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
		SetMenuTitle(g_hVoteMenu, "是否%s ready插件?",Label);
		AddMenuItem(g_hVoteMenu, VOTE_YES, "Yes");
		AddMenuItem(g_hVoteMenu, VOTE_NO, "No");
	
		SetMenuExitButton(g_hVoteMenu, false);
		VoteMenuToAll(g_hVoteMenu, 20);		
		return Plugin_Handled;
	}
	else if(GetConVarInt(VotensED) == 0 && GetConVarInt(VotensReadyED) == 0)
	{
		PrintToChat(client, "[提示] 禁用投票ready插件");
	}
	return Plugin_Handled;
}
*/
public Action:Command_VoteHp(client, args)
{
	if(GetConVarInt(VotensED) == 1 
	&& GetConVarInt(VotensHpED) == 1)
	{
		if (IsVoteInProgress())
		{
			ReplyToCommand(client, "[提示] 已有投票在进行中");
			return Plugin_Handled;
		}
		
		if (!TestVoteDelay(client))
		{
			return Plugin_Handled;
		}
		PrintToChatAll("\x05[提示] \x04 %N \x03发起投票回血",client);
		
		g_voteType = voteType:hp;
		decl String:SteamId[35];
		GetClientAuthString(client, SteamId, sizeof(SteamId));
		LogMessage("%N &s发起投票所有人回血!",  client, SteamId);//记录在log文件
		g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
		SetMenuTitle(g_hVoteMenu, "是否所有人回血?");
		AddMenuItem(g_hVoteMenu, VOTE_YES, "Yes");
		AddMenuItem(g_hVoteMenu, VOTE_NO, "No");
	
		SetMenuExitButton(g_hVoteMenu, false);
		VoteMenuToAll(g_hVoteMenu, 20);		
		return Plugin_Handled;	
	}
	else if(GetConVarInt(VotensED) == 0 && GetConVarInt(VotensHpED) == 0)
	{
		PrintToChat(client, "[提示] 禁用投票回血");
	}
	return Plugin_Handled;
}

public Action:Command_Voteskick(client, args)
{
	if(client!=0) CreateVotekickMenu(client);		
	return Plugin_Handled;
}

CreateVotekickMenu(client)
{	
	new Handle:menu = CreateMenu(Menu_Voteskick);		
	new team = GetClientTeam(client);
	new String:name[MAX_NAME_LENGTH];
	new String:playerid[32];
	SetMenuTitle(menu, "选择踢出玩家");
	for(new i = 1;i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i)==team)
		{
			Format(playerid,sizeof(playerid),"%i",GetClientUserId(i));
			if(GetClientName(i,name,sizeof(name)))
			{
				AddMenuItem(menu, playerid, name);						
			}
		}		
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);	
}
public Menu_Voteskick(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32] , String:name[32];
		GetMenuItem(menu, param2, info, sizeof(info), _, name, sizeof(name));
		kickplayer = info;
		kickplayername = name;
		PrintToChatAll("\x05[提示] \x04%N 发起投票踢出 \x05 %s", param1, kickplayername);
		DisplayVoteKickMenu(param1);		
	}
}

public DisplayVoteKickMenu(client)
{
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[提示] 已有投票在进行中");
		return;
	}
	
	if (!TestVoteDelay(client))
	{
		return;
	}
	g_voteType = voteType:kicks;
	
	g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
	SetMenuTitle(g_hVoteMenu, "是否踢出玩家 %s",kickplayername);
	AddMenuItem(g_hVoteMenu, VOTE_YES, "Yes");
	AddMenuItem(g_hVoteMenu, VOTE_NO, "No");
	SetMenuExitButton(g_hVoteMenu, false);
	VoteMenuToAll(g_hVoteMenu, 20);
}

public Action:Command_VotemapsMenu(client, args)
{
	if(GetConVarInt(VotensED) == 1 && GetConVarInt(VotensMapED) == 1)
	{
		
		if (!TestVoteDelay(client))
		{
			return Plugin_Handled;
		}
		new Handle:menu = CreateMenu(MapMenuHandler);
	
		SetMenuTitle(menu, "请选择投票地图");
		if(game_l4d2)
		{
			//AddMenuItem(menu, "option1", "返回");
			AddMenuItem(menu, "c1m1_hotel", "C1死亡中心");
			AddMenuItem(menu, "c2m1_highway", "C2黑色嘉年华");
			AddMenuItem(menu, "c3m1_plankcountry", "C3沼泽激战");
			AddMenuItem(menu, "c4m1_milltown_a", "C4暴风骤雨");
			AddMenuItem(menu, "c5m1_waterfront", "C5教区");
			AddMenuItem(menu, "c6m1_riverbank", "C6消逝");
			AddMenuItem(menu, "c7m1_docks", "C7牺牲");
			AddMenuItem(menu, "c8m1_apartment", "C8毫不留情");
			AddMenuItem(menu, "c9m1_alleys", "C9坠机险途");
			AddMenuItem(menu, "c10m1_caves", "C10死亡丧钟");
			AddMenuItem(menu, "c11m1_greenhouse", "C11静寂时分");
			AddMenuItem(menu, "c12m1_hilltop", "C12血腥收获");
			AddMenuItem(menu, "c13m1_alpinecreek", "C13刺骨寒溪");
			AddMenuItem(menu, "c14m1_junkyard", "C14临死一搏");
			AddMenuItem(menu, "ch01_jupiter", "切尔诺贝利 (Chernobyl: Chapter One)");
			AddMenuItem(menu, "qe_1_cliche", "伦理问题 (Questionable Ethics)");
			AddMenuItem(menu, "qe2_ep1", "伦理问题2 (Questionable Ethics : Alpha test)");
			AddMenuItem(menu, "l4d2_bts01_forest", "回到学校 (Back to school)");
			AddMenuItem(menu, "l4d_yama_1", "摩耶山危机 (Yama)");
			AddMenuItem(menu, "l4d_dbd2dc_anna_is_gone", "活死人黎明 (Dead Before Dawn DC)");
			AddMenuItem(menu, "l4d_ihm01_forest", "我恨山2 (I Hate Mountains 2)");
			AddMenuItem(menu, "l4d2_daybreak01_hotel", "黎明 (Day Break)");
			AddMenuItem(menu, "l4d2_diescraper1_apartment_361", "喋血蜃楼 (Diescraper Redux)");
			AddMenuItem(menu, "dw_woods", "黑暗森林 (Dark Wood Extended)");
			AddMenuItem(menu, "wth_1", "欢迎来到地狱 (Welcome to Hell)");
			AddMenuItem(menu, "l4d2_7hours_later_01", "七小时后2 (7 Hours Later II)");
			AddMenuItem(menu, "ch_map1_city", "方氏 (True FangShi)");
		}
		else
		{
			//AddMenuItem(menu, "option1", "返回");
			AddMenuItem(menu, "l4d_vs_hospital01_apartment", "毫不留情");
			AddMenuItem(menu, "l4d_vs_airport01_greenhouse", "静寂时分");
			AddMenuItem(menu, "l4d_vs_smalltown01_caves", "死亡丧钟");
			AddMenuItem(menu, "l4d_vs_farm01_hilltop", "血腥收获");
			AddMenuItem(menu, "l4d_garage01_alleys", "坠机险途");
			AddMenuItem(menu, "l4d_river01_docks", "牺牲");
		}
		SetMenuExitBackButton(menu, true);
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
		
		return Plugin_Handled;
	}
	else 
	if(GetConVarInt(VotensED) == 0 && GetConVarInt(VotensMapED) == 0)
	{
		PrintToChat(client, "[提示] 禁用投票换图");
	}
	return Plugin_Handled;
}

public MapMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select ) 
	{
		new String:info[32] , String:name[32];
		GetMenuItem(menu, itemNum, info, sizeof(info), _, name, sizeof(name));
		votesmaps = info;
		votesmapsname = name;
		PrintToChatAll("\x05[提示] \x04%N 发起投票换图 \x05 %s", client, votesmapsname);
		DisplayVoteMapsMenu(client);		
	}
}
public DisplayVoteMapsMenu(client)
{
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[提示] 已有投票在进行中");
		return;
	}
	
	if (!TestVoteDelay(client))
	{
		return;
	}
	g_voteType = voteType:map;
	
	g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
	SetMenuTitle(g_hVoteMenu, "发起投票换图 %s %s",votesmapsname, votesmaps);
	AddMenuItem(g_hVoteMenu, VOTE_YES, "Yes");
	AddMenuItem(g_hVoteMenu, VOTE_NO, "No");
	SetMenuExitButton(g_hVoteMenu, false);
	VoteMenuToAll(g_hVoteMenu, 20);
}
public Handler_VoteCallback(Handle:menu, MenuAction:action, param1, param2)
{
	//==========================
	if(action == MenuAction_Select)
	{
		switch(param2)
		{
			case 0: 
			{
				Votey += 1;
				PrintToChatAll("\x03%N \x05投票了.", param1);
			}
			case 1: 
			{
				Voten += 1;
				PrintToChatAll("\x03%N \x04投票了.", param1);
			}
		}
	}
	//==========================
	decl String:item[64], String:display[64];
	new Float:percent, Float:limit, votes, totalVotes;

	GetMenuVoteInfo(param2, votes, totalVotes);
	GetMenuItem(menu, param1, item, sizeof(item), _, display, sizeof(display));
	
	if (strcmp(item, VOTE_NO) == 0 && param1 == 1)
	{
		votes = totalVotes - votes;
	}
	percent = GetVotePercent(votes, totalVotes);

	limit = GetConVarFloat(g_Cvar_Limits);
	
	CheckVotes();
	if (action == MenuAction_End)
	{
		VoteMenuClose();
	}
	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		PrintToChatAll("[提示] 没有票数");
	}	
	else if (action == MenuAction_VoteEnd)
	{
		if ((strcmp(item, VOTE_YES) == 0 && FloatCompare(percent,limit) < 0 && param1 == 0) || (strcmp(item, VOTE_NO) == 0 && param1 == 1))
		{
			PrintToChatAll("[提示] 投票失败. 至少需要 %d%% 支持.(同意 %d%% 总共 %i 票)", RoundToNearest(100.0*limit), RoundToNearest(100.0*percent), totalVotes);
			CreateTimer(2.0, VoteEndDelay);
		}
		else
		{
			PrintToChatAll("[提示] 投票通过.(同意 %d%% 总共 %i 票)", RoundToNearest(100.0*percent), totalVotes);
			CreateTimer(2.0, VoteEndDelay);
			switch (g_voteType)
			{
			/*
				case (voteType:ready):
				{
					if (strcmp(ReadyMode, "0", false) == 0 || strcmp(item, VOTE_NO) == 0 || strcmp(item, VOTE_YES) == 0 )
					{
						strcopy(item, sizeof(item), display);
						ServerCommand("sv_search_key 1");
						SetConVarInt(FindConVar("l4d_ready_enabled"), 1);
					}
					if (strcmp(ReadyMode, "1", false) == 0 || strcmp(item, VOTE_NO) == 0 || strcmp(item, VOTE_YES) == 0 )
					{
						ServerCommand("sv_search_key 1");
						SetConVarInt(FindConVar("l4d_ready_enabled"), 0);
					}
					PrintToChatAll("[提示] 投票的结果为: %s.", item);
					LogMessage("投票 %s ready通过",Label);
				}
				*/
				case (voteType:hp):
				{
					AnyHp();
					LogMessage("投票 所有玩家回血 ready通过");
				}
				case (voteType:map):
				{
					CreateTimer(5.0, Changelevel_Map);
					PrintToChatAll("\x03[提示] \x04 5秒后换图 \x05%s",votesmapsname);
					PrintToChatAll("\x04 %s",votesmaps);
					LogMessage("投票换图 %s %s 通过",votesmapsname,votesmaps);
				}
				case (voteType:kicks):
				{
					PrintToChatAll("\x05[提示] \x05 %s \x04投票踢出", kickplayername);
					ServerCommand("sm_kick %s 投票踢出", kickplayername);	
					LogMessage(" 投票踢出%s 通过",kickplayername);
				}
			}
		}
	}
	return 0;
}
//====================================================
public AnyHp()
{
	PrintToChatAll("\x03[提示]\x04所有玩家回血");
	new flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			FakeClientCommand(i, "give health");
			SetEntityHealth(i, MaxHealth);
			//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03回血",i);
		}
		else
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i)) 
		{
			new class = GetEntProp(i, Prop_Send, "m_zombieClass");
			if (class == ZOMBIECLASS_SMOKER)
			{
				SetEntityHealth(i, 250);
				//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03Smoker回血",i);//请勿使用提示,否则知道有那些特感
			}
			else
			if (class == ZOMBIECLASS_BOOMER)
			{
				SetEntityHealth(i, 50);
				//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03Boomer回血",i);//请勿使用提示,否则知道有那些特感
			}
			else
			if (class == ZOMBIECLASS_HUNTER)
			{
				SetEntityHealth(i, 250);
				//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03Hunter回血",i);//请勿使用提示,否则知道有那些特感
			}
			else
            if (class == ZOMBIECLASS_SPITTER)
			{
				SetEntityHealth(i, 100);
				//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03Spitter 回血",i);//请勿使用提示,否则知道有那些特感
			}
			else
			if (class == ZOMBIECLASS_JOCKEY)
			{
				decl String:game_name[64];
				GetGameFolderName(game_name, sizeof(game_name));
				if (!StrEqual(game_name, "left4dead2", false))
				{
					SetEntityHealth(i, 6000);
					//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03Tank 回血",i);//请勿使用提示,否则知道有那些特感
				}
				else
				{
					SetEntityHealth(i, 325);
					//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03Jockey回血",i);//请勿使用提示,否则知道有那些特感
				}
			}
			else
			if (class == ZOMBIECLASS_CHARGER)
			{
				SetEntityHealth(i, 600);
				//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03Charger回血",i);//请勿使用提示,否则知道有那些特感
			}
			else
			if (class == ZOMBIECLASS_TANK)
			{
				SetEntityHealth(i, 6000);
				//PrintToChatAll("\x03[所有人]玩家 \x04%N \x03Tank回血",i);//请勿使用提示,否则知道有那些特感
			}
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}
//================================
CheckVotes()
{
	PrintHintTextToAll("同意: \x04%i\n不同意: \x04%i", Votey, Voten);
}
public Action:VoteEndDelay(Handle:timer)
{
	Votey = 0;
	Voten = 0;
}
public Action:Changelevel_Map(Handle:timer)
{
	ServerCommand("changelevel %s", votesmaps);
}
//===============================
VoteMenuClose()
{
	Votey = 0;
	Voten = 0;
	CloseHandle(g_hVoteMenu);
	g_hVoteMenu = INVALID_HANDLE;
}
Float:GetVotePercent(votes, totalVotes)
{
	return FloatDiv(float(votes),float(totalVotes));
}
bool:TestVoteDelay(client)
{
 	new delay = CheckVoteDelay();
 	
 	if (delay > 0)
 	{
 		if (delay > 60)
 		{
 			PrintToChat(client, "[提示] 您必须再等 %i 分钟後才能发起新一轮投票", delay % 60);
 		}
 		else
 		{
 			PrintToChat(client, "[提示] 您必须再等 %i 秒钟後才能发起新一轮投票", delay);
 		}
 		return false;
 	}
	return true;
}
//=======================================
public OnClientDisconnect(client)
{
	if (IsClientInGame(client) && IsFakeClient(client)) return;

	new Float:currenttime = GetGameTime();
	
	if (lastDisconnectTime == currenttime) return;
	
	CreateTimer(SCORE_DELAY_EMPTY_SERVER, IsNobodyConnected, currenttime);
	lastDisconnectTime = currenttime;
}

public Action:IsNobodyConnected(Handle:timer, any:timerDisconnectTime)
{
	if (timerDisconnectTime != lastDisconnectTime) return Plugin_Stop;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
			return  Plugin_Stop;
	}
	/*
	SetConVarInt(FindConVar("l4d_ready_enabled"), 0);		
	if (GetConVarBool(cvarFullResetOnEmpty))
	{
		SetConVarInt(FindConVar("l4d_ready_enabled"), 0);
	}*/
	
	return  Plugin_Stop;
}
