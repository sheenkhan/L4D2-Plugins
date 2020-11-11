/********************************************************************************************
* Plugin	: L4D/L4D2 InfectedBots Control
* Version	: 1.0.0
* Game		: Left 4 Dead 1 & 2
* Author	: djromero (SkyDavid, David) and MI 5
* Testers	: Myself, MI 5
* Website	: www.sky.zebgames.com
* 
* Purpose	: This plugin spawns infected bots in versus for L4D1 and gives greater control of the infected bots in L4D1/L4D2.
* *******************************************************************************************/

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

#define DEBUGSERVER 0  // 改为1查看服务器debug
#define DEBUGCLIENTS 0  // 改为1查看对话框debug
#define DEBUGTANK 0
#define DEBUGHUD 0
#define DEVELOPER 0  // 改为1使用开发者指令

#define TEAM_SPECTATOR		1
#define TEAM_SURVIVORS 		2
#define TEAM_INFECTED 		3

#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6

// Variables
static InfectedRealCount; // Holds the amount of real infected players
static InfectedBotCount; // Holds the amount of infected bots in any gamemode
static InfectedBotQueue; // Holds the amount of bots that are going to spawn

static GameMode; // Holds the GameMode, 1 for coop and realism, 2 for versus, teamversus, scavenge and teamscavenge, 3 for survival

static BoomerLimit; // Sets the Boomer Limit, related to the boomer limit cvar
static SmokerLimit; // Sets the Smoker Limit, related to the smoker limit cvar
static HunterLimit; // Sets the Hunter Limit, related to the hunter limit cvar
static SpitterLimit; // Sets the Spitter Limit, related to the Spitter limit cvar
static JockeyLimit; // Sets the Jockey Limit, related to the Jockey limit cvar
static ChargerLimit; // Sets the Charger Limit, related to the Charger limit cvar

static MaxPlayerZombies; // Holds the amount of the maximum amount of special zombies on the field
static BotReady; // Used to determine how many bots are ready, used only for the coordination feature
static ZOMBIECLASS_TANK; // This value varies depending on which L4D game it is, holds the the tank class value
static GetSpawnTime[MAXPLAYERS+1]; // Used for the HUD on getting spawn times of players
static PlayersInServer;
static InfectedSpawnTimeMax;
static InfectedSpawnTimeMin;
static InitialSpawnInt;
static TankLimit;

// Booleans
static bool:b_HasRoundStarted; // Used to state if the round started or not
static bool:b_HasRoundEnded; // States if the round has ended or not
static bool:b_LeftSaveRoom; // States if the survivors have left the safe room
static bool:canSpawnBoomer; // States if we can spawn a boomer (releated to spawn restrictions)
static bool:canSpawnSmoker; // States if we can spawn a smoker (releated to spawn restrictions)
static bool:canSpawnHunter; // States if we can spawn a hunter (releated to spawn restrictions)
static bool:canSpawnSpitter; // States if we can spawn a spitter (releated to spawn restrictions)
static bool:canSpawnJockey; // States if we can spawn a jockey (releated to spawn restrictions)
static bool:canSpawnCharger; // States if we can spawn a charger (releated to spawn restrictions)
static bool:DirectorSpawn; // Can allow either the director to spawn the infected (normal l4d behavior), or allow the plugin to spawn them
static bool:SpecialHalt; // Loop Breaker, prevents specials spawning, while Director is spawning, from spawning again
//new bool:TankHalt; // Loop Breaker, prevents player tanks from spawning over and over
static bool:PlayerLifeState[MAXPLAYERS+1]; // States whether that player has the lifestate changed from switching the gamemode
static bool:InitialSpawn; // Related to the coordination feature, tells the plugin to let the infected spawn when the survivors leave the safe room
static bool:b_IsL4D2; // Holds the version of L4D; false if its L4D, true if its L4D2
static bool:AlreadyGhosted[MAXPLAYERS+1]; // Loop Breaker, prevents a player from spawning into a ghost over and over again
static bool:AlreadyGhostedBot[MAXPLAYERS+1]; // Prevents bots taking over a player from ghosting
static bool:DirectorCvarsModified; // Prevents reseting the director class limit cvars if the server or admin modifed them
static bool:PlayerHasEnteredStart[MAXPLAYERS+1];
static bool:AdjustSpawnTimes
static bool:Coordination
static bool:DisableSpawnsTank


// Handles
static Handle:h_BoomerLimit; // Related to the Boomer limit cvar
static Handle:h_SmokerLimit; // Related to the Smoker limit cvar
static Handle:h_HunterLimit; // Related to the Hunter limit cvar
static Handle:h_SpitterLimit; // Related to the Spitter limit cvar
static Handle:h_JockeyLimit; // Related to the Jockey limit cvar
static Handle:h_ChargerLimit; // Related to the Charger limit cvar
static Handle:h_MaxPlayerZombies; // Related to the max specials cvar
static Handle:h_InfectedSpawnTimeMax; // Related to the spawn time cvar
static Handle:h_InfectedSpawnTimeMin; // Related to the spawn time cvar
static Handle:h_DirectorSpawn; // yeah you're getting the idea
static Handle:h_GameMode; // uh huh
static Handle:h_Coordination;
static Handle:h_idletime_b4slay;
static Handle:h_InitialSpawn;
static Handle:FightOrDieTimer[MAXPLAYERS+1]; // kill idle bots
static Handle:h_BotGhostTime;
static Handle:h_DisableSpawnsTank;
static Handle:h_TankLimit;
static Handle:h_AdjustSpawnTimes;

static Handle:hOA_AIS;
new Handle:hRIFADDNUMS;
new Handle:hR_AutoIS_T;

int RIFADDNUMS;
int baseNum;
int R_AutoIS_T;

bool OA_AIS;
bool RAScheck;
bool IFADDEnabled;
bool R14Enabled;

new Handle:timer_handle = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[L4D/L4D2] Infected Bots Control",
	author = "djromero (SkyDavid), MI 5",
	description = "This plugin spawns infected bots in versus for L4D1 and gives greater control of the infected bots in L4D1/L4D2.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=893938#post893938"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) 
{
	// Checks to see if the game is a L4D game. If it is, check if its the sequel. L4DVersion is L4D if false, L4D2 if true.
	decl String:GameName[64];
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrContains(GameName, "left4dead", false) == -1)
		return APLRes_Failure; 
	else if (StrEqual(GameName, "left4dead2", false))
		b_IsL4D2 = true;
	
	return APLRes_Success; 
}

