/*
更新日志:
添加9.24更新的两把近战翻译
语法更新到sm1.10
近战给物功能支持三方图自定义近战
保存命令的全局字符串变量改为给每个玩家分别保存命令
修复给生命值后会出现虚血超过100的情况
刷特感功能支持强制刷出超过导演系统默认数量的特感，支持指定特感玩家复活
踢出所有Bot功能现在只踢出无闲置玩家控制的Bot
删除友伤设置功能
传送功能改为菜单变量传递被传送目标的参数而不是原来全局变量传递，防止多人同时使用传送功能时出现Bug
传送功能现在支持传送被牛控制或者挂边的玩家
复活功能在玩家复活后默认给1把MAC微冲
删除重复上一次功能
添加装备剥夺功能，可删除指定玩家/所有玩家身上的某样/全部物品
优化菜单功能，添加一部分菜单的回退功能
添加了强制倒地功能
恢复友伤设置功能
*/
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define GAMEDATA "ry_give_fix"

Handle hRoundRespawn;
int g_iMeleeClassCount;
char g_sMeleeClass[16][32];

char g_sItemName[MAXPLAYERS + 1][64];

static const char g_sMeleeModels[][] =
{
	"models/weapons/melee/v_bat.mdl",
	"models/weapons/melee/w_bat.mdl",
	"models/weapons/melee/v_cricket_bat.mdl",
	"models/weapons/melee/w_cricket_bat.mdl",
	"models/weapons/melee/v_crowbar.mdl",
	"models/weapons/melee/w_crowbar.mdl",
	"models/weapons/melee/v_electric_guitar.mdl",
	"models/weapons/melee/w_electric_guitar.mdl",
	"models/weapons/melee/v_fireaxe.mdl",
	"models/weapons/melee/w_fireaxe.mdl",
	"models/weapons/melee/v_frying_pan.mdl",
	"models/weapons/melee/w_frying_pan.mdl",
	"models/weapons/melee/v_golfclub.mdl",
	"models/weapons/melee/w_golfclub.mdl",
	"models/weapons/melee/v_katana.mdl",
	"models/weapons/melee/w_katana.mdl",
	"models/weapons/melee/v_machete.mdl",
	"models/weapons/melee/w_machete.mdl",
	"models/weapons/melee/v_tonfa.mdl",
	"models/weapons/melee/w_tonfa.mdl",
	"models/weapons/melee/v_riotshield.mdl",
	"models/weapons/melee/w_riotshield.mdl",
	"models/weapons/melee/v_pitchfork.mdl",
	"models/weapons/melee/w_pitchfork.mdl",
	"models/weapons/melee/v_shovel.mdl",
	"models/weapons/melee/w_shovel.mdl"
};

static const char g_sMeleeName[][] =
{
	"knife",
	"cricket_bat",
	"crowbar",
	"electric_guitar",
	"fireaxe",
	"frying_pan",
	"golfclub",
	"baseball_bat",
	"katana",
	"machete",
	"tonfa",
	"riotshield",
	"pitchfork",
	"shovel"
};

static const char g_sMeleeTrans[][] =
{
	"小刀",
	"板球棍",
	"撬棍",
	"电吉他",
	"消防斧",
	"平底锅",
	"高尔夫球棍",
	"棒球棒",
	"武士刀",
	"砍刀",
	"警棍",
	"盾牌",
	"干草叉",
	"铁铲"
};

public Plugin myinfo =
{
	name = "Give Item Menu",
	description = "Gives Item Menu",
	author = "Ryanx, sorallll",
	version = "1.0.0",
	url = ""
};

public void OnPluginStart()
{
	CreateConVar("rygive_version", "1.0.0", "rygive功能插件", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if(FileExists(sPath) == false)
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if(hGameData == null) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "RoundRespawn");
	hRoundRespawn = EndPrepSDKCall();
	if(hRoundRespawn == null)
		SetFailState("RoundRespawn Signature broken. Make sure \"%s.txt\" is in /gamedata/", GAMEDATA);

	RegAdminCmd("sm_rygive", RygiveMenu, ADMFLAG_ROOT, "rygive");
}

public void OnMapStart()
{
	int len;

	len = sizeof(g_sMeleeModels);
	for(int i; i < len; i++)
	{
		if(!IsModelPrecached(g_sMeleeModels[i]))
			PrecacheModel(g_sMeleeModels[i], true);
	}

	len = sizeof(g_sMeleeName);
	char buffer[32];
	for(int i; i < len; i++)
	{
		FormatEx(buffer, sizeof(buffer), "scripts/melee/%s.txt", g_sMeleeName[i]);
		if(!IsGenericPrecached(buffer))
			PrecacheModel(buffer, true);
	}
	CreateTimer(1.0, CheckMelee, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action CheckMelee(Handle timer)
{
	GetMeleeClasses();
}

stock void GetMeleeClasses()
{
	g_iMeleeClassCount = 0;
	for(int i; i < 16; i++)
	{
		g_sMeleeClass[i][0] = 0;
	}
	
	int MeleeStringTable = FindStringTable("MeleeWeapons");
	int iCount = GetStringTableNumStrings(MeleeStringTable);
	
	char sMeleeClass[16][32];
	for(int i; i < iCount; i++)
	{
		ReadStringTable(MeleeStringTable, i, sMeleeClass[i], sizeof(sMeleeClass[]));
		if(IsVaidMelee(sMeleeClass[i]))
			strcopy(g_sMeleeClass[g_iMeleeClassCount++], sizeof(g_sMeleeClass[]), sMeleeClass[i]);
	}
}

stock bool IsVaidMelee(const char[] sWeapon)
{
	bool IsVaid = false;
	int iEntity = CreateEntityByName("weapon_melee");
	DispatchKeyValue(iEntity, "melee_script_name", sWeapon);
	DispatchSpawn(iEntity);

	char modelname[256];
	GetEntPropString(iEntity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
	if(StrContains(modelname, "hunter", false) == -1)
		IsVaid = true;

	RemoveEdict(iEntity);
	return IsVaid;
}

public Action RygiveMenu(int client, int args)
{
	if(client && IsClientInGame(client))
		Rygive(client);

	return Plugin_Handled;
}

public Action Rygive(int client)
{
	Menu menu = new Menu(RygiveMenuHandler);
	menu.SetTitle("多功能插件");
	menu.AddItem("0", "手枪及近战");
	menu.AddItem("1", "微种及步枪");
	menu.AddItem("2", "散弹及狙击");
	menu.AddItem("3", "药品及投掷");
	menu.AddItem("4", "其它");
	menu.AddItem("5", "升级附件");
	menu.AddItem("6", "装备剥夺");
	menu.AddItem("7", "服务器人数设置");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int RygiveMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			switch(param2)
			{
				case 0:
					DisplaySMMenu(client);
				case 1:
					DisplaySRMenu(client);
				case 2:
					DisplaySSMenu(client);
				case 3:
					DisplayMTMenu(client);
				case 4:
					DisplayOTMenu(client);
				case 5:
					DisplayLUMenu(client);
				case 6:
					DisplaySWMenu(client);
				case 7:
					DisplaySLMenu(client);
			}
		}
	}
}

public int DisplaySMMenu(int client)
{
	Menu menu = new Menu(SMMenuHandler);
	menu.SetTitle("手枪及近战");
	menu.AddItem("pistol", "小手枪");
	menu.AddItem("pistol_magnum", "马格南");
	menu.AddItem("weapon_chainsaw", "电锯");
	for(int i; i < g_iMeleeClassCount; i++)
	{
		int iTrans = GetMeleeTrans(g_sMeleeClass[i]);
		if(iTrans != -1)
			menu.AddItem(g_sMeleeClass[i], g_sMeleeTrans[iTrans]);
		else
			menu.AddItem(g_sMeleeClass[i], g_sMeleeClass[i]); //三方图自定义近战显示默认脚本名称
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

stock int GetMeleeTrans(char[] MeleeName)
{
	for(int i; i < sizeof(g_sMeleeName); i++)
	{
		if(strcmp(g_sMeleeName[i], MeleeName) == 0)
			return i;
	}
	return -1;
}

public int SMMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Rygive(client);
		}
		case MenuAction_Select:
		{
			char menu1[64];
			if(menu.GetItem(param2, menu1, sizeof(menu1)))
			{
				FormatEx(g_sItemName[client], 64, "give %s", menu1);
				DisplayNLMenu(client);
			}
		}
	}
}