public OnPluginStart()
{
	// Tank Class value is different in L4D2
	if (b_IsL4D2)
		ZOMBIECLASS_TANK = 8;
	else
	ZOMBIECLASS_TANK = 5;
	
	// We register the version cvar
	CreateConVar("l4d_infectedbots_version", PLUGIN_VERSION, "Version of L4D Infected Bots", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	h_GameMode = FindConVar("mp_gamemode");
	
	#if DEVELOPER
	RegConsoleCmd("sm_gamemode", CheckGameMode);
	RegConsoleCmd("sm_count2", CheckQueue);
	RegConsoleCmd("sm_tt", Test);
	#endif

	RegConsoleCmd("sm_on14", R14Infectedon, "开启CFG配置特感模式", 0);
	RegConsoleCmd("sm_on142", R14Infectedon2, "开启基础4特,按人数增加特感模式", 0);
	RegConsoleCmd("sm_on141", R14Infectedon3, "开启基础0特,按人数增加特感模式", 0);
	RegConsoleCmd("sm_off14", R14Infectedoff, "关闭多特", 0);
	RegConsoleCmd("sm_addif", IFADDNumsetcheck, "配置每个幸存者增加的特感数", 0);
	RegConsoleCmd("sm_it", IFADDTimecheck, "修改特感生成速度", 0);
	
	// console variables
	hOA_AIS = CreateConVar("Only_Admin", "1", "[0=所有人|1=仅管理员]可使用命令", 0, true, 0.0, true, 1.0);
	hR_AutoIS_T = CreateConVar("R_AutoIS_T", "0", "默认模式;0=关;1=!on14;2=!on141;3=!on142", 0, true, 0.0, true, 3.0);
	hRIFADDNUMS = CreateConVar("l4d2_add_if", "0", "!on141 !on142模式 每加1人加几特感,最多6,!addif更改本参数", 0, true, 1.0, true, 6.0);
	h_BoomerLimit = CreateConVar("l4d_infectedbots_boomer_limit", "1", "设置插件产生boomers的上限", FCVAR_SPONLY);
	h_SmokerLimit = CreateConVar("l4d_infectedbots_smoker_limit", "1", "设置插件产生smokers的上限", FCVAR_SPONLY);
	h_TankLimit = CreateConVar("l4d_infectedbots_tank_limit", "0", "Sets the limit for tanks spawned by the plugin (plugin treats these tanks as another infected bot) (does not affect director tanks)", FCVAR_SPONLY);
	if (b_IsL4D2)
	{
		h_SpitterLimit = CreateConVar("l4d_infectedbots_spitter_limit", "1", "设置插件产生spitters的上限", FCVAR_SPONLY);
		h_JockeyLimit = CreateConVar("l4d_infectedbots_jockey_limit", "2", "设置插件产生jockeys的上限", FCVAR_SPONLY);
		h_ChargerLimit = CreateConVar("l4d_infectedbots_charger_limit", "1", "设置插件产生chargers的上限", FCVAR_SPONLY);
		h_HunterLimit = CreateConVar("l4d_infectedbots_hunter_limit", "2", "设置插件产生hunters的上限", FCVAR_SPONLY);
	}
	else
	{
		h_HunterLimit = CreateConVar("l4d_infectedbots_hunter_limit", "2", "设置插件产生hunters的上限", FCVAR_SPONLY);
	}
	h_MaxPlayerZombies = CreateConVar("l4d_infectedbots_max_specials", "6", "定义在所有游戏模式下地图上可能有多少特殊感染者（这也会影响感染者玩家的上限）", FCVAR_SPONLY); 
	h_InfectedSpawnTimeMax = CreateConVar("l4d_infectedbots_spawn_time_max", "16", "设置插件产生的特殊感染的最大产生时间（以秒为单位）", FCVAR_SPONLY);
	h_InfectedSpawnTimeMin = CreateConVar("l4d_infectedbots_spawn_time_min", "13", "设置插件产生的特殊感染的最短产生时间（以秒为单位）", FCVAR_SPONLY);
	h_DirectorSpawn = CreateConVar("l4d_infectedbots_director_spawn_times", "0", "如果为1，则插件将使用导演模式的计时器；如果游戏为L4D2对抗模式，它将激活Valve的机器人", FCVAR_SPONLY, true, 0.0, true, 1.0);
	h_Coordination = CreateConVar("l4d_infectedbots_coordination", "0", "如果为1，电脑只有在所有其他生成计时器都为零时生成（即一起生成）", FCVAR_SPONLY, true, 0.0, true, 1.0);
	h_idletime_b4slay = CreateConVar("l4d_infectedbots_lifespan", "30", "踢出特殊感染者的秒数（感染者生存周期）", FCVAR_SPONLY);
	h_InitialSpawn = CreateConVar("l4d_infectedbots_initial_spawn_timer", "10", "第一次在地图上生成感染者电脑时的生成计时器秒数", FCVAR_SPONLY);
	h_BotGhostTime = CreateConVar("l4d_infectedbots_ghost_time", "2", "如果大于零，则插件将首先以幽灵形式生成电脑，然后才将它们完全生成在 对抗/清道夫模式 中。", FCVAR_SPONLY);
	h_DisableSpawnsTank = CreateConVar("l4d_infectedbots_spawns_disabled_tank", "0", "如果为1，则当tank在场时，插件会禁用电脑生成", FCVAR_SPONLY, true, 0.0, true, 1.0);
	h_AdjustSpawnTimes = CreateConVar("l4d_infectedbots_adjust_spawn_times", "0", "如果为1，则插件将根据游戏模式调整生成计时器，并根据合作模式中幸存玩家的数量以及对战/清道夫的感染者玩家数量来调整生成计时器", FCVAR_SPONLY, true, 0.0, true, 1.0);
	
	R_AutoIS_T = GetConVarInt(hR_AutoIS_T);
	RIFADDNUMS = GetConVarInt(hRIFADDNUMS);

	HookConVarChange(hOA_AIS, ConVarOA_AIS);
	OA_AIS = GetConVarBool(hOA_AIS);
	HookConVarChange(h_BoomerLimit, ConVarBoomerLimit);
	BoomerLimit = GetConVarInt(h_BoomerLimit);
	HookConVarChange(h_SmokerLimit, ConVarSmokerLimit);
	SmokerLimit = GetConVarInt(h_SmokerLimit);
	HookConVarChange(h_HunterLimit, ConVarHunterLimit);
	HunterLimit = GetConVarInt(h_HunterLimit);
	if (b_IsL4D2)
	{
		HookConVarChange(h_SpitterLimit, ConVarSpitterLimit);
		SpitterLimit = GetConVarInt(h_SpitterLimit);
		HookConVarChange(h_JockeyLimit, ConVarJockeyLimit);
		JockeyLimit = GetConVarInt(h_JockeyLimit);
		HookConVarChange(h_ChargerLimit, ConVarChargerLimit);
		ChargerLimit = GetConVarInt(h_ChargerLimit);
	}
	HookConVarChange(h_MaxPlayerZombies, ConVarMaxPlayerZombies);
	MaxPlayerZombies = GetConVarInt(h_MaxPlayerZombies);
	HookConVarChange(h_DirectorSpawn, ConVarDirectorSpawn);
	DirectorSpawn = GetConVarBool(h_DirectorSpawn);
	HookConVarChange(h_GameMode, ConVarGameMode);
	AdjustSpawnTimes = GetConVarBool(h_AdjustSpawnTimes);
	HookConVarChange(h_AdjustSpawnTimes, ConVarAdjustSpawnTimes);
	Coordination = GetConVarBool(h_Coordination);
	HookConVarChange(h_Coordination, ConVarCoordination);
	DisableSpawnsTank = GetConVarBool(h_DisableSpawnsTank);
	HookConVarChange(h_DisableSpawnsTank, ConVarDisableSpawnsTank);
	HookConVarChange(h_InfectedSpawnTimeMax, ConVarInfectedSpawnTimeMax);
	InfectedSpawnTimeMax = GetConVarInt(h_InfectedSpawnTimeMax);
	HookConVarChange(h_InfectedSpawnTimeMin, ConVarInfectedSpawnTimeMin);
	InfectedSpawnTimeMin = GetConVarInt(h_InfectedSpawnTimeMin);
	HookConVarChange(h_InitialSpawn, ConVarInitialSpawn);
	InitialSpawnInt = GetConVarInt(h_InitialSpawn);
	HookConVarChange(h_TankLimit, ConVarTankLimit);
	TankLimit = GetConVarInt(h_TankLimit);
	
	// If the admin wanted to change the director class limits with director spawning on, the plugin will not reset those cvars to their defaults upon startup.
	
	HookConVarChange(FindConVar("z_hunter_limit"), ConVarDirectorCvarChanged);
	if (!b_IsL4D2)
	{
		HookConVarChange(FindConVar("z_gas_limit"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("z_exploding_limit"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("holdout_max_boomers"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("holdout_max_smokers"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("holdout_max_hunters"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("holdout_max_specials"), ConVarDirectorCvarChanged);
	}
	else
	{
		HookConVarChange(FindConVar("z_smoker_limit"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("z_boomer_limit"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("z_jockey_limit"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("z_spitter_limit"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("z_charger_limit"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("survival_max_boomers"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("survival_max_smokers"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("survival_max_hunters"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("survival_max_jockeys"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("survival_max_spitters"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("survival_max_chargers"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("survival_max_specials"), ConVarDirectorCvarChanged);
	}
	
	HookEvent("round_start", evtRoundStart);
	HookEvent("round_end", evtRoundEnd, EventHookMode_Pre);
	// We hook some events ...
	HookEvent("player_death", evtPlayerDeath, EventHookMode_Pre);
	HookEvent("player_team", evtPlayerTeam);
	HookEvent("player_spawn", evtPlayerSpawn);
	HookEvent("create_panic_event", evtSurvivalStart);
	HookEvent("finale_start", evtFinaleStart);
	HookEvent("player_bot_replace", evtBotReplacedPlayer);
	HookEvent("player_first_spawn", evtPlayerFirstSpawned);
	HookEvent("player_entered_start_area", evtPlayerFirstSpawned);
	HookEvent("player_entered_checkpoint", evtPlayerFirstSpawned);
	HookEvent("player_transitioned", evtPlayerFirstSpawned);
	HookEvent("player_left_start_area", evtPlayerFirstSpawned);
	HookEvent("player_left_checkpoint", evtPlayerFirstSpawned);
	
	//Autoconfig for plugin
	AutoExecConfig(true, "l4dinfectedbots");

	RAScheck = false;
}

public Action:Test(client, args)
{
	PrintToChatAll("初次启动设定:\x04\x04%d\x01\x01, 最小重生时间:\x04%d\x01, 最大重生时间:\x04%d\x01, 特感总数:\x04%d\x01",RAScheck,InfectedSpawnTimeMin,InfectedSpawnTimeMax,MaxPlayerZombies);
	PrintToChatAll("每人增加特感数:\x04%d\x01, 基础特感数:\x04%d\x01, 是否开启自动增加:\x04%d\x01, 是否开启多特:\x04%d\x01",RIFADDNUMS,baseNum,IFADDEnabled,R14Enabled);
	PrintToServer("初次启动设定:%d, 最小重生时间:%d, 最大重生时间:%d, 特感总数:%d",RAScheck,InfectedSpawnTimeMin,InfectedSpawnTimeMax,MaxPlayerZombies);
	PrintToServer("每人增加特感数:%d, 基础特感数:%d, 是否开启自动增加:%d, 是否开启多特:%d",RIFADDNUMS,baseNum,IFADDEnabled,R14Enabled);
}

public ConVarOA_AIS(Handle:convar, const String:oldValue[], const String:newValue[])
{
	OA_AIS = GetConVarBool(hOA_AIS);
}
public ConVarBoomerLimit(Handle:convar, const String:oldValue[], const String:newValue[])
{
	BoomerLimit = GetConVarInt(h_BoomerLimit);
}
public ConVarSmokerLimit(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SmokerLimit = GetConVarInt(h_SmokerLimit);
}

public ConVarHunterLimit(Handle:convar, const String:oldValue[], const String:newValue[])
{
	HunterLimit = GetConVarInt(h_HunterLimit);
}

public ConVarSpitterLimit(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SpitterLimit = GetConVarInt(h_SpitterLimit);
}

public ConVarJockeyLimit(Handle:convar, const String:oldValue[], const String:newValue[])
{
	JockeyLimit = GetConVarInt(h_JockeyLimit);
}

public ConVarChargerLimit(Handle:convar, const String:oldValue[], const String:newValue[])
{
	ChargerLimit = GetConVarInt(h_ChargerLimit);
}

public ConVarInfectedSpawnTimeMax(Handle:convar, const String:oldValue[], const String:newValue[])
{
	InfectedSpawnTimeMax = GetConVarInt(h_InfectedSpawnTimeMax);
}

public ConVarInfectedSpawnTimeMin(Handle:convar, const String:oldValue[], const String:newValue[])
{
	InfectedSpawnTimeMin = GetConVarInt(h_InfectedSpawnTimeMin);
}

public ConVarInitialSpawn(Handle:convar, const String:oldValue[], const String:newValue[])
{
	InitialSpawnInt = GetConVarInt(h_InitialSpawn);
}

public ConVarTankLimit(Handle:convar, const String:oldValue[], const String:newValue[])
{
	TankLimit = GetConVarInt(h_TankLimit);
}

public ConVarDirectorCvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	DirectorCvarsModified = true;
}

public ConVarAdjustSpawnTimes(Handle:convar, const String:oldValue[], const String:newValue[])
{
	AdjustSpawnTimes = GetConVarBool(h_AdjustSpawnTimes);
}

public ConVarCoordination(Handle:convar, const String:oldValue[], const String:newValue[])
{
	Coordination = GetConVarBool(h_Coordination);
}

public ConVarDisableSpawnsTank(Handle:convar, const String:oldValue[], const String:newValue[])
{
	DisableSpawnsTank = GetConVarBool(h_DisableSpawnsTank);
}

public ConVarMaxPlayerZombies(Handle:convar, const String:oldValue[], const String:newValue[])
{
	MaxPlayerZombies = GetConVarInt(h_MaxPlayerZombies);
	CreateTimer(0.1, MaxSpecialsSet);
}

public ConVarDirectorSpawn(Handle:convar, const String:oldValue[], const String:newValue[])
{
	DirectorSpawn = GetConVarBool(h_DirectorSpawn);
	if (!DirectorSpawn)
	{
		//ResetCvars();
		TweakSettings();
		CheckIfBotsNeeded(true, false);
	}
	else
	{
		//ResetCvarsDirector();
		DirectorStuff();
	}
}

public ConVarGameMode(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GameModeCheck();
	
	if (!DirectorSpawn)
	{
		//ResetCvars();
		TweakSettings();
	}
	else
	{
		//ResetCvarsDirector();
		DirectorStuff();
	}
}

TweakSettings()
{
	// We tweak some settings ...
	
	// Some interesting things about this. There was a bug I discovered that in versions 1.7.8 and below, infected players would not spawn as ghosts in VERSUS. This was
	// due to the fact that the coop class limits were not being reset (I didn't think they were linked at all, but I should have known better). This bug has been fixed
	// with the coop class limits being reset on every gamemode except coop of course.
	
	// Reset the cvars
	ResetCvars();
	
	switch (GameMode)
	{
		case 1: // Coop, We turn off the ability for the director to spawn the bots, and have the plugin do it while allowing the director to spawn tanks and witches, 
		// MI 5
		{
			// If the game is L4D 2...
			if (b_IsL4D2)
			{
				SetConVarInt(FindConVar("z_smoker_limit"), 0);
				SetConVarInt(FindConVar("z_boomer_limit"), 0);
				SetConVarInt(FindConVar("z_hunter_limit"), 0);
				SetConVarInt(FindConVar("z_spitter_limit"), 0);
				SetConVarInt(FindConVar("z_jockey_limit"), 0);
				SetConVarInt(FindConVar("z_charger_limit"), 0);
			}
			else
			{
				SetConVarInt(FindConVar("z_gas_limit"), 0);
				SetConVarInt(FindConVar("z_exploding_limit"), 0);
				SetConVarInt(FindConVar("z_hunter_limit"), 0);
			}
		}
		case 2: // Versus, Better Versus Infected Bot AI
		{
			// If the game is L4D 2...
			if (b_IsL4D2)
			{
				SetConVarInt(FindConVar("z_smoker_limit"), 0);
				SetConVarInt(FindConVar("z_boomer_limit"), 0);
				SetConVarInt(FindConVar("z_hunter_limit"), 0);
				SetConVarInt(FindConVar("z_spitter_limit"), 0);
				SetConVarInt(FindConVar("z_jockey_limit"), 0);
				SetConVarInt(FindConVar("z_charger_limit"), 0);
				SetConVarInt(FindConVar("z_jockey_leap_time"), 0);
				SetConVarInt(FindConVar("z_spitter_max_wait_time"), 0);
			}
			else
			{
				SetConVarInt(FindConVar("z_gas_limit"), 999);
				SetConVarInt(FindConVar("z_exploding_limit"), 999);
				SetConVarInt(FindConVar("z_hunter_limit"), 999);
			}
			// Enhance Special Infected AI
			SetConVarFloat(FindConVar("smoker_tongue_delay"), 0.0);
			SetConVarFloat(FindConVar("boomer_vomit_delay"), 0.0);
			SetConVarFloat(FindConVar("boomer_exposed_time_tolerance"), 0.0);
			SetConVarInt(FindConVar("hunter_leap_away_give_up_range"), 0);
			SetConVarInt(FindConVar("z_hunter_lunge_distance"), 5000);
			SetConVarInt(FindConVar("hunter_pounce_ready_range"), 1500);
			SetConVarFloat(FindConVar("hunter_pounce_loft_rate"), 0.055);
			SetConVarFloat(FindConVar("z_hunter_lunge_stagger_time"), 0.0);
		}
		case 3: // Survival, Turns off the ability for the director to spawn infected bots in survival, MI 5
		{
			if (b_IsL4D2)
			{
				SetConVarInt(FindConVar("survival_max_smokers"), 0);
				SetConVarInt(FindConVar("survival_max_boomers"), 0);
				SetConVarInt(FindConVar("survival_max_hunters"), 0);
				SetConVarInt(FindConVar("survival_max_spitters"), 0);
				SetConVarInt(FindConVar("survival_max_jockeys"), 0);
				SetConVarInt(FindConVar("survival_max_chargers"), 0);
				SetConVarInt(FindConVar("survival_max_specials"), MaxPlayerZombies);
				SetConVarInt(FindConVar("z_smoker_limit"), 0);
				SetConVarInt(FindConVar("z_boomer_limit"), 0);
				SetConVarInt(FindConVar("z_hunter_limit"), 0);
				SetConVarInt(FindConVar("z_spitter_limit"), 0);
				SetConVarInt(FindConVar("z_jockey_limit"), 0);
				SetConVarInt(FindConVar("z_charger_limit"), 0);
			}
			else
			{
				SetConVarInt(FindConVar("holdout_max_smokers"), 0);
				SetConVarInt(FindConVar("holdout_max_boomers"), 0);
				SetConVarInt(FindConVar("holdout_max_hunters"), 0);
				SetConVarInt(FindConVar("holdout_max_specials"), MaxPlayerZombies);
				SetConVarInt(FindConVar("z_gas_limit"), 0);
				SetConVarInt(FindConVar("z_exploding_limit"), 0);
				SetConVarInt(FindConVar("z_hunter_limit"), 0);
			}
		}
	}
	
	//Some cvar tweaks
	SetConVarInt(FindConVar("z_attack_flow_range"), 50000);
	SetConVarInt(FindConVar("director_spectate_specials"), 1);
	SetConVarInt(FindConVar("z_spawn_safety_range"), 0);
	SetConVarInt(FindConVar("z_spawn_flow_limit"), 50000);
	DirectorCvarsModified = false;
	if (b_IsL4D2)
	{
		// Prevents the Director from spawning bots in versus
		SetConVarInt(FindConVar("versus_special_respawn_interval"), 99999999);
	}
	#if DEBUGSERVER
	LogMessage("调整设置");
	#endif
}

ResetCvars()
{
	#if DEBUGSERVER
	LogMessage("插件参数重置");
	#endif
	if (GameMode == 1)
	{
		ResetConVar(FindConVar("director_no_specials"), true, true);
		ResetConVar(FindConVar("boomer_vomit_delay"), true, true);
		ResetConVar(FindConVar("smoker_tongue_delay"), true, true);
		ResetConVar(FindConVar("hunter_leap_away_give_up_range"), true, true);
		ResetConVar(FindConVar("boomer_exposed_time_tolerance"), true, true);
		ResetConVar(FindConVar("z_hunter_lunge_distance"), true, true);
		ResetConVar(FindConVar("hunter_pounce_ready_range"), true, true);
		ResetConVar(FindConVar("hunter_pounce_loft_rate"), true, true);
		ResetConVar(FindConVar("z_hunter_lunge_stagger_time"), true, true);
		if (b_IsL4D2)
		{
			ResetConVar(FindConVar("survival_max_smokers"), true, true);
			ResetConVar(FindConVar("survival_max_boomers"), true, true);
			ResetConVar(FindConVar("survival_max_hunters"), true, true);
			ResetConVar(FindConVar("survival_max_spitters"), true, true);
			ResetConVar(FindConVar("survival_max_jockeys"), true, true);
			ResetConVar(FindConVar("survival_max_chargers"), true, true);
			ResetConVar(FindConVar("survival_max_specials"), true, true);
			ResetConVar(FindConVar("z_jockey_leap_time"), true, true);
			ResetConVar(FindConVar("z_spitter_max_wait_time"), true, true);
		}
		else
		{
			ResetConVar(FindConVar("holdout_max_smokers"), true, true);
			ResetConVar(FindConVar("holdout_max_boomers"), true, true);
			ResetConVar(FindConVar("holdout_max_hunters"), true, true);
			ResetConVar(FindConVar("holdout_max_specials"), true, true);
		}
	}
	else if (GameMode == 2)
	{
		if (b_IsL4D2)
		{
			ResetConVar(FindConVar("survival_max_smokers"), true, true);
			ResetConVar(FindConVar("survival_max_boomers"), true, true);
			ResetConVar(FindConVar("survival_max_hunters"), true, true);
			ResetConVar(FindConVar("survival_max_spitters"), true, true);
			ResetConVar(FindConVar("survival_max_jockeys"), true, true);
			ResetConVar(FindConVar("survival_max_chargers"), true, true);
			ResetConVar(FindConVar("survival_max_specials"), true, true);
		}
		else
		{
			ResetConVar(FindConVar("holdout_max_smokers"), true, true);
			ResetConVar(FindConVar("holdout_max_boomers"), true, true);
			ResetConVar(FindConVar("holdout_max_hunters"), true, true);
			ResetConVar(FindConVar("holdout_max_specials"), true, true);
		}
	}
	else if (GameMode == 3)
	{
		ResetConVar(FindConVar("z_hunter_limit"), true, true);
		if (b_IsL4D2)
		{
			ResetConVar(FindConVar("z_smoker_limit"), true, true);
			ResetConVar(FindConVar("z_boomer_limit"), true, true);
			ResetConVar(FindConVar("z_hunter_limit"), true, true);
			ResetConVar(FindConVar("z_spitter_limit"), true, true);
			ResetConVar(FindConVar("z_jockey_limit"), true, true);
			ResetConVar(FindConVar("z_charger_limit"), true, true);
			ResetConVar(FindConVar("z_jockey_leap_time"), true, true);
			ResetConVar(FindConVar("z_spitter_max_wait_time"), true, true);
		}
		else
		{
			ResetConVar(FindConVar("z_gas_limit"), true, true);
			ResetConVar(FindConVar("z_exploding_limit"), true, true);
		}
		ResetConVar(FindConVar("boomer_vomit_delay"), true, true);
		ResetConVar(FindConVar("director_no_specials"), true, true);
		ResetConVar(FindConVar("smoker_tongue_delay"), true, true);
		ResetConVar(FindConVar("hunter_leap_away_give_up_range"), true, true);
		ResetConVar(FindConVar("boomer_exposed_time_tolerance"), true, true);
		ResetConVar(FindConVar("z_hunter_lunge_distance"), true, true);
		ResetConVar(FindConVar("hunter_pounce_ready_range"), true, true);
		ResetConVar(FindConVar("hunter_pounce_loft_rate"), true, true);
		ResetConVar(FindConVar("z_hunter_lunge_stagger_time"), true, true);
	}
}

ResetCvarsDirector()
{
	#if DEBUGSERVER
	LogMessage("导演模式参数重置");
	#endif
	if (GameMode != 2)
	{
		if (b_IsL4D2)
		{
			ResetConVar(FindConVar("z_smoker_limit"), true, true);
			ResetConVar(FindConVar("z_boomer_limit"), true, true);
			ResetConVar(FindConVar("z_hunter_limit"), true, true);
			ResetConVar(FindConVar("z_spitter_limit"), true, true);
			ResetConVar(FindConVar("z_jockey_limit"), true, true);
			ResetConVar(FindConVar("z_charger_limit"), true, true);
			ResetConVar(FindConVar("survival_max_smokers"), true, true);
			ResetConVar(FindConVar("survival_max_boomers"), true, true);
			ResetConVar(FindConVar("survival_max_hunters"), true, true);
			ResetConVar(FindConVar("survival_max_spitters"), true, true);
			ResetConVar(FindConVar("survival_max_jockeys"), true, true);
			ResetConVar(FindConVar("survival_max_chargers"), true, true);
			ResetConVar(FindConVar("survival_max_specials"), true, true);
		}
		else
		{
			ResetConVar(FindConVar("z_hunter_limit"), true, true);
			ResetConVar(FindConVar("z_exploding_limit"), true, true);
			ResetConVar(FindConVar("z_gas_limit"), true, true);
			ResetConVar(FindConVar("holdout_max_smokers"), true, true);
			ResetConVar(FindConVar("holdout_max_boomers"), true, true);
			ResetConVar(FindConVar("holdout_max_hunters"), true, true);
			ResetConVar(FindConVar("holdout_max_specials"), true, true);
		}
	}
	else
	{
		if (b_IsL4D2)
		{
			//ResetConVar(FindConVar("z_smoker_limit"), true, true);
			SetConVarInt(FindConVar("z_smoker_limit"), 2);
			ResetConVar(FindConVar("z_boomer_limit"), true, true);
			//ResetConVar(FindConVar("z_hunter_limit"), true, true);
			SetConVarInt(FindConVar("z_hunter_limit"), 2);
			ResetConVar(FindConVar("z_spitter_limit"), true, true);
			ResetConVar(FindConVar("z_jockey_limit"), true, true);
			ResetConVar(FindConVar("z_charger_limit"), true, true);
		}
		else
		{
			ResetConVar(FindConVar("z_hunter_limit"), true, true);
			ResetConVar(FindConVar("z_exploding_limit"), true, true);
			ResetConVar(FindConVar("z_gas_limit"), true, true);
		}
	}
}

public Action:evtRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// If round has started ...
	if (b_HasRoundStarted)
		return;
	
	b_LeftSaveRoom = false;
	b_HasRoundEnded = false;
	b_HasRoundStarted = true;
	
	//Check the GameMode
	GameModeCheck();
	
	if (GameMode == 0)
		return;
	
	#if DEBUGCLIENTS
	PrintToChatAll("回合开始");
	#endif
	#if DEBUGSERVER
	LogMessage("回合开始");
	#endif
	
	// Removes the boundaries for z_max_player_zombies and notify flag
	new flags = GetConVarFlags(FindConVar("z_max_player_zombies"));
	SetConVarBounds(FindConVar("z_max_player_zombies"), ConVarBound_Upper, false);
	SetConVarFlags(FindConVar("z_max_player_zombies"), flags & ~FCVAR_NOTIFY);
	
	// Added a delay to setting MaxSpecials so that it would set correctly when the server first starts up
	CreateTimer(0.4, MaxSpecialsSet);
	
	//reset some variables
	InfectedBotQueue = 0;
	BotReady = 0;
	SpecialHalt = false;
	InitialSpawn = false;
	
	// Start up TweakSettings or Director Stuff
	if (!DirectorSpawn)
		TweakSettings();
	else
		DirectorStuff();
	
	if (GameMode != 3)
	{
		#if DEBUGSERVER
		LogMessage("开始 合作/对抗 玩家离开出生点计时器");
		#endif
		CreateTimer(1.0, PlayerLeftStart, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:evtPlayerFirstSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	// This event's purpose is to execute when a player first enters the server. This eliminates a lot of problems when changing variables setting timers on clients.
	
	if (b_HasRoundEnded)
		return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!client)
		return;
	
	if (IsFakeClient(client))
		return;
	
	// If player has already entered the start area, don't go into this
	if (PlayerHasEnteredStart[client])
		return;
	
	#if DEBUGCLIENTS
	PrintToChatAll("玩家第一次生成");
	#endif
	
	
	AlreadyGhosted[client] = false;
	PlayerHasEnteredStart[client] = true;
	
}

GameModeCheck()
{
	#if DEBUGSERVER
	LogMessage("检查游戏模式");
	#endif
	// We determine what the gamemode is
	decl String:GameName[16];
	GetConVarString(h_GameMode, GameName, sizeof(GameName));
	if (StrEqual(GameName, "survival", false))
		GameMode = 3;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false) || StrEqual(GameName, "mutation12", false) || StrEqual(GameName, "mutation13", false) || StrEqual(GameName, "mutation15", false) || StrEqual(GameName, "mutation11", false))
		GameMode = 2;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false) || StrEqual(GameName, "mutation3", false) || StrEqual(GameName, "mutation9", false) || StrEqual(GameName, "mutation1", false) || StrEqual(GameName, "mutation7", false) || StrEqual(GameName, "mutation10", false) || StrEqual(GameName, "mutation2", false) || StrEqual(GameName, "mutation4", false) || StrEqual(GameName, "mutation5", false) || StrEqual(GameName, "mutation14", false))
		GameMode = 1;
	else
	GameMode = 1;
}

public Action:MaxSpecialsSet(Handle:Timer)
{
	SetConVarInt(FindConVar("z_max_player_zombies"), MaxPlayerZombies);
	#if DEBUGSERVER
	LogMessage("僵尸最大玩家数设置");
	#endif
}

DirectorStuff()
{	
	SpecialHalt = false;
	SetConVarInt(FindConVar("z_spawn_safety_range"), 0);
	SetConVarInt(FindConVar("director_spectate_specials"), 1);
	if (b_IsL4D2)
		ResetConVar(FindConVar("versus_special_respawn_interval"), true, true);
	
	// if the server changes the director spawn limits in any way, don't reset the cvars
	if (!DirectorCvarsModified)
		ResetCvarsDirector();
	
	#if DEBUGSERVER
	LogMessage("导演模式stuff设置");
	#endif
	
}

public Action:evtRoundEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	// If round has not been reported as ended ..
	if (!b_HasRoundEnded)
	{
		// we mark the round as ended
		b_HasRoundEnded = true;
		b_HasRoundStarted = false;
		b_LeftSaveRoom = false;
		
		for (new i = 1; i <= MaxClients; i++)
		{
			PlayerHasEnteredStart[i] = false;
			if (FightOrDieTimer[i] != INVALID_HANDLE)
			{
				KillTimer(FightOrDieTimer[i]);
				FightOrDieTimer[i] = INVALID_HANDLE;
			}
		}
		
		#if DEBUGCLIENTS
		PrintToChatAll("回合结束");
		#endif
		#if DEBUGSERVER
		LogMessage("回合结束");
		#endif
	}
	
}

public OnMapStart()
{
	OA_AIS = GetConVarBool(hOA_AIS);
	if (!RAScheck)
	{
		R_AutoIS_T = GetConVarInt(hR_AutoIS_T);
		if (R_AutoIS_T < 0 || R_AutoIS_T > 3)
		{
			R_AutoIS_T = 0;
		}
		if (R_AutoIS_T == 1)
		{
			Rs14Infectedon();
		}
		if (R_AutoIS_T == 2)
		{
			Rs14Infectedon2();
		}
		if (R_AutoIS_T == 3)
		{
			Rs14Infectedon3();
		}
		RAScheck = true;
	}
}

public OnMapEnd()
{
	#if DEBUGSERVER
	LogMessage("地图结束");
	#endif
	
	b_HasRoundStarted = false;
	b_HasRoundEnded = true;
	b_LeftSaveRoom = false;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (FightOrDieTimer[i] != INVALID_HANDLE)
		{
			KillTimer(FightOrDieTimer[i]);
			FightOrDieTimer[i] = INVALID_HANDLE;
		}
	}
}

public Action:PlayerLeftStart(Handle:Timer)
{
	if (LeftStartArea())
	{	
		// We don't care who left, just that at least one did
		if (!b_LeftSaveRoom)
		{
			decl String:GameName[16];
			GetConVarString(h_GameMode, GameName, sizeof(GameName));
			if (StrEqual(GameName, "mutation15", false))
			{
				SetConVarInt(FindConVar("survival_max_smokers"), 0);
				SetConVarInt(FindConVar("survival_max_boomers"), 0);
				SetConVarInt(FindConVar("survival_max_hunters"), 0);
				SetConVarInt(FindConVar("survival_max_jockeys"), 0);
				SetConVarInt(FindConVar("survival_max_spitters"), 0);
				SetConVarInt(FindConVar("survival_max_chargers"), 0);
				return Plugin_Continue; 
			}
			
			#if DEBUGSERVER
			LogMessage("一个玩家离开了出生点，生成电脑");
			#endif
			#if DEBUGCLIENTS
			PrintToChatAll("一个玩家离开了出生点，生成电脑");
			#endif
			b_LeftSaveRoom = true;
			
			
			
			
			// We reset some settings
			canSpawnBoomer = true;
			canSpawnSmoker = true;
			canSpawnHunter = true;
			if (b_IsL4D2)
			{
				canSpawnSpitter = true;
				canSpawnJockey = true;
				canSpawnCharger = true;
			}
			InitialSpawn = true;
			
			// We check if we need to spawn bots
			CheckIfBotsNeeded(false, true);
			#if DEBUGSERVER
			LogMessage("检查是否需要电脑");
			#endif
			CreateTimer(3.0, InitialSpawnReset, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else
	{
		CreateTimer(1.0, PlayerLeftStart, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

// This is hooked to the panic event, but only starts if its survival. This is what starts up the bots in survival.

public Action:evtSurvivalStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GameMode == 3)
	{  
		// We don't care who left, just that at least one did
		if (!b_LeftSaveRoom)
		{
			#if DEBUGSERVER
			LogMessage("一个玩家触发了生还者时间，生成电脑");
			#endif
			#if DEBUGCLIENTS
			PrintToChatAll("一个玩家触发了生还者时间，生成电脑");
			#endif
			b_LeftSaveRoom = true;
			
			// We reset some settings
			canSpawnBoomer = true;
			canSpawnSmoker = true;
			canSpawnHunter = true;
			if (b_IsL4D2)
			{
				canSpawnSpitter = true;
				canSpawnJockey = true;
				canSpawnCharger = true;
			}
			InitialSpawn = true;
			
			// We check if we need to spawn bots
			CheckIfBotsNeeded(false, true);
			#if DEBUGSERVER
			LogMessage("检查是否需要电脑");
			#endif
			CreateTimer(3.0, InitialSpawnReset, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

public Action:InitialSpawnReset(Handle:Timer)
{
	InitialSpawn = false;
}

public Action:BotReadyReset(Handle:Timer)
{
	BotReady = 0;
}

public Action:InfectedBotBooterVersus(Handle:Timer)
{
	//This is to check if there are any extra bots and boot them if necessary, excluding tanks, versus only
	if (GameMode != 2 || b_IsL4D2)
		return;
	
	// current count ...
	new total;
	
	for (new i=1; i<=MaxClients; i++)
	{
		// if player is ingame ...
		if (IsClientInGame(i))
		{
			// if player is on infected's team
			if (GetClientTeam(i) == TEAM_INFECTED)
			{
				// We count depending on class ...
				if (!IsPlayerTank(i) || (IsPlayerTank(i) && !PlayerIsAlive(i)))
				{
					total++;
				}
			}
		}
	}
	if (total + InfectedBotQueue > MaxPlayerZombies)
	{
		new kick = total + InfectedBotQueue - MaxPlayerZombies; 
		new kicked = 0;
		
		// We kick any extra bots ....
		for (new i=1;(i<=MaxClients)&&(kicked < kick);i++)
		{
			// If player is infected and is a bot ...
			if (IsClientInGame(i) && IsFakeClient(i))
			{
				//  If bot is on infected ...
				if (GetClientTeam(i) == TEAM_INFECTED)
				{
					// If player is not a tank
					if (!IsPlayerTank(i) || ((IsPlayerTank(i) && !PlayerIsAlive(i))))
					{
						// timer to kick bot
						CreateTimer(0.1,kickbot,i);
						
						// increment kicked count ..
						kicked++;
						#if DEBUGSERVER
						LogMessage("踢出一个电脑因为超过了玩家上限");
						#endif
					}
				}
			}
		}
	}
	
}

public OnClientPutInServer(client)
{
	// If is a bot, skip this function
	if (IsFakeClient(client))
		return;
	
	if (R14Enabled && IFADDEnabled)
	{
		CreateTimer(3.0, ADDIFNUMCHECKSD, any:2, 0);
	}
	
	PlayersInServer++;
	
	#if DEBUGSERVER
	LogMessage("OnClientPutInServer 已经开始");
	#endif
}

public Action:CheckGameMode(client, args)
{
	if (client)
	{
		PrintToChat(client, "GameMode = %i", GameMode);
	}
}

public Action:CheckQueue(client, args)
{
	if (client)
	{
		CountInfected();
		
		PrintToChat(client, "InfectedBotQueue = %i, InfectedBotCount = %i, InfectedRealCount = %i", InfectedBotQueue, InfectedBotCount, InfectedRealCount);
	}
}

public Action:evtPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// We get the client id and time
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	// If client is valid
	if (!client || !IsClientInGame(client)) return Plugin_Continue;
	
	if (GetClientTeam(client) != TEAM_INFECTED)
		return Plugin_Continue;
	
	if (DirectorSpawn && GameMode != 2)
	{
		if (IsPlayerSmoker(client))
		{
			if (IsFakeClient(client))
			{
				if (!SpecialHalt)
				{
					CreateTimer(0.1, kickbot, client);
					
					#if DEBUGSERVER
					LogMessage("Smoker 踢出");
					#endif
					
					new BotNeeded = 1;
					
					CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded);
					
					
					#if DEBUGSERVER
					LogMessage("生成 Smoker");
					#endif
				}
			}
		}
		else if (IsPlayerBoomer(client))
		{
			if (IsFakeClient(client))
			{
				if (!SpecialHalt)
				{
					CreateTimer(0.1, kickbot, client);
					
					#if DEBUGSERVER
					LogMessage("Boomer 踢出");
					#endif
					
					new BotNeeded = 2;
					CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded);
					
					
					#if DEBUGSERVER
					LogMessage("生成 Booomer");
					#endif
				}
			}
		}
		else if (IsPlayerHunter(client))
		{
			if (IsFakeClient(client))
			{
				if (!SpecialHalt)
				{
					CreateTimer(0.1, kickbot, client);
					
					#if DEBUGSERVER
					LogMessage("Hunter 踢出");
					#endif
					
					new BotNeeded = 3;
					
					CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded);
					
					
					#if DEBUGSERVER
					LogMessage("Hunter 生成");
					#endif
				}
			}
		}
		else if (IsPlayerSpitter(client) && b_IsL4D2)
		{
			if (IsFakeClient(client))
			{
				if (!SpecialHalt)
				{
					CreateTimer(0.1, kickbot, client);
					
					#if DEBUGSERVER
					LogMessage("Spitter 踢出");
					#endif
					
					new BotNeeded = 4;
					
					CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded);
					
					
					#if DEBUGSERVER
					LogMessage("Spitter 生成");
					#endif
				}
			}
		}
		else if (IsPlayerJockey(client) && b_IsL4D2)
		{
			if (IsFakeClient(client))
			{
				if (!SpecialHalt)
				{
					CreateTimer(0.1, kickbot, client);
					
					#if DEBUGSERVER
					LogMessage("Jockey 踢出");
					#endif
					
					new BotNeeded = 5;
					
					CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded);
					
					
					#if DEBUGSERVER
					LogMessage("Jockey 生成");
					#endif
				}
			}
		}
		else if (IsPlayerCharger(client) && b_IsL4D2)
		{
			if (IsFakeClient(client))
			{
				if (!SpecialHalt)
				{
					CreateTimer(0.1, kickbot, client);
					
					#if DEBUGSERVER
					LogMessage("Charger 踢出");
					#endif
					
					new BotNeeded = 6;
					
					CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded);
					
					
					#if DEBUGSERVER
					LogMessage("Charger 生成");
					#endif
				}
			}
		}
	}
	
	if (!IsPlayerTank(client) && IsFakeClient(client))
	{
		if (FightOrDieTimer[client] != INVALID_HANDLE)
		{
			KillTimer(FightOrDieTimer[client]);
			FightOrDieTimer[client] = INVALID_HANDLE;
		}
		FightOrDieTimer[client] = CreateTimer(GetConVarFloat(h_idletime_b4slay), DisposeOfCowards, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	// If its Versus and the bot is not a tank, make the bot into a ghost
	if (IsFakeClient(client) && GameMode == 2 && !IsPlayerTank(client))
		CreateTimer(0.1, Timer_SetUpBotGhost, client, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Action:evtBotReplacedPlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	// The purpose of using this event, is to prevent a bot from ghosting after the player leaves or joins another team
	
	new bot = GetClientOfUserId(GetEventInt(event, "bot"));
	AlreadyGhostedBot[bot] = true;
}

public Action:DisposeOfCowards(Handle:timer, any:coward)
{
	if (IsClientInGame(coward) && IsFakeClient(coward) && GetClientTeam(coward) == TEAM_INFECTED && !IsPlayerTank(coward) && PlayerIsAlive(coward))
	{
		// Check to see if the infected thats about to be slain sees the survivors. If so, kill the timer and make a new one.
		new threats = GetEntProp(coward, Prop_Send, "m_hasVisibleThreats");
		
		if (threats)
		{
			FightOrDieTimer[coward] = INVALID_HANDLE;
			FightOrDieTimer[coward] = CreateTimer(GetConVarFloat(h_idletime_b4slay), DisposeOfCowards, coward);
			#if DEBUGCLIENTS
			PrintToChatAll("%N 在计时器启动后看到幸存者，创建新计时器", coward);
			#endif
			return;
		}
		else
		{
			CreateTimer(0.1, kickbot, coward);
			if (!DirectorSpawn)
			{
				new SpawnTime = GetURandomIntRange(InfectedSpawnTimeMin, InfectedSpawnTimeMax);
				
				if (GameMode == 2 && AdjustSpawnTimes && MaxPlayerZombies != HumansOnInfected())
					SpawnTime = SpawnTime / (MaxPlayerZombies - HumansOnInfected());
				else if (GameMode == 1 && AdjustSpawnTimes)
					SpawnTime = SpawnTime - TrueNumberOfSurvivors();
				
				CreateTimer(float(SpawnTime), Spawn_InfectedBot, _, 0);
				InfectedBotQueue++;
				
				#if DEBUGCLIENTS
				PrintToChatAll("踢出电脑 %N 由于没有进行攻击", coward);
				PrintToChatAll("由于生存周期计时器超时，已将感染者电脑添加到生成队列中");
				#endif
			}
		}
	}
	FightOrDieTimer[coward] = INVALID_HANDLE;
}

public Action:Timer_SetUpBotGhost(Handle:timer, any:client)
{
	// This will set the bot a ghost, stop the bot's movement, and waits until it can spawn
	if (IsValidEntity(client))
	{
		if (!AlreadyGhostedBot[client])
		{
			SetGhostStatus(client, true);
			SetEntityMoveType(client, MOVETYPE_NONE);
			CreateTimer(GetConVarFloat(h_BotGhostTime), Timer_RestoreBotGhost, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		AlreadyGhostedBot[client] = false;
	}
}

public Action:Timer_RestoreBotGhost(Handle:timer, any:client)
{
	if (IsValidEntity(client))
	{
		SetGhostStatus(client, false);
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
}

public Action:evtPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// If round has ended .. we ignore this
	if (b_HasRoundEnded || !b_LeftSaveRoom) return Plugin_Continue;
	
	// We get the client id and time
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (FightOrDieTimer[client] != INVALID_HANDLE)
	{
		KillTimer(FightOrDieTimer[client]);
		FightOrDieTimer[client] = INVALID_HANDLE;
	}
	
	
	if (!client || !IsClientInGame(client)) return Plugin_Continue;
	
	if (GetClientTeam(client) !=TEAM_INFECTED) return Plugin_Continue;
	
	/*
	if (!DirectorSpawn)
	{
	if (L4DVersion)
	{
	if (IsPlayerBoomer(client))
	{
	canSpawnBoomer = false;
	CreateTimer(float(GetConVarInt(h_InfectedSpawnTimeMin)), ResetSpawnRestriction, 3);
	#if DEBUGSERVER
	LogMessage("Boomer died, setting spawn restrictions");
	#endif
	}
	else if (IsPlayerSmoker(client))
	{
	canSpawnSmoker = false;
	CreateTimer(float(GetConVarInt(h_InfectedSpawnTimeMin)), ResetSpawnRestriction, 2);
	}
	else if (IsPlayerHunter(client))
	{
	canSpawnHunter = false;
	CreateTimer(float(GetConVarInt(h_InfectedSpawnTimeMin)), ResetSpawnRestriction, 1);
	}
	else if (IsPlayerSpitter(client))
	{
	canSpawnSpitter = false;
	CreateTimer(float(GetConVarInt(h_InfectedSpawnTimeMin)), ResetSpawnRestriction, 4);
	}
	else if (IsPlayerJockey(client))
	{
	canSpawnJockey = false;
	CreateTimer(float(GetConVarInt(h_InfectedSpawnTimeMin)), ResetSpawnRestriction, 5);
	}
	else if (IsPlayerCharger(client))
	{
	canSpawnCharger = false;
	CreateTimer(float(GetConVarInt(h_InfectedSpawnTimeMin)), ResetSpawnRestriction, 6);
	}
	}
	else
	{
	if (IsPlayerBoomer(client))
	{
	canSpawnBoomer = false;
	CreateTimer(float(GetConVarInt(h_InfectedSpawnTimeMin) * 0), ResetSpawnRestriction, 3);
	#if DEBUGSERVER
	LogMessage("Boomer died, setting spawn restrictions");
	#endif
	}
	else if (IsPlayerSmoker(client))
	{
	canSpawnSmoker = false;
	CreateTimer(float(GetConVarInt(h_InfectedSpawnTimeMin) * 0), ResetSpawnRestriction, 2);
	}
	}
	}
	*/
	
	// if victim was a bot, we setup a timer to spawn a new bot ...
	if (GetEventBool(event, "victimisbot") && (!DirectorSpawn))
	{
		if (!IsPlayerTank(client))
		{
			new SpawnTime = GetURandomIntRange(InfectedSpawnTimeMin, InfectedSpawnTimeMax);
			if (AdjustSpawnTimes && MaxPlayerZombies != HumansOnInfected())
				SpawnTime = SpawnTime / (MaxPlayerZombies - HumansOnInfected());
			CreateTimer(float(SpawnTime), Spawn_InfectedBot, _, 0);
			InfectedBotQueue++;
		}
		
		#if DEBUGCLIENTS
		PrintToChatAll("一个感染者电脑已经被加入生成队列...");
		#endif
	}
	
	if (IsPlayerTank(client))
	{
		CheckIfBotsNeeded(false, false);
	
		#if DEBUGCLIENTS
		PrintToChatAll("一个感染者电脑已经被加入生成队列...");
		#endif
	}
	else if (GameMode != 2 && DirectorSpawn)
	{
		new SpawnTime = GetURandomIntRange(InfectedSpawnTimeMin, InfectedSpawnTimeMax);
		GetSpawnTime[client] = SpawnTime;
	}
	
	// This fixes the spawns when the spawn timer is set to 5 or below and fixes the spitter spit glitch
	if (IsFakeClient(client) && !IsPlayerSpitter(client))
		CreateTimer(0.1, kickbot, client);
	
	return Plugin_Continue;
}

public Action:Spawn_InfectedBot_Director(Handle:timer, any:BotNeeded)
{
	
	new bool:resetGhost[MAXPLAYERS+1];
	new bool:resetLife[MAXPLAYERS+1];
	
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && (!IsFakeClient(i))) // player is connected and is not fake and it's in game ...
		{
			// If player is on infected's team and is dead ..
			if (GetClientTeam(i)==TEAM_INFECTED)
			{
				// If player is a ghost ....
				if (IsPlayerGhost(i))
				{
					resetGhost[i] = true;
					SetGhostStatus(i, false);
				}
				else if (!PlayerIsAlive(i))
				{
					AlreadyGhosted[i] = false;
					SetLifeState(i, true);
				}
			}
		}
	}
	
	new anyclient = GetAnyClient();
	new bool:temp = false;
	if (anyclient == -1)
	{
		#if DEBUGSERVER
		LogMessage("[Infected bots] 创建临时用户以伪造命令");
		#endif
		
		// we create a fake client
		anyclient = CreateFakeClient("Bot");
		if (anyclient == 0)
		{
			LogError("[L4D] Infected Bots: CreateFakeClient returned 0 -- 感染者电脑没有生成");
		}
		temp = true;
	}
	
	SpecialHalt = true;
	
	switch (BotNeeded)
	{
		case 1: // Smoker
		CheatCommand(anyclient, "z_spawn_old", "smoker auto");
		case 2: // Boomer
		CheatCommand(anyclient, "z_spawn_old", "boomer auto");
		case 3: // Hunter
		CheatCommand(anyclient, "z_spawn_old", "hunter auto");
		case 4: // Spitter
		CheatCommand(anyclient, "z_spawn_old", "spitter auto");
		case 5: // Jockey
		CheatCommand(anyclient, "z_spawn_old", "jockey auto");
		case 6: // Charger
		CheatCommand(anyclient, "z_spawn_old", "charger auto");
	}
	
	SpecialHalt = false;
	
	// We restore the player's status
	for (new i=1;i<=MaxClients;i++)
	{
		if (resetGhost[i])
			SetGhostStatus(i, true);
		if (resetLife[i])
			SetLifeState(i, true);
	}
	// If client was temp, we setup a timer to kick the fake player
	if (temp) CreateTimer(0.1, kickbot, anyclient);
}

/*
public Action:ResetSpawnRestriction (Handle:timer, any:bottype)
{
#if DEBUGSERVER
LogMessage("Resetting spawn restrictions");
#endif
switch (bottype)
{
case 1: // hunter
canSpawnHunter = true;
case 2: // smoker
canSpawnSmoker = true;
case 3: // boomer
canSpawnBoomer = true;
case 4: // spitter
canSpawnSpitter = true;
case 5: // jockey
canSpawnJockey = true;
case 6: // charger
canSpawnCharger = true;
}

}
*/
public Action:evtPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	// If player is a bot, we ignore this ...
	if (GetEventBool(event, "isbot")) return Plugin_Continue;
	
	// We get some data needed ...
	new newteam = GetEventInt(event, "team");
	new oldteam = GetEventInt(event, "oldteam");
	
	// If player's new/old team is infected, we recount the infected and add bots if needed ...
	if (!b_HasRoundEnded && b_LeftSaveRoom && GameMode == 2)
	{
		if (oldteam == 3||newteam == 3)
		{
			CheckIfBotsNeeded(false, false);
		}
		if (newteam == 3)
		{
			//Kick Timer
			CreateTimer(1.0, InfectedBotBooterVersus, _, TIMER_FLAG_NO_MAPCHANGE);
			#if DEBUGSERVER
			LogMessage("玩家切换到感染者队伍，尝试启动一个电脑");
			#endif
		}
	}
	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
	// If is a bot, skip this function
	if (IsFakeClient(client))
		return;
	
	// Reset all other arrays
	PlayerLifeState[client] = false;
	GetSpawnTime[client] = 0;
	AlreadyGhosted[client] = false;
	PlayerHasEnteredStart[client] = false;
	PlayersInServer--;
	
	// If no real players are left in game ... MI 5
	if (PlayersInServer == 0)
	{
		#if DEBUGSERVER
		LogMessage("所有玩家都离开了服务器");
		#endif
		
		b_LeftSaveRoom = false;
		b_HasRoundEnded = true;
		b_HasRoundStarted = false;
		DirectorCvarsModified = false;
		
		
		// Zero all respawn times ready for the next round
		for (new i = 1; i <= MaxClients; i++)
		{
			AlreadyGhosted[i] = false;
			PlayerHasEnteredStart[i] = false;
		}
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (FightOrDieTimer[i] != INVALID_HANDLE)
			{
				KillTimer(FightOrDieTimer[i]);
				FightOrDieTimer[i] = INVALID_HANDLE;
			}
		}
		
	}

	if (R14Enabled && IFADDEnabled)
	{
		CreateTimer(3.0, ADDIFNUMCHECKSD, any:2, 0);
	}
	
}

public Action:CheckIfBotsNeededLater (Handle:timer, any:spawn_immediately)
{
	CheckIfBotsNeeded(spawn_immediately, false);
}

CheckIfBotsNeeded(bool:spawn_immediately, bool:initial_spawn)
{
	if (!DirectorSpawn)
	{
		#if DEBUGSERVER
		LogMessage("检查电脑");
		#endif
		#if DEBUGCLIENTS
		PrintToChatAll("检查电脑");
		#endif
		
		if (b_HasRoundEnded || !b_LeftSaveRoom) return;
		
		// First, we count the infected
		CountInfected();
		
		new diff = MaxPlayerZombies - (InfectedBotCount + InfectedRealCount + InfectedBotQueue);
		
		// If we need more infected bots
		if (diff > 0)
		{
			for (new i;i<diff;i++)
			{
				// If we need them right away ...
				if (spawn_immediately)
				{
					InfectedBotQueue++;
					CreateTimer(0.5, Spawn_InfectedBot, _, 0);
					#if DEBUGSERVER
					LogMessage("正在设置电脑");
					#endif
				}
				else if (initial_spawn)
				{
					InfectedBotQueue++;
					CreateTimer(float(InitialSpawnInt), Spawn_InfectedBot, _, 0);
					#if DEBUGSERVER
					LogMessage("正在设置初始电脑");
					#endif
				}
				else // We use the normal time ..
				{
					InfectedBotQueue++;
					if (GameMode == 2 && AdjustSpawnTimes && MaxPlayerZombies != HumansOnInfected())
						CreateTimer(float(InfectedSpawnTimeMax) / (MaxPlayerZombies - HumansOnInfected()), Spawn_InfectedBot, _, 0);
					else if (GameMode == 1 && AdjustSpawnTimes)
						CreateTimer(float(InfectedSpawnTimeMax - TrueNumberOfSurvivors()), Spawn_InfectedBot, _, 0);
					else
					CreateTimer(float(InfectedSpawnTimeMax), Spawn_InfectedBot, _, 0);
				}
			}
		}
		
	}
}

CountInfected()
{
	// reset counters
	InfectedBotCount = 0;
	InfectedRealCount = 0;
	
	// First we count the ammount of infected real players and bots
	for (new i=1;i<=MaxClients;i++)
	{
		// We check if player is in game
		if (!IsClientInGame(i)) continue;
		
		// Check if client is infected ...
		if (GetClientTeam(i) == TEAM_INFECTED)
		{
			// If player is a bot ...
			if (IsFakeClient(i))
				InfectedBotCount++;
			else
			InfectedRealCount++;
		}
	}
	
}

// This event serves to make sure the bots spawn at the start of the finale event. The director disallows spawning until the survivors have started the event, so this was
// definitely needed.
public Action:evtFinaleStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(1.0, CheckIfBotsNeededLater, true);
}

BotTimePrepare()
{
	CreateTimer(1.0, BotTypeTimer)
	
	return 0;
}

public Action:BotTypeTimer (Handle:timer)
{
	BotTypeNeeded()
}

BotTypeNeeded()
{
	#if DEBUGSERVER
	LogMessage("正在确定电脑类型");
	#endif
	#if DEBUGCLIENTS
	PrintToChatAll("正在确定电脑类型");
	#endif
	
	// current count ...
	new boomers=0;
	new smokers=0;
	new hunters=0;
	new spitters=0;
	new jockeys=0;
	new chargers=0;
	new tanks=0;
	
	for (new i=1;i<=MaxClients;i++)
	{
		// if player is connected and ingame ...
		if (IsClientInGame(i))
		{
			// if player is on infected's team
			if (GetClientTeam(i) == TEAM_INFECTED && PlayerIsAlive(i))
			{
				// We count depending on class ...
				if (IsPlayerSmoker(i))
					smokers++;
				else if (IsPlayerBoomer(i))
					boomers++;	
				else if (IsPlayerHunter(i))
					hunters++;	
				else if (IsPlayerTank(i))
					tanks++;	
				else if (b_IsL4D2 && IsPlayerSpitter(i))
					spitters++;	
				else if (b_IsL4D2 && IsPlayerJockey(i))
					jockeys++;	
				else if (b_IsL4D2 && IsPlayerCharger(i))
					chargers++;	
			}
		}
	}
	
	if  (b_IsL4D2)
	{
		new random = GetURandomIntRange(1, 7);
		
		if (random == 2)
		{
			if ((smokers < SmokerLimit) && (canSpawnSmoker))
			{
				#if DEBUGSERVER
				LogMessage("电脑类型返回 Smoker");
				#endif
				return 2;
			}
		}
		else if (random == 3)
		{
			if ((boomers < BoomerLimit) && (canSpawnBoomer))
			{
				#if DEBUGSERVER
				LogMessage("电脑类型返回 Boomer");
				#endif
				return 3;
			}
		}
		else if (random == 1)
		{
			if ((hunters < HunterLimit) && (canSpawnHunter))
			{
				#if DEBUGSERVER
				LogMessage("电脑类型返回 Hunter");
				#endif
				return 1;
			}
		}
		else if (random == 4)
		{
			if ((spitters < SpitterLimit) && (canSpawnSpitter))
			{
				#if DEBUGSERVER
				LogMessage("电脑类型返回 Spitter");
				#endif
				return 4;
			}
		}
		else if (random == 5)
		{
			if ((jockeys < JockeyLimit) && (canSpawnJockey))
			{
				#if DEBUGSERVER
				LogMessage("电脑类型返回 Jockey");
				#endif
				return 5;
			}
		}
		else if (random == 6)
		{
			if ((chargers < ChargerLimit) && (canSpawnCharger))
			{
				#if DEBUGSERVER
				LogMessage("电脑类型返回 Charger");
				#endif
				return 6;
			}
		}
		
		else if (random == 7)
		{
			if (tanks < TankLimit)
			{
				#if DEBUGSERVER
				LogMessage("电脑类型返回 Tank");
				#endif
				return 7;
			}
		}
		
		return BotTimePrepare();
	}
	else
	{
		new random = GetURandomIntRange(1, 4);
		
		if (random == 2)
		{
			if ((smokers < SmokerLimit) && (canSpawnSmoker)) // we need a smoker ???? can we spawn a smoker ??? is smoker bot allowed ??
			{
				#if DEBUGSERVER
				LogMessage("返回 Smoker");
				#endif
				return 2;
			}
		}
		else if (random == 3)
		{
			if ((boomers < BoomerLimit) && (canSpawnBoomer))
			{
				#if DEBUGSERVER
				LogMessage("返回 Boomer");
				#endif
				return 3;
			}
		}
		else if (random == 1)
		{
			if (hunters < HunterLimit && canSpawnHunter)
			{
				#if DEBUGSERVER
				LogMessage("返回 Hunter");
				#endif
				return 1;
			}
		}
		
		else if (random == 4)
		{
			if (tanks < GetConVarInt(h_TankLimit))
			{
				#if DEBUGSERVER
				LogMessage("电脑类型返回 Tank");
				#endif
				return 7;
			}
		}
		
		return BotTimePrepare();
	}
}

public Action:Spawn_InfectedBot(Handle:timer)
{
	// If round has ended, we ignore this request ...
	if (b_HasRoundEnded || !b_HasRoundStarted || !b_LeftSaveRoom) return;
	
	new Infected = MaxPlayerZombies;
	
	if (Coordination && !DirectorSpawn && !InitialSpawn)
	{
		BotReady++;
		
		for (new i=1;i<=MaxClients;i++)
		{
			// We check if player is in game
			if (!IsClientInGame(i)) continue;
			
			// Check if client is infected ...
			if (GetClientTeam(i)==TEAM_INFECTED)
			{
				// If player is a real player 
				if (!IsFakeClient(i))
					Infected--;
			}
		}
		
		if (BotReady >= Infected)
		{
			CreateTimer(3.0, BotReadyReset, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			InfectedBotQueue--;
			return;
		}
	}
	
	// First we get the infected count
	CountInfected();
	
	// If infected's team is already full ... we ignore this request (a real player connected after timer started ) ..
	if ((InfectedRealCount + InfectedBotCount) >= MaxPlayerZombies || (InfectedRealCount + InfectedBotCount + InfectedBotQueue) > MaxPlayerZombies) 	
	{
		#if DEBUGSERVER
		LogMessage("感染者团队已满，插件将不会生成电脑");
		#endif
		InfectedBotQueue--;
		return;
	}
	
	// If there is a tank on the field and l4d_infectedbots_spawns_disable_tank is set to 1, the plugin will check for
	// any tanks on the field
	
	if (DisableSpawnsTank)
	{
		for (new i=1;i<=MaxClients;i++)
		{
			// We check if player is in game
			if (!IsClientInGame(i)) continue;
			
			// Check if client is infected ...
			if (GetClientTeam(i)==TEAM_INFECTED)
			{
				// If player is a tank
				if (IsPlayerTank(i) && IsPlayerAlive(i))
				{
					InfectedBotQueue--;
					return;
				}
			}
		}
		
	}
	
	// The bread and butter of this plugin.
	
	new bool:resetGhost[MAXPLAYERS+1];
	new bool:resetLife[MAXPLAYERS+1];
	
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i)) // player is connected and is not fake and it's in game ...
		{
			// If player is on infected's team and is dead ..
			if (GetClientTeam(i) == TEAM_INFECTED)
			{
				// If player is a ghost ....
				if (IsPlayerGhost(i))
				{
					resetGhost[i] = true;
					SetGhostStatus(i, false);
					#if DEBUGSERVER
					LogMessage("玩家是幽灵形态，阻止玩家生成");
					#endif
				}
				else if (!PlayerIsAlive(i)) // if player is just dead
				{
					resetLife[i] = true;
					SetLifeState(i, false);
				}
			}
		}
	}
	
	// We get any client ....
	new anyclient = GetAnyClient();
	new bool:temp = false;
	if (anyclient == -1)
	{
		#if DEBUGSERVER
		LogMessage("[Infected bots] 创建临时用户以伪造命令");
		#endif
		// we create a fake client
		anyclient = CreateFakeClient("Bot");
		if (!anyclient)
		{
			LogError("[L4D] Infected Bots: CreateFakeClient returned 0 -- 感染者电脑没有生成");
			return;
		}
		temp = true;
	}
	
	if (b_IsL4D2 && GameMode != 2)
	{
		new bot = CreateFakeClient("Infected Bot");
		if (bot != 0)
		{
			ChangeClientTeam(bot,TEAM_INFECTED);
			CreateTimer(0.1,kickbot,bot);
		}
	}
	
	// Determine the bot class needed ...
	new bot_type = BotTypeNeeded();
	// We spawn the bot ...
	switch (bot_type)
	{
		case 0: // Nothing
		{
			#if DEBUGSERVER
			LogMessage("电脑类型返回 NOTHING!");
			#endif
		}
		case 1: // Hunter
		{
			#if DEBUGSERVER
			LogMessage("正在生成 Hunter");
			#endif
			#if DEBUGCLIENTS
			PrintToChatAll("正在生成 Hunter");
			#endif
			CheatCommand(anyclient, "z_spawn_old", "hunter auto");
		}
		case 2: // Smoker
		{	
			#if DEBUGSERVER
			LogMessage("正在生成 Smoker");
			#endif
			#if DEBUGCLIENTS
			PrintToChatAll("正在生成 Smoker");
			#endif
			CheatCommand(anyclient, "z_spawn_old", "smoker auto");
		}
		case 3: // Boomer
		{
			#if DEBUGSERVER
			LogMessage("正在生成 Boomer");
			#endif
			#if DEBUGCLIENTS
			PrintToChatAll("正在生成 Boomer");
			#endif
			CheatCommand(anyclient, "z_spawn_old", "boomer auto");
		}
		case 4: // Spitter
		{
			#if DEBUGSERVER
			LogMessage("正在生成 Spitter");
			#endif
			#if DEBUGCLIENTS
			PrintToChatAll("正在生成 Spitter");
			#endif
			CheatCommand(anyclient, "z_spawn_old", "spitter auto");
		}
		case 5: // Jockey
		{
			#if DEBUGSERVER
			LogMessage("正在生成 Jockey");
			#endif
			#if DEBUGCLIENTS
			PrintToChatAll("正在生成 Jockey");
			#endif
			CheatCommand(anyclient, "z_spawn_old", "jockey auto");
		}
		case 6: // Charger
		{
			#if DEBUGSERVER
			LogMessage("正在生成 Charger");
			#endif
			#if DEBUGCLIENTS
			PrintToChatAll("正在生成 Charger");
			#endif
			CheatCommand(anyclient, "z_spawn_old", "charger auto");
		}
		case 7: // Tank
		{
			#if DEBUGSERVER
			LogMessage("正在生成 Tank");
			#endif
			#if DEBUGCLIENTS
			PrintToChatAll("正在生成 Tank");
			#endif
			CheatCommand(anyclient, "z_spawn_old", "tank auto");
		}
	}
	
	// We restore the player's status
	for (new i=1;i<=MaxClients;i++)
	{
		if (resetGhost[i] == true)
			SetGhostStatus(i, true);
		if (resetLife[i] == true)
			SetLifeState(i, true);
	}
	
	// If client was temp, we setup a timer to kick the fake player
	if (temp) CreateTimer(0.1,kickbot,anyclient);
	
	// Debug print
	#if DEBUGCLIENTS
	PrintToChatAll("正在生成一个感染者电脑. 类型 = %i ", bot_type);
	#endif
	
	// We decrement the infected queue
	InfectedBotQueue--;
	
	CreateTimer(1.0, CheckIfBotsNeededLater, true);
}

stock GetAnyClient() 
{ 
	for (new target = 1; target <= MaxClients; target++) 
	{ 
		if (IsClientInGame(target)) return target; 
	} 
	return -1; 
} 

public Action:kickbot(Handle:timer, any:client)
{
	if (IsClientInGame(client) && (!IsClientInKickQueue(client)))
	{
		if (IsFakeClient(client)) KickClient(client);
	}
}

bool:IsPlayerGhost (client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost"))
		return true;
	return false;
}

bool:PlayerIsAlive (client)
{
	if (!GetEntProp(client,Prop_Send, "m_lifeState"))
		return true;
	return false;
}

bool:IsPlayerSmoker (client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_SMOKER)
		return true;
	return false;
}

bool:IsPlayerBoomer (client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_BOOMER)
		return true;
	return false;
}

bool:IsPlayerHunter (client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_HUNTER)
		return true;
	return false;
}

bool:IsPlayerSpitter (client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_SPITTER)
		return true;
	return false;
}

bool:IsPlayerJockey (client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_JOCKEY)
		return true;
	return false;
}

bool:IsPlayerCharger (client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_CHARGER)
		return true;
	return false;
}

bool:IsPlayerTank (client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_TANK)
		return true;
	return false;
}

SetGhostStatus (client, bool:ghost)
{
	if (ghost)
		SetEntProp(client, Prop_Send, "m_isGhost", 1);
	else
	SetEntProp(client, Prop_Send, "m_isGhost", 0);
}

SetLifeState (client, bool:ready)
{
	if (ready)
		SetEntProp(client, Prop_Send,  "m_lifeState", 1);
	else
	SetEntProp(client, Prop_Send, "m_lifeState", 0);
}

TrueNumberOfSurvivors ()
{
	new TotalSurvivors;
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i))
			if (GetClientTeam(i) == TEAM_SURVIVORS)
				TotalSurvivors++;
		}
	return TotalSurvivors;
}