public int DisplaySRMenu(int client)
{
	Menu menu = new Menu(SRMenuHandler);
	menu.SetTitle("微种及步枪");
	menu.AddItem("smg", "UZI");
	menu.AddItem("smg_silenced", "MAC");
	menu.AddItem("weapon_smg_mp5", "MP5");
	menu.AddItem("rifle_ak47", "AK47");
	menu.AddItem("rifle", "M16");
	menu.AddItem("rifle_desert", "SCAR");
	menu.AddItem("weapon_rifle_sg552", "SG552");
	menu.AddItem("weapon_grenade_launcher", "榴弹枪");
	menu.AddItem("rifle_m60", "M60");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int SRMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Rygive(client);
		}
		case MenuAction_Select:
		{
			char menu1[64];
			if(menu.GetItem(param2, menu1, sizeof(menu1)))
			{
				FormatEx(g_sItemName[client], 64, "give %s", menu1);
				DisplayNLMenu(client);
			}
		}
	}
}

public int DisplaySSMenu(int client)
{
	Menu menu = new Menu(SSMenuHandler);
	menu.SetTitle("散弹及狙击");
	menu.AddItem("pumpshotgun", "M870");
	menu.AddItem("shotgun_chrome", "Chrome");
	menu.AddItem("autoshotgun", "M1014");
	menu.AddItem("shotgun_spas", "SPAS");
	menu.AddItem("hunting_rifle", "M14");
	menu.AddItem("sniper_military", "G3SG1");
	menu.AddItem("weapon_sniper_scout", "Scout");
	menu.AddItem("weapon_sniper_awp", "AWP");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int SSMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Rygive(client);
		}
		case MenuAction_Select:
		{
			char menu1[64];
			if(menu.GetItem(param2, menu1, sizeof(menu1)))
			{
				FormatEx(g_sItemName[client], 64, "give %s", menu1);
				DisplayNLMenu(client);
			}
		}
	}
}

public int DisplayMTMenu(int client)
{
	Menu menu = new Menu(MTMenuHandler);
	menu.SetTitle("药品及投掷");
	menu.AddItem("pain_pills", "药丸");
	menu.AddItem("adrenaline", "肾上腺");
	menu.AddItem("first_aid_kit", "医药包");
	menu.AddItem("defibrillator", "电击器");
	menu.AddItem("vomitjar", "胆汁");
	menu.AddItem("pipe_bomb", "土制");
	menu.AddItem("molotov", "燃烧瓶");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MTMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Rygive(client);
		}
		case MenuAction_Select:
		{
			char menu1[64];
			if(menu.GetItem(param2, menu1, sizeof(menu1)))
			{
				FormatEx(g_sItemName[client], 64, "give %s", menu1);
				DisplayNLMenu(client);
			}
		}
	}
}

public int DisplayOTMenu(int client)
{
	Menu menu = new Menu(OTMenuHandler);
	menu.SetTitle("其它");
	menu.AddItem("health", "生命值");
	menu.AddItem("incapplayer", "强制倒地");
	menu.AddItem("rmaddinf", "感染者");
	menu.AddItem("rffset", "友伤设置");
	menu.AddItem("ammo", "子弹");
	menu.AddItem("weapon_upgradepack_incendiary", "燃烧弹盒");
	menu.AddItem("weapon_upgradepack_explosive", "高爆弹盒");
	menu.AddItem("gascan", "汽油桶");
	menu.AddItem("propanetank", "煤气罐");
	menu.AddItem("oxygentank", "氧气瓶");
	menu.AddItem("weapon_fireworkcrate", "烟花");
	menu.AddItem("weapon_gnome", "圣诞老人");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int OTMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Rygive(client);
		}
		case MenuAction_Select:
		{
			char menu1[64];
			if(menu.GetItem(param2, menu1, sizeof(menu1)))
			{
				switch(param2)
				{
					case 0:
					{
						FormatEx(g_sItemName[client], 64, "give %s", menu1);
						DisplayRLMenu(client);
					}
					case 1:
						DisplayINCAPMenu(client);
					case 2:
						DisplayRMIFMenu(client);
					case 3:
						DisplayRFFMenu(client);
					default:
					{
						FormatEx(g_sItemName[client], 64, "give %s", menu1);
						DisplayNLMenu(client);
					}
				}
			}
		}
	}
}