HumansOnInfected ()
{
	new TotalHumans;
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED && !IsFakeClient(i))
			TotalHumans++;
	}
	return TotalHumans;
}

bool:LeftStartArea()
{
	new ent = -1, maxents = GetMaxEntities();
	for (new i = MaxClients+1; i <= maxents; i++)
	{
		if (IsValidEntity(i))
		{
			decl String:netclass[64];
			GetEntityNetClass(i, netclass, sizeof(netclass));
			
			if (StrEqual(netclass, "CTerrorPlayerResource"))
			{
				ent = i;
				break;
			}
		}
	}
	
	if (ent > -1)
	{
		if (GetEntProp(ent, Prop_Send, "m_hasAnySurvivorLeftSafeArea"))
		{
			return true;
		}
	}
	return false;
}

stock GetURandomIntRange(min, max)
{
	return (GetURandomInt() % (max-min+1)) + min;
}

stock CheatCommand(client, String:command[], String:arguments[] = "")
{
	new userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}

bool IsPlayerGenericAdmin(int client)
{
    if (CheckCommandAccess(client, "generic_admin", ADMFLAG_GENERIC, false))
    {
        return false;
    }

    return true;
}  
/////////////////////////////////////////////////////////

public Action:R14Infectedon(client, args)
{
	if (client != 0 && OA_AIS && IsPlayerGenericAdmin(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
		return Action:0;
	}
	Rs14Infectedon();
	return Action:0;
}

Rs14Infectedon()
{
	IFADDEnabled = false;
	SetSpawnLimits();
	R14Enabled = true;
	EnabledCheck();
	PrintToChatAll("\x04[!警告!]\x05 开启了\x04 \x04%d\x01 \x05特模式,请注意!关闭请输入!off14", MaxPlayerZombies);
	return 0;
}

public Action:R14Infectedon2(client, args)
{
	if (client != 0 && OA_AIS && IsPlayerGenericAdmin(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
		return Action:0;
	}
	Rs14Infectedon2();
	return Action:0;
}

Rs14Infectedon2()
{
	IFADDEnabled = true;
	R14Enabled = true;
	baseNum = 4;
	CreateTimer(0.1, ADDIFNUMCHECKSD, any:3, 0);
	return 0;
}

public Action:R14Infectedon3(client, args)
{
	if (client != 0 && OA_AIS && IsPlayerGenericAdmin(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
		return Action:0;
	}
	Rs14Infectedon3();
	return Action:0;
}

Rs14Infectedon3()
{
	IFADDEnabled = true;
	R14Enabled = true;
	baseNum = 0;
	CreateTimer(0.1, ADDIFNUMCHECKSD, any:3, 0);
	return 0;
}

public Action:R14Infectedoff(client, args)
{
	if (client != 0 && OA_AIS && IsPlayerGenericAdmin(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
		return Action:0;
	}
	IFADDEnabled = false;
	R14Enabled = false;
	EnabledCheck();
	PrintToChatAll("\x04[!警告!]\x05 关闭了\x04 \x04%d\x01 \x05特模式,请注意!开启请输入!on14 ", MaxPlayerZombies);
	return Action:0;
}

public Action:IFADDNumsetcheck(client, args)
{
	if (client != 0 && OA_AIS && IsPlayerGenericAdmin(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
		return Action:0;
	}
	rDisplayIFADDMenu(client);
	return Action:0;
}

public Action:IFADDTimecheck(client, args)
{
	if (client != 0 && OA_AIS && IsPlayerGenericAdmin(client))
	{
		ReplyToCommand(client, "[提示] 该功能只限管理员使用.");
		return Action:0;
	}
	if (args > 0)
	{
		char arg[4];
		GetCmdArg(1, arg, sizeof(arg));
		int itemNum = StringToInt(arg, 10);
		SetItemNum(itemNum)
	}
	else
	{
		rDisplayIFTimeMenu(client);
	}
	return Action:0;
}

rDisplayIFADDMenu(client)
{
	new String:namelist[10];
	new String:nameno[4];
	new Handle:menu = CreateMenu(rIFADDNumMMNMenuHandler, MenuAction:28);
	SetMenuTitle(menu, "配置每名幸存者玩家增加多少特感");
	new i = 1;
	while (i <= 6)
	{
		Format(nameno, 3, "%i", i);
		Format(namelist, 10, "%i 个", i);
		AddMenuItem(menu, nameno, namelist, 0);
		i++;
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	return 0;
}

public rIFADDNumMMNMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction:4)
	{
		new String:clientinfos[12];
		new R14userids;
		GetMenuItem(menu, itemNum, clientinfos, 10);
		R14userids = StringToInt(clientinfos, 10);
		RIFADDNUMS = R14userids;
		if (R14Enabled && IFADDEnabled)
		{
			CreateTimer(1.0, ADDIFNUMCHECKSD, any:0, 0);
		}
	}
	return 0;
}

rDisplayIFTimeMenu(client)
{
	new Handle:menu = CreateMenu(rIFTimeNumMMNMenuHandler, MenuAction:28);
	SetMenuTitle(menu, "多久刷新一轮特感(秒)");
	AddMenuItem(menu, "time0", "使用CFG的配置", 0);
	AddMenuItem(menu, "time1", "Min:20-Max:35", 0);
	AddMenuItem(menu, "time2", "Min:15-Max:30", 0);
	AddMenuItem(menu, "time3", "Min:15-Max:25", 0);
	AddMenuItem(menu, "time4", "Min:15-Max:20", 0);
	AddMenuItem(menu, "time5", "Min:10-Max:20", 0);
	AddMenuItem(menu, "time6", "Min:5-Max:15", 0);
	AddMenuItem(menu, "time7", "Min:5-Max:10", 0);
	AddMenuItem(menu, "time8", "Min:1-Max:2", 0);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	return 0;
}

public rIFTimeNumMMNMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction:4)
	{
		SetItemNum(itemNum)
	}
	return 0;
}

public Action:Event_RIFPlayerAct(Handle:event, String:name[], bool:dontBroadcast)
{
	new check14player = GetClientOfUserId(GetEventInt(event, "userid", 0));
	if (!IsFakeClient(check14player))
	{
		if (R14Enabled && IFADDEnabled)
		{
			CreateTimer(3.0, ADDIFNUMCHECKSD, any:2, 0);
		}
	}
	return Action:0;
}

public void SetItemNum(int itemNum)
{
	int SpawnTimeMin, SpawnTimeMax;
	switch (itemNum)
	{
		case 0:
		{
			SpawnTimeMin = GetConVarInt(h_InfectedSpawnTimeMin);
			SpawnTimeMax = GetConVarInt(h_InfectedSpawnTimeMax);
		}
		case 1:
		{
			SpawnTimeMin = 20;
			SpawnTimeMax = 35;
		}
		case 2:
		{
			SpawnTimeMin = 15;
			SpawnTimeMax = 30;
		}
		case 3:
		{
			SpawnTimeMin = 15;
			SpawnTimeMax = 25;
		}
		case 4:
		{
			SpawnTimeMin = 15;
			SpawnTimeMax = 20;
		}
		case 5:
		{
			SpawnTimeMin = 10;
			SpawnTimeMax = 20;
		}
		case 6:
		{
			SpawnTimeMin = 5;
			SpawnTimeMax = 15;
		}
		case 7:
		{
			SpawnTimeMin = 5;
			SpawnTimeMax = 10;
		}
		case 8:
		{
			SpawnTimeMin = 1;
			SpawnTimeMax = 2;
		}
		default:
		{
		}
	}
	InfectedSpawnTimeMin = SpawnTimeMin;
	InfectedSpawnTimeMax = SpawnTimeMax;
	PrintToChatAll("\x04[!警告!]\x05 特感重生时间(秒)\x04 Min:\x04%d\x01 - Max:\x04%d\x01\x05,请注意!", SpawnTimeMin, SpawnTimeMax);
}

public Action:ADDIFNUMCHECKSD(Handle:timer, any:Rflag)
{
	if (IFADDEnabled)
	{
		new num14Players;
		new i = 1;
		while (i <= MaxClients)
		{
			if (IsClientInGame(i) && GetClientTeam(i) <= 2 && !IsFakeClient(i))
			{
				num14Players++;
			}
			i++;
		}
		if (num14Players <= 4)
		{
			num14Players = 4;
		}
		MaxPlayerZombies = RIFADDNUMS * num14Players + baseNum;
		if (MaxPlayerZombies > 24)
		{
			MaxPlayerZombies = 24;
		}
		if (MaxPlayerZombies < 13)
		{
			SetSpawnLimit(2);
		}
		if (MaxPlayerZombies > 12 && MaxPlayerZombies < 19)
		{
			SetSpawnLimit(3);
		}
		if (MaxPlayerZombies > 18)
		{
			SetSpawnLimit(4);
		}
	}
	else
	{
		MaxPlayerZombies = GetConVarInt(h_MaxPlayerZombies);
		SetSpawnLimits();
	}
	if (Rflag == 3)
	{
		PrintToChatAll("\x04[!警告!]\x05开启了\x04\x04%d\x01\x05特模式按人数增加,最少\x04\x04%d\x01\x05特,每增加一名幸存者增加\x04\x04%d\x01\x05特,关闭请输入!off14", MaxPlayerZombies, baseNum, RIFADDNUMS);
	}
	else
	{
		if (timer_handle != null)
		{
			KillTimer(timer_handle);
			timer_handle = null;
		}
		timer_handle = CreateTimer(1.0, Announce_Delay, Rflag);
		return Action:0;
	}
	return Action:0;
}

public Action:Announce_Delay(Handle:timer, any:Rflag)
{
	switch (Rflag)
	{
		case 0:
		{
			PrintToChatAll("\x04[!提示!]\x05 特感数量增加现在是\x03 \x04%d\x01 特.", MaxPlayerZombies);
		}
		case 1:
		{
			PrintToChatAll("\x04[!提示!]\x05 -幸存者减少了,特感数量现在是\x03 \x04%d\x01 特.", MaxPlayerZombies);
		}
		case 2:
		{
			PrintToChatAll("\x04[!提示!]\x05 +幸存者增加了,特感数量现在是\x03 \x04%d\x01 特.", MaxPlayerZombies);
		}
		default:
		{
		}
	}
	timer_handle = null;
	return Action:0;
}

SetSpawnLimit(num)
{
	BoomerLimit = num;
	SmokerLimit = num;
	HunterLimit = num;
	if (b_IsL4D2)
	{
		SpitterLimit = num;
		JockeyLimit = num;
		ChargerLimit = num;
	}
}

SetSpawnLimits()
{
	BoomerLimit = GetConVarInt(h_BoomerLimit);
	SmokerLimit = GetConVarInt(h_SmokerLimit);
	HunterLimit = GetConVarInt(h_HunterLimit);
	if (b_IsL4D2)
	{
		SpitterLimit = GetConVarInt(h_SpitterLimit);
		JockeyLimit = GetConVarInt(h_JockeyLimit);
		ChargerLimit = GetConVarInt(h_ChargerLimit);
	}
}

EnabledCheck()
{
	if (R14Enabled)
	{
		SetConVarInt(h_DirectorSpawn, 0);
	}
	else
	{
		SetConVarInt(h_DirectorSpawn, 1);
	}
	return 0;
}