public int DisplayRLMenu(int client)
{
	char name[MAX_NAME_LENGTH];
	char uid[16];
	Menu menu = new Menu(RLMenuHandler);
	menu.SetTitle("给谁生命值");
	menu.AddItem("allsurvivor", "所有<生还者>");
	menu.AddItem("allinfected", "所有<感染者>");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			FormatEx(name, sizeof(name), "%N", i);
			FormatEx(uid, sizeof(uid), "%d", GetClientUserId(i));
			menu.AddItem(uid, name);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int RLMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				DisplayOTMenu(client);
		}
		case MenuAction_Select:
		{
			char info[16];
			if(menu.GetItem(param2, info, sizeof(info)))
			{
				if(!strcmp(info, "allsurvivor", true))
				{
					for(int i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
							CheatCommand(i, g_sItemName[client]);
					}
				}
				else if(!strcmp(info, "allinfected", true))
				{
					for(int i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
							CheatCommand(i, g_sItemName[client]);
					}
				}
				else
					CheatCommand(GetClientOfUserId(StringToInt(info)), g_sItemName[client]);
			}
		}
	}
}

public int DisplayINCAPMenu(int client)
{
	char name[MAX_NAME_LENGTH];
	char uid[16];
	Menu menu = new Menu(INCAPMenuHandler);
	menu.SetTitle("倒地目标");
	menu.AddItem("allplayer", "<所有人>");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !IsIncapacitated(i))
		{
			FormatEx(name, sizeof(name), "%N", i);
			FormatEx(uid, sizeof(uid), "%d", GetClientUserId(i));
			menu.AddItem(uid, name);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int INCAPMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				DisplayOTMenu(client);
		}
		case MenuAction_Select:
		{
			char info[16];
			if(menu.GetItem(param2, info, sizeof(info)))
			{
				if(!strcmp(info, "allplayer", true))
				{
					for(int i = 1; i <= MaxClients; i++)
					{
						IncapCheck(i);
					}
				}
				else
				{
					int target = GetClientOfUserId(StringToInt(info));
					if(target > 0)
						IncapCheck(target);
					DisplayINCAPMenu(client);
				}
			}
		}
	}
}

stock bool IsIncapacitated(int client) 
{
	return !!GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

void IncapCheck(int client)
{
	if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && !IsIncapacitated(client))
	{
		if(FindConVar("survivor_max_incapacitated_count").IntValue == GetEntProp(client, Prop_Send, "m_currentReviveCount"))
		{
			SetEntProp(client, Prop_Send, "m_currentReviveCount", FindConVar("survivor_max_incapacitated_count").IntValue - 1);
			SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
			SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
			StopSound(client, SNDCHAN_STATIC, "player/heartbeatloop.wav");
		}
		IncapPlayer(client);
	}
}

stock void IncapPlayer(int client) 
{
	float fPos[3];
	char sUser[128];
	GetClientAbsOrigin(client, fPos);
	FormatEx(sUser, sizeof(sUser), "hurtme%d", client);
	int iEntity = CreateEntityByName("point_hurt");
	if(iEntity > 0)
	{
		SetEntityHealth(client, 1);
		DispatchKeyValue(iEntity, "Damage", "6000");
		DispatchKeyValue(iEntity, "DamageType", "128");
		DispatchKeyValue(client, "targetname", sUser);
		DispatchKeyValue(iEntity, "DamageTarget", sUser);
		DispatchSpawn(iEntity);
		TeleportEntity(iEntity, fPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(iEntity, "Hurt");
		RemoveEntity(iEntity);
	}
}

public int DisplayRMIFMenu(int client)
{
	Menu menu = new Menu(RMIFMenuHandler);
	menu.SetTitle("感染者");
	menu.AddItem("tank", "Tank坦克");
	menu.AddItem("witch", "Witch女巫");
	menu.AddItem("charger", "Charger牛哥");
	menu.AddItem("hunter", "Hunter猎手");
	menu.AddItem("jockey", "Jockey猴子");
	menu.AddItem("smoker", "Smoker舌头");
	menu.AddItem("spitter", "Spitter口水");
	menu.AddItem("boomer", "Boomer胖子");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int RMIFMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				DisplayOTMenu(client);
		}
		case MenuAction_Select:
		{
			char menu1[64];
			if(menu.GetItem(param2, menu1, sizeof(menu1)))
			{
				FormatEx(g_sItemName[client], 64, "z_spawn_old %s", menu1);
				DisplayRafNLMenu(client);
			}
		}
	}
}

public int DisplayRafNLMenu(int client)
{
	char name[MAX_NAME_LENGTH];
	char uid[16];
	Menu menu = new Menu(RafNLMenuHandler);
	menu.SetTitle("玩家列表");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			FormatEx(name, sizeof(name), "%N", i);
			FormatEx(uid, sizeof(uid), "%d", GetClientUserId(i));
			menu.AddItem(uid, name);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int RafNLMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				DisplayRMIFMenu(client);
		}
		case MenuAction_Select:
		{
			char info[16];
			if(menu.GetItem(param2, info, sizeof(info)))
			{
				int target = GetClientOfUserId(StringToInt(info));
				bool[] resetGhost = new bool[MaxClients + 1];
				bool[] resetLifeState = new bool[MaxClients + 1];
				int i;
				for(i = 1; i <= MaxClients; i++)
				{
					if(i == target || !IsClientInGame(i) || GetClientTeam(i) != 3 || IsFakeClient(i))
						continue;

					if(GetEntProp(i, Prop_Send, "m_isGhost") == 1)
					{
						resetGhost[i] = true;
						SetEntProp(i, Prop_Send, "m_isGhost", 0);
					}
					else if(!IsPlayerAlive(i))
					{
						resetLifeState[i] = true;
						SetEntProp(i, Prop_Send, "m_lifeState", 0);
					}
				}
				int DummyBot = CreateFakeClient("DummyBot");
				if(DummyBot > 0)
				{
					ChangeClientTeam(DummyBot, 3);
					CheatCommand(target, g_sItemName[client]);
					KickClient(DummyBot);
				}
				for(i = 1; i <= MaxClients; i++)
				{
					if(resetGhost[i]) 
						SetEntProp(i, Prop_Send, "m_isGhost", 1);
					if(resetLifeState[i]) 
						SetEntProp(i, Prop_Send, "m_lifeState", 1);
				}
				DisplayRafNLMenu(client);
			}
		}
	}
}

public int DisplayRFFMenu(int client)
{
	Menu menu = new Menu(RFFMenuHandler);
	menu.SetTitle("友伤设置");
	menu.AddItem("-1.0", "恢复默认");
	menu.AddItem("0.0", "0.0(简单)");
	menu.AddItem("0.1", "0.1(普通)");
	menu.AddItem("0.2", "0.2");
	menu.AddItem("0.3", "0.3(困难)");
	menu.AddItem("0.4", "0.4");
	menu.AddItem("0.5", "0.5(专家)");
	menu.AddItem("0.6", "0.6");
	menu.AddItem("0.7", "0.7");
	menu.AddItem("0.8", "0.8");
	menu.AddItem("0.9", "0.9");
	menu.AddItem("1.0", "1.0");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int RFFMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				DisplayOTMenu(client);
		}
		case MenuAction_Select:
		{
			char info[16];
			if(menu.GetItem(param2, info, sizeof(info)))
			{
				switch(param2)
				{
					case 0:
					{
						FindConVar("survivor_friendly_fire_factor_easy").RestoreDefault();
						FindConVar("survivor_friendly_fire_factor_normal").RestoreDefault();
						FindConVar("survivor_friendly_fire_factor_hard").RestoreDefault();
						FindConVar("survivor_friendly_fire_factor_expert").RestoreDefault();
					}
					default:
					{
						float percent = StringToFloat(info);
						FindConVar("survivor_friendly_fire_factor_easy").SetFloat(percent);
						FindConVar("survivor_friendly_fire_factor_normal").SetFloat(percent);
						FindConVar("survivor_friendly_fire_factor_hard").SetFloat(percent);
						FindConVar("survivor_friendly_fire_factor_expert").SetFloat(percent);
					}
				}
			}
		}
	}
}

public int DisplayLUMenu(int client)
{
	Menu menu = new Menu(LUMenuHandler);
	menu.SetTitle("升级附件&特殊");
	menu.AddItem("laser_sight", "红外线");
	menu.AddItem("Incendiary_ammo", "燃烧子弹");
	menu.AddItem("explosive_ammo", "高爆子弹");
	menu.AddItem("respawns", "复活某人");
	menu.AddItem("warp_all_survivors_heres", "传送");
	menu.AddItem("slayinfected", "处死所有感染者");
	menu.AddItem("slayplayer", "处死所有玩家");
	menu.AddItem("kickallbots", "踢除所有bot");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int LUMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				RygiveMenu(client, 0);
		}
		case MenuAction_Select:
		{
			switch(param2)
			{
				case 0 , 1, 2:
				{
					char menu1[64];
					if(menu.GetItem(param2, menu1, sizeof(menu1)))
					{
						FormatEx(g_sItemName[client], 64, "upgrade_add %s", menu1);
						DisplayNLMenu(client);
					}
				}
				case 3:
					DisplayRPMenu(client);
				case 4:
					DisplayTEMenu(client);
				case 5:
				{
					for(int i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
							ForcePlayerSuicide(i);
					}
				}
				case 6:
				{
					for(int i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
							ForcePlayerSuicide(i);
					}
				}
				case 7:
				{
					for(int i = 1; i <= MaxClients; i++)
					{
						if(IsBotValid(i))
							KickClient(i);
					}
				}
			}
		}
	}
}

bool IsBotValid(int client)
{
	if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsFakeClient(client) && !GetIdlePlayer(client) && !IsClientInKickQueue(client))
		return true;

	return false;
}

int GetIdlePlayer(int bot)
{
	if(IsPlayerAlive(bot))
	{
		if(HasEntProp(bot, Prop_Send, "m_humanSpectatorUserID"))
		{
			int client = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));			
			if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 1)
				return client;
		}
	}
	return 0;
}

public int DisplaySWMenu(int client)
{
	char name[MAX_NAME_LENGTH];
	char uid[16];
	Menu menu = new Menu(SWMenuHandler);
	menu.SetTitle("剥夺目标");
	menu.AddItem("allplayer", "<所有人>");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			FormatEx(name, sizeof(name), "%N", i);
			FormatEx(uid, sizeof(uid), "%d", GetClientUserId(i));
			menu.AddItem(uid, name);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int SWMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				RygiveMenu(client, 0);
		}
		case MenuAction_Select:
		{
			char info[16];
			if(menu.GetItem(param2, info, sizeof(info)))
			{
				if(!strcmp(info, "allplayer", true))
				{
					for(int i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
							DeletePlayerSlotAll(i);
					}
				}
				else
				{
					int target = GetClientOfUserId(StringToInt(info));
					if(target > 0)
						SlotSlect(client, target);
				}
			}
		}
	}
}

public int SlotSlect(int client, int target)
{
	char uid[2][16];
	char uidplus[32];
	Menu menu = new Menu(SlotSlectHandler);
	menu.SetTitle("要剥夺的装备");
	FormatEx(uid[0], 16, "%d", GetClientUserId(target));
	strcopy(uid[1], 16, "allslot");
	ImplodeStrings(uid, 2, "|", uidplus, sizeof(uidplus));
	menu.AddItem(uidplus, "<所有装备>");
	for(int i; i < 5; i++)
	{
		int weapon = GetPlayerWeaponSlot(target, i);
		if(weapon > MaxClients && IsValidEntity(weapon))
		{
			char clsaaname[32];
			GetEntityClassname(weapon, clsaaname, sizeof(clsaaname));
			FormatEx(uid[1], 16, "%d", i);
			ImplodeStrings(uid, 2, "|", uidplus, sizeof(uidplus));
			menu.AddItem(uidplus, clsaaname[7]);
		}	
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int SlotSlectHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				DisplaySWMenu(client);
		}
		case MenuAction_Select:
		{
			char info[2][16];
			char infoplus[32];
			if(menu.GetItem(param2, infoplus, sizeof(infoplus)))
			{
				ExplodeString(infoplus, "|", info, 2, 16);
				int target = GetClientOfUserId(StringToInt(info[0]));
				if(target > 0)
				{
					if(!strcmp(info[1], "allslot", true))
					{
						DeletePlayerSlotAll(target);
						DisplaySWMenu(client);
					}
					else
					{
						DeletePlayerSlotX(target, StringToInt(info[1]));
						SlotSlect(client, target);
					}
				}
			}
		}
	}
}

stock void DeletePlayerSlot(int client, int weapon)
{		
	if(RemovePlayerItem(client, weapon))
		RemoveEntity(weapon);
}

stock void DeletePlayerSlotX(int client, int slot)
{
	int iSlot = GetPlayerWeaponSlot(client, slot);
	if(iSlot > 0)
	{
		if(RemovePlayerItem(client, iSlot))
			RemoveEntity(iSlot);
	}
}

stock void DeletePlayerSlotAll(int client)
{
	int iSlot;
	for(int i; i < 5; i++)
	{
		iSlot = GetPlayerWeaponSlot(client, i);
		if(iSlot > 0)
			DeletePlayerSlot(client, iSlot);
	}
}

public int DisplayNLMenu(int client)
{
	char name[MAX_NAME_LENGTH];
	char uid[16];
	Menu menu = new Menu(NLMenuHandler);
	menu.SetTitle("玩家列表");
	menu.AddItem("allplayer", "<所有人>");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			FormatEx(name, sizeof(name), "%N", i);
			FormatEx(uid, sizeof(uid), "%d", GetClientUserId(i));
			menu.AddItem(uid, name);
		}
	}
	menu.ExitBackButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int NLMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char info[16];
			if(menu.GetItem(param2, info, sizeof(info)))
			{
				if(!strcmp(info, "allplayer", true))
				{
					for(int i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
							CheatCommand(i, g_sItemName[client]);
					}
				}
				else
					CheatCommand(GetClientOfUserId(StringToInt(info)), g_sItemName[client]);
			}
		}
	}
}

public int DisplayRPMenu(int client)
{
	char name[MAX_NAME_LENGTH];
	char uid[16];
	Menu menu = new Menu(RPMenuHandler);
	menu.SetTitle("复活列表");
	menu.AddItem("alldead", "所有<死人>");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && !IsPlayerAlive(i))
		{
			FormatEx(name, sizeof(name), "%N", i);
			FormatEx(uid, sizeof(uid), "%d", GetClientUserId(i));
			menu.AddItem(uid, name);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int RPMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				DisplayLUMenu(client);
		}
		case MenuAction_Select:
		{
			char info[16];
			if(menu.GetItem(param2, info, sizeof(info)))
			{
				if(!strcmp(info, "alldead", true))
				{
					for(int i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && GetClientTeam(i) == 2 && !IsPlayerAlive(i))
						{
							SDKCall(hRoundRespawn, i);
							TeleportToSurvivor(i);
						}
					}
				}
				else
				{
					int target = GetClientOfUserId(StringToInt(info));
					SDKCall(hRoundRespawn, target);
					TeleportToSurvivor(target);
					DisplayRPMenu(client);
				}
			}
		}
	}
}

void TeleportToSurvivor(int client) 
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(i != client && IsClientInGame(i) && GetClientTeam(i) == 2 && IsAlive(i))
		{
			float pos[3];
			GetClientAbsOrigin(i, pos);
			TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
			CheatCommand(client, "give smg_silenced");
			return;
		}
	}
}

bool IsAlive(int client)
{
	if(!GetEntProp(client, Prop_Send, "m_lifeState")) 
		return true;

	return false;
}

public int DisplayTEMenu(int client)
{
	char name[MAX_NAME_LENGTH];
	char uid[16];
	Menu menu = new Menu(TEMenuHandler);
	menu.SetTitle("传送谁");
	menu.AddItem("as", "所有<生还者>");
	menu.AddItem("ai", "所有<感染者>");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			FormatEx(name, sizeof(name), "%N", i);
			FormatEx(uid, sizeof(uid), "%d", GetClientUserId(i));
			menu.AddItem(uid, name);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int TEMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				DisplayLUMenu(client);
		}
		case MenuAction_Select:
		{
			char info[16];
			if(menu.GetItem(param2, info, sizeof(info)))
				DisplayTELMenu(client, info);
		}
	}
}

public int DisplayTELMenu(int client, char[] sTarget)
{
	char name[MAX_NAME_LENGTH];
	char uid[2][16];
	char uidplus[32];
	Menu menu = new Menu(TELMenuHandler);
	menu.SetTitle("传送到谁那里");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			FormatEx(name, sizeof(name), "%N", i);
			strcopy(uid[0], 12, sTarget);
			FormatEx(uid[1], 12, "%d", GetClientUserId(i));
			ImplodeStrings(uid, 2, "|", uidplus, sizeof(uidplus));
			menu.AddItem(uidplus, name);
		}
	}
	menu.ExitBackButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int TELMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char info[2][16];
			char infoplus[32];
			if(menu.GetItem(param2, infoplus, sizeof(infoplus)))
			{
				ExplodeString(infoplus, "|", info, 2, 16);
				int target = GetClientOfUserId(StringToInt(info[1]));
				float vOrigin[3];
				float vAngles[3];
				GetClientAbsOrigin(target, vOrigin);
				GetClientAbsAngles(target, vAngles);
				if(!strcmp(info[0], "as", true))
				{
					for(int i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
						{
							TeleportCheck(i);
							TeleportEntity(i, vOrigin, vAngles, NULL_VECTOR);
						}
					}
				}
				else if(!strcmp(info[0], "ai", true))
				{
					for(int i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
							TeleportEntity(i, vOrigin, vAngles, NULL_VECTOR);
					}
				}
				else
				{
					int victim = GetClientOfUserId(StringToInt(info[0]));
					TeleportCheck(victim);
					TeleportEntity(victim, vOrigin, vAngles, NULL_VECTOR);
				}
			}
		}
	}
}

stock void TeleportCheck(int client)
{
	if(GetClientTeam(client) != 2)
		return;
	
	if(IsHanging(client))
		L4D2_ReviveFromIncap(client);
	else
		ChargerCheck(client);
}
//https://github.com/LuxLuma/Scuffle
stock void ChargerCheck(int client)
{
	static const char attackTypes[][] = 
	{
		"m_pummelAttacker",
		"m_carryAttacker" 
	};
	for(int i; i < sizeof(attackTypes); i++)
	{
		if(HasEntProp(client, Prop_Send, attackTypes[i]))
		{
			int attackerId = GetEntPropEnt(client, Prop_Send, attackTypes[i]);
			if(attackerId > 0)
			{
				L4D2_Stagger(attackerId);
				return;
			}
		}
	}
}

stock void L4D2_Stagger(int iClient, float fPos[3]=NULL_VECTOR) 
{
    /**
    * Stagger a client (Credit to Timocop)
    *
    * @param iClient    Client to stagger
    * @param fPos       Vector to stagger
    * @return void
    */

    L4D2_RunScript("GetPlayerFromUserID(%d).Stagger(Vector(%d,%d,%d))", GetClientUserId(iClient), RoundFloat(fPos[0]), RoundFloat(fPos[1]), RoundFloat(fPos[2]));
}

//https://forums.alliedmods.net/showpost.php?p=2681159&postcount=10
stock bool IsHanging(int client)
{
	return GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 0;
}

stock void L4D2_ReviveFromIncap(int client) 
{
	L4D2_RunScript("GetPlayerFromUserID(%d).ReviveFromIncap()", GetClientUserId(client));
}

stock void L4D2_RunScript(const char[] sCode, any ...) 
{
	/**
	* Run a VScript (Credit to Timocop)
	*
	* @param sCode		Magic
	* @return void
	*/

	static int iScriptLogic = INVALID_ENT_REFERENCE;
	if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic)) 
	{
		iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));
		if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic)) 
			SetFailState("Could not create 'logic_script'");

		DispatchSpawn(iScriptLogic);
	}

	char sBuffer[512];
	VFormat(sBuffer, sizeof(sBuffer), sCode, 2);
	SetVariantString(sBuffer);
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
}

public int DisplaySLMenu(int client)
{
	char num[4];
	Menu menu = new Menu(SLMenuHandler);
	menu.SetTitle("服务器人数");
	for(int i = 1; i <= 16; i++)
	{
		FormatEx(num, sizeof(num), "%d", i);
		menu.AddItem(num, num);
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int SLMenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				RygiveMenu(client, 0);
		}
		case MenuAction_Select:
		{
			char info[16];
			if(menu.GetItem(param2, info, sizeof(info)))
			{
				int num = StringToInt(info);
				FakeClientCommand(client, "sm_cvar sv_maxplayers %d", num);
				FakeClientCommand(client, "sm_cvar sv_visiblemaxplayers %d", num);
			}
		}
	}
}

void CheatCommand(int client, const char[] sCommand)
{
	if(client == 0 || !IsClientInGame(client))
		return;

	char sCmd[16];
	SplitString(sCommand, " ", sCmd, sizeof(sCmd));
	int bits = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(sCmd);
	SetCommandFlags(sCmd, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, sCommand);
	SetCommandFlags(sCmd, flags);
	SetUserFlagBits(client, bits);
	if(sCommand[0] == 'g' && strcmp(sCommand[5], "health") == 0)
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0); //防止有虚血时give health会超过100血
}