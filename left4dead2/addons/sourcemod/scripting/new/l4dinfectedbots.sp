
#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#undef REQUIRE_PLUGIN
#include <left4dhooks>
#define PLUGIN_VERSION "2.4.4"
#define DEBUG 0

#define TEAM_SPECTATOR		1
#define TEAM_SURVIVORS 		2
#define TEAM_INFECTED 		3

#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6

#define MAXENTITIES 2048
#define SUICIDE_TIME 10
// Infected models
#define MODEL_SMOKER "models/infected/smoker.mdl"
#define MODEL_BOOMER "models/infected/boomer.mdl"
#define MODEL_HUNTER "models/infected/hunter.mdl"
#define MODEL_SPITTER "models/infected/spitter.mdl"
#define MODEL_JOCKEY "models/infected/jockey.mdl"
#define MODEL_CHARGER "models/infected/charger.mdl"
#define MODEL_TANK "models/infected/hulk.mdl"
#define ZOMBIESPAWN_Attempts 7

// l4d1/2 value
static char sSpawnCommand[32];
static int ZOMBIECLASS_TANK;

// Variables
static int InfectedRealCount; // Holds the amount of real infected players
static int InfectedBotCount; // Holds the amount of infected bots in any gamemode
static int InfectedBotQueue; // Holds the amount of bots that are going to spawn
static int GameMode; // Holds the GameMode, 1 for coop and realism, 2 for versus, teamversus, scavenge and teamscavenge, 3 for survival
static int TanksPlaying; // Holds the amount of tanks on the playing field
static int g_iBoomerLimit; // Sets the Boomer Limit, related to the boomer limit cvar
static int g_iSmokerLimit; // Sets the Smoker Limit, related to the smoker limit cvar
static int g_iHunterLimit; // Sets the Hunter Limit, related to the hunter limit cvar
static int g_iSpitterLimit; // Sets the Spitter Limit, related to the Spitter limit cvar
static int g_iJockeyLimit; // Sets the Jockey Limit, related to the Jockey limit cvar
static int g_iChargerLimit; // Sets the Charger Limit, related to the Charger limit cvar
static int g_iMaxPlayerZombies; // Holds the amount of the maximum amount of special zombies on the field
static int MaxPlayerTank; // Used for setting an additional slot for each tank that spawns
static int BotReady; // Used to determine how many bots are ready, used only for the coordination feature
static int GetSpawnTime[MAXPLAYERS+1]; // Used for the HUD on getting spawn times of players
static int iPlayersInSurvivorTeam;

// Booleans
static bool b_HasRoundStarted; // Used to state if the round started or not
static bool b_HasRoundEnded; // States if the round has ended or not
static bool b_LeftSaveRoom; // States if the survivors have left the safe room
static bool canSpawnBoomer; // States if we can spawn a boomer (releated to spawn restrictions)
static bool canSpawnSmoker; // States if we can spawn a smoker (releated to spawn restrictions)
static bool canSpawnHunter; // States if we can spawn a hunter (releated to spawn restrictions)
static bool canSpawnSpitter; // States if we can spawn a spitter (releated to spawn restrictions)
static bool canSpawnJockey; // States if we can spawn a jockey (releated to spawn restrictions)
static bool canSpawnCharger; // States if we can spawn a charger (releated to spawn restrictions)
static bool FinaleStarted; // States whether the finale has started or not
static bool WillBeTank[MAXPLAYERS+1]; // States whether that player will be the tank
//bool TankHalt; // Loop Breaker, prevents player tanks from spawning over and over
static bool TankWasSeen[MAXPLAYERS+1]; // Used only in coop, prevents the Sound hook event from triggering over and over again
static bool PlayerLifeState[MAXPLAYERS+1]; // States whether that player has the lifestate changed from switching the gamemode
static bool InitialSpawn; // Related to the coordination feature, tells the plugin to let the infected spawn when the survivors leave the safe room
static bool L4D2Version = false; // Holds the version of L4D; false if its L4D, true if its L4D2
static bool TempBotSpawned; // Tells the plugin that the tempbot has spawned
static bool AlreadyGhosted[MAXPLAYERS+1]; // Loop Breaker, prevents a player from spawning into a ghost over and over again
static bool AlreadyGhostedBot[MAXPLAYERS+1]; // Prevents bots taking over a player from ghosting
static bool SurvivalVersus;
static bool PlayerHasEnteredStart[MAXPLAYERS+1];
static bool bDisableSurvivorModelGlow;

// ConVar
ConVar h_BoomerLimit; // Related to the Boomer limit cvar
ConVar h_SmokerLimit; // Related to the Smoker limit cvar
ConVar h_HunterLimit; // Related to the Hunter limit cvar
ConVar h_SpitterLimit; // Related to the Spitter limit cvar
ConVar h_JockeyLimit; // Related to the Jockey limit cvar
ConVar h_ChargerLimit; // Related to the Charger limit cvar
ConVar h_MaxPlayerZombies; // Related to the max specials cvar
ConVar h_PlayerAddZombiesScale;
ConVar h_PlayerAddZombies;
ConVar h_PlayerAddTankHealthScale; 
ConVar h_PlayerAddTankHealth; 
ConVar h_InfectedSpawnTimeMax; // Related to the spawn time cvar
ConVar h_InfectedSpawnTimeMin; // Related to the spawn time cvar
ConVar h_CoopPlayableTank; // yup, same thing again
ConVar h_JoinableTeams; // Can you guess this one?
ConVar h_StatsBoard; // Oops, now we are
ConVar h_JoinableTeamsAnnounce;
ConVar h_Coordination;
ConVar h_Idletime_b4slay;
ConVar h_InitialSpawn;
ConVar h_HumanCoopLimit;
ConVar h_AdminJoinInfected;
ConVar h_BotGhostTime;
ConVar h_DisableSpawnsTank;
ConVar h_TankLimit;
ConVar h_WitchLimit;
ConVar h_VersusCoop;
ConVar h_AdjustSpawnTimes;
ConVar h_InfHUD;
ConVar h_Announce ;
ConVar h_TankHealthAdjust;
ConVar h_TankHealth;
ConVar h_GameMode; 
ConVar h_Difficulty; 
ConVar cvarZombieHP[7];				// Array of handles to the 4 cvars we have to hook to monitor HP changes
ConVar h_SafeSpawn;
ConVar h_SpawnDistanceMin;
ConVar h_SpawnDistanceMax;
ConVar h_SpawnDistanceFinal;
ConVar h_WitchPeriodMax;
ConVar h_WitchPeriodMin;
ConVar h_WitchSpawnFinal;
ConVar h_WitchKillTime;
ConVar h_ReducedSpawnTimesOnPlayer;
ConVar h_SpawnTankProbability;
ConVar h_ZSDisableGamemode;
ConVar h_CommonLimitAdjust, h_CommonLimit, h_PlayerAddCommonLimitScale, h_PlayerAddCommonLimit,h_common_limit_cvar;

//Handle
static Handle PlayerLeftStartTimer = null; //Detect player has left safe area or not
static Handle infHUDTimer 		= null;	// The main HUD refresh timer
static Handle respawnTimer 	= null;	// Respawn countdown timer
static Handle delayedDmgTimer 	= null;	// Delayed damage update timer
static Panel pInfHUD = null;
static Handle usrHUDPref 		= null;	// Stores the client HUD preferences persistently
Handle FightOrDieTimer[MAXPLAYERS+1] = null; // kill idle bots
Handle hSpawnWitchTimer = null;

//signature call
static Handle hSpec = null;
static Handle hSwitch = null;
static Handle hCreateSmoker = null;
static Handle hCreateBoomer = null;
static Handle hCreateHunter = null;
static Handle hCreateSpitter = null;
static Handle hCreateJockey = null;
static Handle hCreateCharger = null;
static Handle hCreateTank = null;

// Stuff related to Durzel's HUD (Panel was redone)
static int respawnDelay[MAXPLAYERS+1]; 			// Used to store individual player respawn delays after death
static int hudDisabled[MAXPLAYERS+1];				// Stores the client preference for whether HUD is shown
static int clientGreeted[MAXPLAYERS+1]; 			// Stores whether or not client has been shown the mod commands/announce
static int zombieHP[7];					// Stores special infected max HP
static bool roundInProgress 		= false;		// Flag that marks whether or not a round is currently in progress
static float fPlayerSpawnEngineTime[MAXENTITIES] = 0.0; //time when real infected player spawns

int g_iClientColor[MAXPLAYERS+1], g_iClientIndex[MAXPLAYERS+1], g_iLightIndex[MAXPLAYERS+1];
int iPlayerTeam[MAXPLAYERS+1];
bool g_bSafeSpawn, g_bTankHealthAdjust, g_bVersusCoop, g_bJoinableTeams, g_bCoopPlayableTank , g_bJoinableTeamsAnnounce,
	g_bInfHUD, g_bAnnounce , g_bAdminJoinInfected, g_bAdjustSpawnTimes, g_bCommonLimitAdjust;
int g_iZSDisableGamemode, g_iTankHealth, g_iInfectedSpawnTimeMax, g_iInfectedSpawnTimeMin, g_iHumanCoopLimit,
	g_iReducedSpawnTimesOnPlayer, g_iWitchPeriodMax, g_iWitchPeriodMin, g_iSpawnTankProbability, g_iCommonLimit;
int g_iPlayerSpawn, g_bMapStarted, g_bSpawnWitchBride;
float g_fIdletime_b4slay, g_fInitialSpawn, g_fWitchKillTime;
int g_iModelIndex[MAXPLAYERS+1];			// Player Model entity reference


public Plugin myinfo = 
{
	name = "[L4D/L4D2] Infected Bots (Coop/Versus/Realism/Scavenge/Survival)",
	author = "djromero (SkyDavid), MI 5, Harry Potter",
	description = "Spawns infected bots in versus, allows playable special infected in coop/survival, and changable z_max_player_zombies limit",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showpost.php?p=2699220&postcount=1371"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	
	if( test == Engine_Left4Dead )
	{
		ZOMBIECLASS_TANK = 5;
		sSpawnCommand = "z_spawn";
		L4D2Version = false;
	}
	else if( test == Engine_Left4Dead2 )
	{
		ZOMBIECLASS_TANK = 8;
		sSpawnCommand = "z_spawn_old";
		L4D2Version = true;
	}
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success; 
}

public void OnPluginStart()
{
	LoadTranslations("l4dinfectedbots.phrases");
	
	// Notes on the offsets: altough m_isGhost is used to check or set a player's ghost status, for some weird reason this disallowed the player from spawning.
	// So I found and used m_isCulling to allow the player to press use and spawn as a ghost (which in this case, I forced the client to press use)
	
	// m_lifeState is an alternative to the "switching to spectator and back" method when a bot spawns. This was used to prevent players from taking over those bots, but
	// this provided weird movements when a player was spectating on the infected team.
	
	// ScrimmageType is interesting as it was used in the beta. The scrimmage code was abanonded and replaced with versus, but some of it is still left over in the final.
	// In the previous versions of this plugin (or not using this plugin at all), you might have seen giant bubbles or spheres around the map. Those are scrimmage spawn
	// spheres that were used to prevent infected from spawning within there. It was bothering me, and a whole lot of people who saw them. Thanks to AtomicStryker who
	// URGED me to remove the spheres, I began looking for a solution. He told me to use various source handles like m_scrimmageType and others. I experimented with it,
	// and found out that it removed the spheres, and implemented it into the plugin. The spheres are no longer shown, and they were useless anyway as infected still spawn 
	// within it.
	
	
	// Notes on the sourcemod commands:
	// JoinSpectator is actually a DEBUG command I used to see if the bots spawn correctly with and without a player. It was incredibly useful for this purpose, but it
	// will not be in the final versions.
	
	// Add a sourcemod command so players can easily join infected in coop/survival

	RegAdminCmd("sm_zlimit", Console_ZLimit, ADMFLAG_SLAY,"control max special zombies limit");
	RegAdminCmd("sm_timer", Console_Timer, ADMFLAG_SLAY,"control special zombies spawn timer");
	#if DEBUG
	RegConsoleCmd("sm_jrtg", JoinInfected);
	RegConsoleCmd("sm_jrshz", JoinSurvivors);
	RegConsoleCmd("sm_tgzs", ForceInfectedSuicide,"suicide myself (if infected get stuck or somthing)");
	RegConsoleCmd("sm_sp", JoinSpectator);
	RegConsoleCmd("sm_gamemode", CheckGameMode);
	RegConsoleCmd("sm_count", CheckQueue);
	#endif
	
	// Hook "say" so clients can toggle HUD on/off for themselves
	RegConsoleCmd("sm_infhud", Command_Say);
	
	// We register the version cvar
	CreateConVar("l4d_infectedbots_version", PLUGIN_VERSION, "Version of L4D Infected Bots", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	// console variables
	h_BoomerLimit = CreateConVar("l4d_infectedbots_boomer_limit", "2", "Sets the limit for boomers spawned by the plugin", FCVAR_NOTIFY, true, 0.0);
	h_SmokerLimit = CreateConVar("l4d_infectedbots_smoker_limit", "2", "Sets the limit for smokers spawned by the plugin", FCVAR_NOTIFY, true, 0.0);
	h_HunterLimit = CreateConVar("l4d_infectedbots_hunter_limit", "2", "Sets the limit for hunters spawned by the plugin", FCVAR_NOTIFY, true, 0.0);
	h_TankLimit = CreateConVar("l4d_infectedbots_tank_limit", "1", "Sets the limit for tanks spawned by the plugin (does not affect director tanks)", FCVAR_NOTIFY, true, 0.0);
	h_WitchLimit = CreateConVar("l4d_infectedbots_witch_max_limit", "10", "Sets the limit for witches spawned by the plugin (does not affect director witches)", FCVAR_NOTIFY, true, 0.0);
	if (L4D2Version)
	{
		h_SpitterLimit = CreateConVar("l4d_infectedbots_spitter_limit", "2", "Sets the limit for spitters spawned by the plugin", FCVAR_NOTIFY, true, 0.0);
		h_JockeyLimit = CreateConVar("l4d_infectedbots_jockey_limit", "2", "Sets the limit for jockeys spawned by the plugin", FCVAR_NOTIFY, true, 0.0);
		h_ChargerLimit = CreateConVar("l4d_infectedbots_charger_limit", "2", "Sets the limit for chargers spawned by the plugin", FCVAR_NOTIFY, true, 0.0);
	}
	
	h_MaxPlayerZombies = CreateConVar("l4d_infectedbots_max_specials", "2", "Defines how many special infected can be on the map on all gamemodes(does not count witch on all gamemodes, count tank in all gamemode)", FCVAR_NOTIFY, true, 0.0); 
	h_PlayerAddZombiesScale = CreateConVar("l4d_infectedbots_add_specials_scale", "2", "If server has more than 4+ alive players, how many special infected = 'max_specials' + [(alive players - 4) ÷ 'add_specials_scale' × 'add_specials'].", FCVAR_NOTIFY, true, 1.0); 
	h_PlayerAddZombies = CreateConVar("l4d_infectedbots_add_specials", "2", "If server has more than 4+ alive players, increase the certain value to 'l4d_infectedbots_max_specials' each 'l4d_infectedbots_add_specials_scale' players joins", FCVAR_NOTIFY, true, 0.0); 

	h_TankHealthAdjust = CreateConVar("l4d_infectedbots_adjust_tankhealth_enable", "1", "If 1, adjust and overrides tank health by this plugin.", FCVAR_NOTIFY, true, 0.0,true, 1.0); 
	h_TankHealth = CreateConVar("l4d_infectedbots_default_tankhealth", "4000", "Sets Default Health for Tank", FCVAR_NOTIFY, true, 1.0); 
	h_PlayerAddTankHealthScale = CreateConVar("l4d_infectedbots_add_tankhealth_scale", "1", "If server has more than 4+ alive players, how many Tank Health = 'default_tankhealth' + [(alive players - 4) ÷ 'add_tankhealth_scale' × 'add_tankhealth'].", FCVAR_NOTIFY, true, 1.0); 
	h_PlayerAddTankHealth = CreateConVar("l4d_infectedbots_add_tankhealth", "500", "If server has more than 4+ alive players, increase the certain value to 'l4d_infectedbots_default_tankhealth' each 'l4d_infectedbots_add_tankhealth_scale' players joins", FCVAR_NOTIFY, true, 0.0); 
	h_InfectedSpawnTimeMax = CreateConVar("l4d_infectedbots_spawn_time_max", "60", "Sets the max spawn time for special infected spawned by the plugin in seconds.", FCVAR_NOTIFY, true, 1.0);
	h_InfectedSpawnTimeMin = CreateConVar("l4d_infectedbots_spawn_time_min", "40", "Sets the minimum spawn time for special infected spawned by the plugin in seconds.", FCVAR_NOTIFY, true, 1.0);
	h_CoopPlayableTank = CreateConVar("l4d_infectedbots_coop_versus_tank_playable", "0", "If 1, tank will be playable in coop/survival", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_JoinableTeams = CreateConVar("l4d_infectedbots_coop_versus", "1", "If 1, players can join the infected team in coop/survival (!ji in chat to join infected, !js to join survivors)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	if (!L4D2Version)
	{
		h_StatsBoard = CreateConVar("l4d_infectedbots_stats_board", "0", "If 1, the stats board will show up after an infected player dies (L4D1 ONLY)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	}
	h_JoinableTeamsAnnounce = CreateConVar("l4d_infectedbots_coop_versus_announce", "1", "If 1, clients will be announced to on how to join the infected team", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_Coordination = CreateConVar("l4d_infectedbots_coordination", "0", "If 1, bots will only spawn when all other bot spawn timers are at zero", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_InfHUD = CreateConVar("l4d_infectedbots_infhud_enable", "1", "Toggle whether Infected HUD is active or not.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_Announce = CreateConVar("l4d_infectedbots_infhud_announce", "1", "Toggle whether Infected HUD announces itself to clients.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_Idletime_b4slay = CreateConVar("l4d_infectedbots_lifespan", "30", "Amount of seconds before a special infected bot is kicked", FCVAR_NOTIFY, true, 1.0);
	h_InitialSpawn = CreateConVar("l4d_infectedbots_initial_spawn_timer", "10", "The spawn timer in seconds used when infected bots are spawned for the first time in a map", FCVAR_NOTIFY, true, 0.0);
	h_HumanCoopLimit = CreateConVar("l4d_infectedbots_coop_versus_human_limit", "2", "Sets the limit for the amount of humans that can join the infected team in coop/survival", FCVAR_NOTIFY, true, 0.0);
	h_AdminJoinInfected = CreateConVar("l4d_infectedbots_admin_coop_versus", "1", "If 1, only admins can join the infected team in coop/survival", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_BotGhostTime = CreateConVar("l4d_infectedbots_ghost_time", "1", "If higher than zero, the plugin will ghost bots before they fully spawn on versus/scavenge", FCVAR_NOTIFY);
	h_DisableSpawnsTank = CreateConVar("l4d_infectedbots_spawns_disabled_tank", "0", "If 1, Plugin will disable spawning infected bot when a tank is on the field.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_VersusCoop = CreateConVar("l4d_infectedbots_versus_coop", "0", "If 1, The plugin will force all players to the infected side against the survivor AI for every round and map in versus/scavenge", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_AdjustSpawnTimes = CreateConVar("l4d_infectedbots_adjust_spawn_times", "1", "If 1, The plugin will adjust spawn timers depending on the gamemode", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_ReducedSpawnTimesOnPlayer = CreateConVar("l4d_infectedbots_adjust_reduced_spawn_times_on_player", "1", "Reduce certain value to maximum spawn timer based per alive player", FCVAR_NOTIFY, true, 0.0);
	h_SafeSpawn = CreateConVar("l4d_infectedbots_safe_spawn", "0", "If 1, spawn special infected before survivors leave starting safe room area.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_SpawnDistanceMin = CreateConVar("l4d_infectedbots_spawn_range_min", "0", "The minimum of spawn range for infected (default: 550)", FCVAR_NOTIFY, true, 0.0);
	h_SpawnDistanceMax = CreateConVar("l4d_infectedbots_spawn_range_max", "2000", "The maximum of spawn range for infected (default: 1500)", FCVAR_NOTIFY, true, 1.0);
	h_SpawnDistanceFinal = CreateConVar("l4d_infectedbots_spawn_range_final", "0", "The minimum of spawn range for infected in final stage rescue.", FCVAR_NOTIFY, true, 0.0);
	h_WitchPeriodMax = CreateConVar("l4d_infectedbots_witch_spawn_time_max", "120.0", "Sets the max spawn time for witch spawned by the plugin in seconds.", FCVAR_NOTIFY, true, 1.0);
	h_WitchPeriodMin = CreateConVar("l4d_infectedbots_witch_spawn_time_min", "90.0", "Sets the mix spawn time for witch spawned by the plugin in seconds.", FCVAR_NOTIFY, true, 1.0);
	h_WitchSpawnFinal = CreateConVar("l4d_infectedbots_witch_spawn_final", "0", "If 1, still spawn witch in final stage rescue", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_WitchKillTime = CreateConVar("l4d_infectedbots_witch_lifespan", "200", "Amount of seconds before a witch is kicked", FCVAR_NOTIFY, true, 1.0);
	h_SpawnTankProbability = CreateConVar("l4d_infectedbots_tank_spawn_probability", "5", "When each time spawn S.I., how much percent of chance to spawn tank", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	h_ZSDisableGamemode = CreateConVar("l4d_infectedbots_sm_zs_disable_gamemode", "6", "Disable sm_zs in these gamemode (0: None, 1: coop/realism, 2: versus/scavenge, 4: survival, add numbers together)", FCVAR_NOTIFY, true, 0.0, true, 7.0);
	h_CommonLimitAdjust = CreateConVar("l4d_infectedbots_adjust_commonlimit_enable", "1", "If 1, adjust and overrides zombie common limit by this plugin.", FCVAR_NOTIFY, true, 0.0,true, 1.0); 
	h_CommonLimit = CreateConVar("l4d_infectedbots_default_commonlimit", "30", "Sets Default zombie common limit.", FCVAR_NOTIFY, true, 1.0); 
	h_PlayerAddCommonLimitScale = CreateConVar("l4d_infectedbots_add_commonlimit_scale", "1", "If server has more than 4+ alive players, zombie common limit = 'default_commonlimit' + [(alive players - 4) ÷ 'add_commonlimit_scale' × 'add_commonlimit'].", FCVAR_NOTIFY, true, 1.0); 
	h_PlayerAddCommonLimit = CreateConVar("l4d_infectedbots_add_commonlimit", "2", "If server has more than 4+ alive players, increase the certain value to 'l4d_infectedbots_default_commonlimit' each 'l4d_infectedbots_add_commonlimit_scale' players joins", FCVAR_NOTIFY, true, 0.0); 

	h_GameMode = FindConVar("mp_gamemode");
	h_GameMode.AddChangeHook(ConVarGameMode);
	h_Difficulty = FindConVar("z_difficulty");
	h_common_limit_cvar = FindConVar("z_common_limit");

	GetCvars();
	h_BoomerLimit.AddChangeHook(ConVarChanged_Cvars);
	h_SmokerLimit.AddChangeHook(ConVarChanged_Cvars);
	h_HunterLimit.AddChangeHook(ConVarChanged_Cvars);
	if (L4D2Version)
	{
		h_SpitterLimit.AddChangeHook(ConVarChanged_Cvars);
		h_JockeyLimit.AddChangeHook(ConVarChanged_Cvars);
		h_ChargerLimit.AddChangeHook(ConVarChanged_Cvars);
	}
	h_SafeSpawn.AddChangeHook(ConVarChanged_Cvars);
	h_TankHealth.AddChangeHook(ConVarChanged_Cvars);
	h_InfectedSpawnTimeMax.AddChangeHook(ConVarChanged_Cvars);
	h_InfectedSpawnTimeMin.AddChangeHook(ConVarChanged_Cvars);
	h_CoopPlayableTank.AddChangeHook(ConVarChanged_Cvars);
	h_JoinableTeamsAnnounce.AddChangeHook(ConVarChanged_Cvars);
	h_InfHUD.AddChangeHook(ConVarChanged_Cvars);
	h_Announce.AddChangeHook(ConVarChanged_Cvars);
	h_Idletime_b4slay.AddChangeHook(ConVarChanged_Cvars);
	h_InitialSpawn.AddChangeHook(ConVarChanged_Cvars);
	h_HumanCoopLimit.AddChangeHook(ConVarChanged_Cvars);
	h_AdminJoinInfected.AddChangeHook(ConVarChanged_Cvars);
	h_AdjustSpawnTimes.AddChangeHook(ConVarChanged_Cvars);
	h_ReducedSpawnTimesOnPlayer.AddChangeHook(ConVarChanged_Cvars);
	h_ZSDisableGamemode.AddChangeHook(ConVarChanged_Cvars);
	h_WitchPeriodMax.AddChangeHook(ConVarChanged_Cvars);
	h_WitchPeriodMin.AddChangeHook(ConVarChanged_Cvars);
	h_WitchKillTime.AddChangeHook(ConVarChanged_Cvars);
	h_SpawnTankProbability.AddChangeHook(ConVarChanged_Cvars);
	h_CommonLimit.AddChangeHook(ConVarChanged_Cvars);

	GetSpawnDisConvars();
	g_iMaxPlayerZombies = h_MaxPlayerZombies.IntValue;
	g_bTankHealthAdjust = h_TankHealthAdjust.BoolValue;
	g_bVersusCoop = h_VersusCoop.BoolValue;
	g_bJoinableTeams = h_JoinableTeams.BoolValue; bDisableSurvivorModelGlow = !g_bJoinableTeams;
	g_bCommonLimitAdjust = h_CommonLimitAdjust.BoolValue;
	h_SpawnDistanceMin.AddChangeHook(ConVarDistanceChanged);
	h_SpawnDistanceMax.AddChangeHook(ConVarDistanceChanged);
	h_SpawnDistanceFinal.AddChangeHook(ConVarDistanceChanged);
	h_Difficulty.AddChangeHook(ConVarDifficulty);
	h_MaxPlayerZombies.AddChangeHook(ConVarMaxPlayerZombies);
	h_TankHealthAdjust.AddChangeHook(ConVarTankHealthAdjust);
	h_VersusCoop.AddChangeHook(ConVarVersusCoop);
	h_JoinableTeams.AddChangeHook(ConVarCoopVersus);
	h_CommonLimitAdjust.AddChangeHook(hCommonLimitAdjustChanged);

	// Some of these events are being used multiple times. Although I copied Durzel's code, I felt this would make it more organized as there is a ton of code in events 
	// Such as PlayerDeath, PlayerSpawn and others.
	
	HookEvent("round_start", evtRoundStart);
	HookEvent("round_end", evtRoundEnd);
	HookEvent("map_transition", evtRoundEnd); //戰役過關到下一關的時候 (沒有觸發round_end)
	HookEvent("mission_lost", evtRoundEnd); //戰役滅團重來該關卡的時候 (之後有觸發round_end)
	HookEvent("finale_vehicle_leaving", evtRoundEnd); //救援載具離開之時  (沒有觸發round_end)
	// We hook some events ...
	HookEvent("player_death", evtPlayerDeath, EventHookMode_Pre);
	HookEvent("player_team", evtPlayerTeam);
	HookEvent("player_spawn", evtPlayerSpawn);
	HookEvent("create_panic_event", evtSurvivalStart);
	HookEvent("finale_start", evtFinaleStart);
	HookEvent("player_death", evtInfectedDeath);
	HookEvent("player_spawn", evtInfectedSpawn);
	HookEvent("player_hurt", evtInfectedHurt);
	HookEvent("player_team", evtTeamSwitch);
	HookEvent("player_death", evtInfectedWaitSpawn);
	HookEvent("ghost_spawn_time", evtInfectedWaitSpawn);
	HookEvent("spawner_give_item", evtUnlockVersusDoor);
	HookEvent("player_bot_replace", evtBotReplacedPlayer);
	HookEvent("player_first_spawn", evtPlayerFirstSpawned);
	HookEvent("player_entered_start_area", evtPlayerFirstSpawned);
	HookEvent("player_entered_checkpoint", evtPlayerFirstSpawned);
	HookEvent("player_transitioned", evtPlayerFirstSpawned);
	HookEvent("player_left_start_area", evtPlayerFirstSpawned);
	HookEvent("player_left_checkpoint", evtPlayerFirstSpawned);
	HookEvent("witch_spawn", Event_WitchSpawn);
	HookEvent("player_incapacitated", Event_Incap);
	HookEvent("player_ledge_grab", Event_Incap);
	HookEvent("player_now_it", Event_GotVomit);
	HookEvent("revive_success", Event_revive_success);//救起倒地的or 懸掛的
	HookEvent("player_ledge_release", Event_ledge_release);//懸掛的玩家放開了

	// Hook a sound
	AddNormalSoundHook(view_as<NormalSHook>(HookSound_Callback));
	
	//----- Zombie HP hooks ---------------------	
	//We store the special infected max HP values in an array and then hook the cvars used to modify them
	//just in case another plugin (or an admin) decides to modify them.  Whilst unlikely if we don't do
	//this then the HP percentages on the HUD will end up screwy, and since it's a one-time initialisation
	//when the plugin loads there's a trivial overhead.
	cvarZombieHP[0] = FindConVar("z_hunter_health");
	cvarZombieHP[1] = FindConVar("z_gas_health");
	cvarZombieHP[2] = FindConVar("z_exploding_health");
	if (L4D2Version)
	{
		cvarZombieHP[3] = FindConVar("z_spitter_health");
		cvarZombieHP[4] = FindConVar("z_jockey_health");
		cvarZombieHP[5] = FindConVar("z_charger_health");
	}
	cvarZombieHP[6] = FindConVar("z_tank_health");
	zombieHP[0] = cvarZombieHP[0].IntValue; 
	cvarZombieHP[0].AddChangeHook(cvarZombieHPChanged);
	zombieHP[1] = cvarZombieHP[1].IntValue; 
	cvarZombieHP[1].AddChangeHook(cvarZombieHPChanged);
	zombieHP[2] = cvarZombieHP[2].IntValue;
	cvarZombieHP[2].AddChangeHook(cvarZombieHPChanged);
	if (L4D2Version)
	{
		zombieHP[3] = cvarZombieHP[3].IntValue;
		cvarZombieHP[3].AddChangeHook(cvarZombieHPChanged);
		zombieHP[4] = cvarZombieHP[4].IntValue;
		cvarZombieHP[4].AddChangeHook(cvarZombieHPChanged);
		zombieHP[5] = cvarZombieHP[5].IntValue;
		cvarZombieHP[5].AddChangeHook(cvarZombieHPChanged);
	}
	zombieHP[6] = cvarZombieHP[6].IntValue;
	cvarZombieHP[6].AddChangeHook(cvarZombieHPChanged);
	
	// Create persistent storage for client HUD preferences 
	usrHUDPref = CreateTrie();

	Handle hGameConf = LoadGameConfigFile("l4dinfectedbots");
	if( hGameConf != null )
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "SetHumanSpec");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		hSpec = EndPrepSDKCall();
		if( hSpec == null)
			SetFailState("Could not prep the \"SetHumanSpec\" function.");

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "TakeOverBot");
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		hSwitch = EndPrepSDKCall();
		if( hSwitch == null)
			SetFailState("Could not prep the \"TakeOverBot\" function.");

		StartPrepSDKCall(SDKCall_Static);
		if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "NextBotCreatePlayerBot<Smoker>"))
			SetFailState("Unable to find NextBotCreatePlayerBot<Smoker> signature in gamedata file.");
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
		hCreateSmoker = EndPrepSDKCall();
		if (hCreateSmoker == null)
			SetFailState("Cannot initialize NextBotCreatePlayerBot<Smoker> SDKCall, signature is broken.") ;

		StartPrepSDKCall(SDKCall_Static);
		if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "NextBotCreatePlayerBot<Boomer>"))
			SetFailState("Unable to find NextBotCreatePlayerBot<Boomer> signature in gamedata file.");
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
		hCreateBoomer = EndPrepSDKCall();
		if (hCreateBoomer == null)
			SetFailState("Cannot initialize NextBotCreatePlayerBot<Boomer> SDKCall, signature is broken.") ;

		StartPrepSDKCall(SDKCall_Static);
		if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "NextBotCreatePlayerBot<Hunter>"))
			SetFailState("Unable to find NextBotCreatePlayerBot<Hunter> signature in gamedata file.");
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
		hCreateHunter = EndPrepSDKCall();
		if (hCreateHunter == null)
			SetFailState("Cannot initialize NextBotCreatePlayerBot<Hunter> SDKCall, signature is broken.") ;

		if(L4D2Version)
		{
			StartPrepSDKCall(SDKCall_Static);
			if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "NextBotCreatePlayerBot<Spitter>"))
				SetFailState("Unable to find NextBotCreatePlayerBot<Spitter> signature in gamedata file.");
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
			hCreateSpitter = EndPrepSDKCall();
			if (hCreateSpitter == null)
				SetFailState("Cannot initialize NextBotCreatePlayerBot<Spitter> SDKCall, signature is broken.") ;

			StartPrepSDKCall(SDKCall_Static);
			if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "NextBotCreatePlayerBot<Jockey>"))
				SetFailState("Unable to find NextBotCreatePlayerBot<Jockey> signature in gamedata file.");
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
			hCreateJockey = EndPrepSDKCall();
			if (hCreateJockey == null)
				SetFailState("Cannot initialize NextBotCreatePlayerBot<Jockey> SDKCall, signature is broken.") ;

			StartPrepSDKCall(SDKCall_Static);
			if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "NextBotCreatePlayerBot<Charger>"))
				SetFailState("Unable to find NextBotCreatePlayerBot<Charger> signature in gamedata file.");
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
			hCreateCharger = EndPrepSDKCall();
			if (hCreateCharger == null)
				SetFailState("Cannot initialize NextBotCreatePlayerBot<Charger> SDKCall, signature is broken.") ;
		}

		StartPrepSDKCall(SDKCall_Static);
		if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "NextBotCreatePlayerBot<Tank>"))
			SetFailState("Unable to find NextBotCreatePlayerBot<Tank> signature in gamedata file.");
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
		hCreateTank = EndPrepSDKCall();
		if (hCreateTank == null)
			SetFailState("Cannot initialize NextBotCreatePlayerBot<Tank> SDKCall, signature is broken.") ;
	}
	else
	{
		SetFailState("Unable to find l4dinfectedbots.txt gamedata file.");
	}
	delete hGameConf;

	// Removes the boundaries for z_max_player_zombies and notify flag
	int flags = FindConVar("z_max_player_zombies").Flags;
	SetConVarBounds(FindConVar("z_max_player_zombies"), ConVarBound_Upper, false);
	SetConVarFlags(FindConVar("z_max_player_zombies"), flags & ~FCVAR_NOTIFY);

	CreateTimer(1.0, PluginStart);

	//Autoconfig for plugin
	AutoExecConfig(true, "l4dinfectedbots");
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iBoomerLimit = h_BoomerLimit.IntValue;
	g_iSmokerLimit = h_SmokerLimit.IntValue;
	g_iHunterLimit = h_HunterLimit.IntValue;
	if(L4D2Version)
	{
		g_iSpitterLimit = h_SpitterLimit.IntValue;
		g_iJockeyLimit = h_JockeyLimit.IntValue;
		g_iChargerLimit = h_ChargerLimit.IntValue;
	}
	g_bSafeSpawn = h_SafeSpawn.BoolValue;
	g_iTankHealth = h_TankHealth.IntValue;
	g_iInfectedSpawnTimeMax = h_InfectedSpawnTimeMax.IntValue;
	g_iInfectedSpawnTimeMin = h_InfectedSpawnTimeMin.IntValue;
	g_bCoopPlayableTank = h_CoopPlayableTank.BoolValue;
	g_bJoinableTeamsAnnounce = h_JoinableTeamsAnnounce.BoolValue;
	g_bInfHUD = h_InfHUD.BoolValue;
	g_bAnnounce = h_Announce.BoolValue;
	g_fIdletime_b4slay = h_Idletime_b4slay.FloatValue;
	g_fInitialSpawn = h_InitialSpawn.FloatValue;
	g_iHumanCoopLimit = h_HumanCoopLimit.IntValue;
	g_bAdminJoinInfected = h_AdminJoinInfected.BoolValue;
	g_bAdjustSpawnTimes = h_AdjustSpawnTimes.BoolValue;
	g_iReducedSpawnTimesOnPlayer = h_ReducedSpawnTimesOnPlayer.IntValue;
	g_iZSDisableGamemode = h_ZSDisableGamemode.IntValue;
	g_iWitchPeriodMax = h_WitchPeriodMax.IntValue;
	g_iWitchPeriodMin = h_WitchPeriodMin.IntValue;
	g_fWitchKillTime = h_WitchKillTime.FloatValue;
	g_iSpawnTankProbability = h_SpawnTankProbability.IntValue;
	g_iCommonLimit = h_CommonLimit.IntValue;
}

public void ConVarMaxPlayerZombies(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iMaxPlayerZombies = h_MaxPlayerZombies.IntValue;
	iPlayersInSurvivorTeam = -1;
	CreateTimer(0.1, MaxSpecialsSet);
	CreateTimer(1.0, ColdDown_Timer,_,TIMER_FLAG_NO_MAPCHANGE);
}

public void ConVarTankHealthAdjust(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bTankHealthAdjust = h_TankHealthAdjust.BoolValue;
	if(g_bTankHealthAdjust) SetConVarInt(FindConVar("z_tank_health"), g_iTankHealth);
	else ResetConVar(FindConVar("z_tank_health"), true, true);
}

public void hCommonLimitAdjustChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bCommonLimitAdjust = h_CommonLimitAdjust.BoolValue;
	if(g_bCommonLimitAdjust) SetConVarInt(h_common_limit_cvar, g_iCommonLimit);
	else ResetConVar(h_common_limit_cvar, true, true);
}

public void ConVarGameMode(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GameModeCheck();
	
	TweakSettings();

	bDisableSurvivorModelGlow = true;
	char mode[64];
	h_GameMode.GetString(mode, sizeof(mode));
	for( int i = 1; i <= MaxClients; i++ ) 
	{
		RemoveSurvivorModelGlow(i);
		if(IsClientInGame(i) && !IsFakeClient(i)) SendConVarValue(i, h_GameMode, mode);
	}

	if(GameMode != 2 && g_bJoinableTeams)
	{
		bDisableSurvivorModelGlow = false;
		for( int i = 1; i <= MaxClients; i++ ) 
		{
			CreateSurvivorModelGlow(i);
			if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_INFECTED) SendConVarValue(i, h_GameMode, "versus");
		}	
	}
}

public void ConVarDifficulty(ConVar convar, const char[] oldValue, const char[] newValue)
{
	TankHealthCheck();
}

public void ConVarVersusCoop(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bVersusCoop = h_VersusCoop.BoolValue;
	if(GameMode == 2)
	{
		if (g_bVersusCoop)
		{
			SetConVarInt(FindConVar("vs_max_team_switches"), 0);
			if (L4D2Version)
			{
				SetConVarInt(FindConVar("sb_all_bot_game"), 1);
				SetConVarInt(FindConVar("allow_all_bot_survivor_team"), 1);
			}
			else
			{
				SetConVarInt(FindConVar("sb_all_bot_team"), 1);
			}
		}
		else
		{
			ResetConVar(FindConVar("vs_max_team_switches"), true, true);
			if (L4D2Version)
			{
				ResetConVar(FindConVar("sb_all_bot_game"), true, true);
				ResetConVar(FindConVar("allow_all_bot_survivor_team"), true, true);
			}
			else
			{
				ResetConVar(FindConVar("sb_all_bot_team"), true, true);
			}
		}
	}
}

public void ConVarDistanceChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{	
	GetSpawnDisConvars();
}

public void ConVarCoopVersus(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bJoinableTeams = h_JoinableTeams.BoolValue;
	if(GameMode != 2)
	{
		if (g_bJoinableTeams)
		{
			if (L4D2Version)
			{
				SetConVarInt(FindConVar("sb_all_bot_game"), 1);
				SetConVarInt(FindConVar("allow_all_bot_survivor_team"), 1);
			}
			else
			{
				SetConVarInt(FindConVar("sb_all_bot_team"), 1);
			}

			bDisableSurvivorModelGlow = false;
			for( int i = 1; i <= MaxClients; i++ ) CreateSurvivorModelGlow(i);
		}
		else
		{
			if (L4D2Version)
			{
				ResetConVar(FindConVar("sb_all_bot_game"), true, true);
				ResetConVar(FindConVar("allow_all_bot_survivor_team"), true, true);
			}
			else
			{
				ResetConVar(FindConVar("sb_all_bot_team"), true, true);
			}
			char mode[64];
			h_GameMode.GetString(mode, sizeof(mode));
			bDisableSurvivorModelGlow = true;
			for( int i = 1; i <= MaxClients; i++ )
			{
				if(IsClientInGame(i) && !IsFakeClient(i)) SendConVarValue(i, h_GameMode, mode);
				RemoveSurvivorModelGlow(i);
			}
		}
	}
}

void TweakSettings()
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
			if (L4D2Version)
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
			SetConVarInt(FindConVar("z_scrimmage_sphere"), 0);
		}
		case 2: // Versus, Better Versus Infected AI
		{
			// If the game is L4D 2...
			if (L4D2Version)
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
			SetConVarInt(FindConVar("hunter_leap_away_give_up_range"), 0);
			SetConVarInt(FindConVar("z_hunter_lunge_distance"), 5000);
			SetConVarInt(FindConVar("hunter_pounce_ready_range"), 1500);
			SetConVarFloat(FindConVar("hunter_pounce_loft_rate"), 0.055);
			if (g_bVersusCoop)
				SetConVarInt(FindConVar("vs_max_team_switches"), 0);
		}
		case 3: // Survival, Turns off the ability for the director to spawn infected bots in survival, MI 5
		{
			if (L4D2Version)
			{
				SetConVarInt(FindConVar("survival_max_smokers"), 0);
				SetConVarInt(FindConVar("survival_max_boomers"), 0);
				SetConVarInt(FindConVar("survival_max_hunters"), 0);
				SetConVarInt(FindConVar("survival_max_spitters"), 0);
				SetConVarInt(FindConVar("survival_max_jockeys"), 0);
				SetConVarInt(FindConVar("survival_max_chargers"), 0);
				SetConVarInt(FindConVar("survival_max_specials"), g_iMaxPlayerZombies);
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
				SetConVarInt(FindConVar("holdout_max_specials"), g_iMaxPlayerZombies);
				SetConVarInt(FindConVar("z_gas_limit"), 0);
				SetConVarInt(FindConVar("z_exploding_limit"), 0);
				SetConVarInt(FindConVar("z_hunter_limit"), 0);
			}
			SetConVarInt(FindConVar("z_scrimmage_sphere"), 0);
		}
	}
	
	//Some cvar tweaks
	SetConVarInt(FindConVar("z_attack_flow_range"), 50000);
	SetConVarInt(FindConVar("director_spectate_specials"), 1);
	SetConVarInt(FindConVar("z_spawn_flow_limit"), 50000);
	if (L4D2Version)
	{
		SetConVarInt(FindConVar("versus_special_respawn_interval"), 99999999);
	}
	#if DEBUG
	LogMessage("Tweaking Settings");
	#endif
	
}

void ResetCvars()
{
	#if DEBUG
	LogMessage("Plugin Cvars Reset");
	#endif

	if (GameMode == 1)
	{
		ResetConVar(FindConVar("z_scrimmage_sphere"), true, true);
		if (L4D2Version)
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
	else if (GameMode == 2)
	{
		if (L4D2Version)
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
		if (L4D2Version)
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
			ResetConVar(FindConVar("z_hunter_limit"), true, true);
		}
		ResetConVar(FindConVar("hunter_leap_away_give_up_range"), true, true);
		ResetConVar(FindConVar("z_hunter_lunge_distance"), true, true);
		ResetConVar(FindConVar("hunter_pounce_ready_range"), true, true);
		ResetConVar(FindConVar("hunter_pounce_loft_rate"), true, true);
		ResetConVar(FindConVar("z_scrimmage_sphere"), true, true);
	}
}

public Action evtRoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	// If round has started ...
	if (b_HasRoundStarted)
		return;

	b_LeftSaveRoom = false;
	b_HasRoundEnded = false;

	if(!b_HasRoundStarted && g_iPlayerSpawn == 1)
	{
		CreateTimer(0.5, PluginStart);
	}

	b_HasRoundStarted = true;
}

public Action PluginStart(Handle timer)
{
	//Check the GameMode
	GameModeCheck();
	
	if (GameMode == 0)
		return;

	for (int i = 1; i <= MaxClients; i++)
	{
		respawnDelay[i] = 0;
		PlayerLifeState[i] = false;
		TankWasSeen[i] = false;
		AlreadyGhosted[i] = false;
	}

	//reset some variables
	InfectedBotQueue = 0;
	TanksPlaying = 0;
	BotReady = 0;
	FinaleStarted = false;
	InitialSpawn = false;
	TempBotSpawned = false;
	SurvivalVersus = false;

	// Added a delay to setting MaxSpecials so that it would set correctly when the server first starts up
	CreateTimer(0.4, MaxSpecialsSet);
	
	// This little part is needed because some events just can't execute when another round starts.
	if (GameMode == 2 && g_bVersusCoop)
	{
		for (int i=1; i<=MaxClients; i++)
		{
			// We check if player is in game
			if (!IsClientInGame(i)) continue;
			// Check if client is survivor ...
			if (GetClientTeam(i)==TEAM_SURVIVORS)
			{
				// If player is a real player ... 
				if (!IsFakeClient(i))
				{
					ChangeClientTeam(i, TEAM_INFECTED);
				}
			}
		}
		
	}
	// Kill the player if they are infected and its not versus (prevents survival finale bug and player ghosts when there shouldn't be)
	if (GameMode != 2)
	{
		for (int i=1; i<=MaxClients; i++)
		{
			// We check if player is in game
			if (!IsClientInGame(i)) continue;
			// Check if client is infected ...
			if (GetClientTeam(i)==TEAM_INFECTED)
			{
				// If player is a real player ... 
				if (!IsFakeClient(i))
				{
					if (g_bJoinableTeams && g_bJoinableTeamsAnnounce)
					{
						CreateTimer(10.0, AnnounceJoinInfected, i, TIMER_FLAG_NO_MAPCHANGE);
					}
					if (IsPlayerGhost(i))
					{
						CreateTimer(0.1, Timer_InfectedKillSelf, i, TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}
	}
	
	// Check the Tank's health to properly display it in the HUD
	TankHealthCheck();
	// Start up TweakSettings
	TweakSettings();

	roundInProgress = true;
	if(infHUDTimer == null) infHUDTimer = CreateTimer(1.0, showInfHUD, _, TIMER_REPEAT);

	#if DEBUG
		PrintToChatAll("PluginStart()!");
	#endif
	if(PlayerLeftStartTimer == null) PlayerLeftStartTimer = CreateTimer(1.0, PlayerLeftStart, _, TIMER_REPEAT);

	if (g_bJoinableTeams && GameMode != 2 || g_bVersusCoop && GameMode == 2)
	{
		if (L4D2Version)
		{
			SetConVarInt(FindConVar("sb_all_bot_game"), 1);
			SetConVarInt(FindConVar("allow_all_bot_survivor_team"), 1);
		}
		else
		{
			SetConVarInt(FindConVar("sb_all_bot_team"), 1);
		}
	}

	iPlayersInSurvivorTeam = -1;
	if(g_bCommonLimitAdjust == true) SetConVarInt(h_common_limit_cvar, 0);
	CreateTimer(1.0,ColdDown_Timer,_,TIMER_FLAG_NO_MAPCHANGE);
}

public Action evtPlayerFirstSpawned(Event event, const char[] name, bool dontBroadcast) 
{
	// This event's purpose is to execute when a player first enters the server. This eliminates a lot of problems when changing variables setting timers on clients, among fixing many sb_all_bot_team
	// issues.
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!client || IsFakeClient(client) || PlayerHasEnteredStart[client])
		return;
	
	#if DEBUG
		PrintToChatAll("Player has spawned for the first time");
	#endif

	// Versus Coop code, puts all players on infected at start, delay is added to prevent a weird glitch
	
	if (GameMode == 2 && g_bVersusCoop)
		CreateTimer(0.1, Timer_VersusCoopTeamChanger, client, TIMER_FLAG_NO_MAPCHANGE);
	
	// Kill the player if they are infected and its not versus (prevents survival finale bug and player ghosts when there shouldn't be)
	if (GameMode != 2)
	{
		if (GetClientTeam(client)==TEAM_INFECTED)
		{
			if (IsPlayerGhost(client))
			{
				CreateTimer(0.1, Timer_InfectedKillSelf, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		if(g_bJoinableTeams && g_bJoinableTeamsAnnounce)
		{
			CreateTimer(10.0, AnnounceJoinInfected, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	PlayerHasEnteredStart[client] = true;
}

public Action Timer_VersusCoopTeamChanger(Handle Timer, int client)
{
	ChangeClientTeam(client, TEAM_INFECTED);
}

public Action Timer_InfectedKillSelf(Handle Timer, int client)
{
	if( client && IsClientInGame(client) && !IsFakeClient(client) )
	{
		PrintHintText(client,"[TS] %T","Not allowed to respawn",client);
		ForcePlayerSuicide(client);
	}
}

void GameModeCheck()
{
	#if DEBUG
	LogMessage("Checking Gamemode");
	#endif
	// We determine what the gamemode is
	char GameName[16];
	h_GameMode.GetString(GameName, sizeof(GameName));
	if (StrEqual(GameName, "survival", false))
		GameMode = 3;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false) || StrEqual(GameName, "mutation12", false) || StrEqual(GameName, "mutation13", false) || StrEqual(GameName, "mutation15", false) || StrEqual(GameName, "mutation11", false))
		GameMode = 2;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false) || StrEqual(GameName, "mutation3", false) || StrEqual(GameName, "mutation9", false) || StrEqual(GameName, "mutation1", false) || StrEqual(GameName, "mutation7", false) || StrEqual(GameName, "mutation10", false) || StrEqual(GameName, "mutation2", false) || StrEqual(GameName, "mutation4", false) || StrEqual(GameName, "mutation5", false) || StrEqual(GameName, "mutation14", false))
		GameMode = 1;
	else
		GameMode = 1;
}

void TankHealthCheck()
{
	char difficulty[100];
	h_Difficulty.GetString(difficulty, sizeof(difficulty));
	
	zombieHP[6] = cvarZombieHP[6].IntValue;
	if (GameMode == 2)
	{
		zombieHP[6] = RoundToFloor(cvarZombieHP[6].IntValue * 1.5);	// Tank health is multiplied by 1.5x in VS	
	}
	else if (StrContains(difficulty, "Easy", false) != -1)  
	{
		zombieHP[6] = RoundToFloor(cvarZombieHP[6].IntValue * 0.75);
	}
	else if (StrContains(difficulty, "Normal", false) != -1)
	{
		zombieHP[6] = cvarZombieHP[6].IntValue;
	}
	else if (StrContains(difficulty, "Hard", false) != -1 || StrContains(difficulty, "Impossible", false) != -1)
	{
		zombieHP[6] = RoundToFloor(cvarZombieHP[6].IntValue * 2.0);
	}
}

public Action MaxSpecialsSet(Handle Timer)
{
	SetConVarInt(FindConVar("z_max_player_zombies"), g_iMaxPlayerZombies);
	#if DEBUG
	LogMessage("Max Player Zombies Set");
	#endif
}


public Action evtRoundEnd (Event event, const char[] name, bool dontBroadcast) 
{
	// If round has not been reported as ended ..
	if (!b_HasRoundEnded)
	{
		for( int i = 1; i <= MaxClients; i++ )
			DeleteLight(i);
			
		// we mark the round as ended
		b_HasRoundEnded = true;
		b_HasRoundStarted = false;
		b_LeftSaveRoom = false;
		roundInProgress = false;
		g_iPlayerSpawn = 0;
		
		// This spawns a Survivor Bot so that the health bonus for the bots count (L4D only)
		if (!L4D2Version && GameMode == 2 && !RealPlayersOnSurvivors() && !AllSurvivorsDeadOrIncapacitated())
		{
			int bot = CreateFakeClient("Fake Survivor");
			ChangeClientTeam(bot,TEAM_SURVIVORS);
			DispatchKeyValue(bot,"classname","SurvivorBot");
			DispatchSpawn(bot);
			
			CreateTimer(0.1,kickbot,bot);
		}
		ResetTimer();
	}
	
}

public void OnMapStart()
{
	g_bMapStarted = true;
	CheckandPrecacheModel(MODEL_SMOKER);
	CheckandPrecacheModel(MODEL_BOOMER);
	CheckandPrecacheModel(MODEL_HUNTER);
	CheckandPrecacheModel(MODEL_SPITTER);
	CheckandPrecacheModel(MODEL_JOCKEY);
	CheckandPrecacheModel(MODEL_CHARGER);
	CheckandPrecacheModel(MODEL_TANK);

	GetSpawnDisConvars();

	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if(StrEqual("c6m1_riverbank", sMap, false))
		g_bSpawnWitchBride = true;

}

public void OnMapEnd()
{
	b_HasRoundStarted = false;
	b_HasRoundEnded = true;
	b_LeftSaveRoom = false;
	g_iPlayerSpawn = 0;
	roundInProgress = false;
	g_bMapStarted = false;
	g_bSpawnWitchBride = false;
	iPlayersInSurvivorTeam = 0;
	ResetTimer();
}

public Action PlayerLeftStart(Handle Timer)
{
	if (L4D_HasAnySurvivorLeftSafeArea() || g_bSafeSpawn)
	{	
		// We don't care who left, just that at least one did
		if (!b_LeftSaveRoom)
		{
			char GameName[16];
			h_GameMode.GetString(GameName, sizeof(GameName));
			if (StrEqual(GameName, "mutation15", false))
			{
				SurvivalVersus = true;
				SetConVarInt(FindConVar("survival_max_smokers"), 0);
				SetConVarInt(FindConVar("survival_max_boomers"), 0);
				SetConVarInt(FindConVar("survival_max_hunters"), 0);
				SetConVarInt(FindConVar("survival_max_jockeys"), 0);
				SetConVarInt(FindConVar("survival_max_spitters"), 0);
				SetConVarInt(FindConVar("survival_max_chargers"), 0);
				return Plugin_Continue; 
			}
			
			b_LeftSaveRoom = true;
			
			// We reset some settings
			canSpawnBoomer = true;
			canSpawnSmoker = true;
			canSpawnHunter = true;
			if (L4D2Version)
			{
				canSpawnSpitter = true;
				canSpawnJockey = true;
				canSpawnCharger = true;
			}
			InitialSpawn = true;
			
			// We check if we need to spawn bots
			CheckIfBotsNeeded(false);
			#if DEBUG
			LogMessage("Checking to see if we need bots");
			#endif
			CreateTimer(g_fInitialSpawn + 10.0, InitialSpawnReset, _, TIMER_FLAG_NO_MAPCHANGE);
			if(hSpawnWitchTimer == null) hSpawnWitchTimer = CreateTimer(float(GetRandomInt(g_iWitchPeriodMin, g_iWitchPeriodMax)), SpawnWitchAuto);
		}
		PlayerLeftStartTimer = null;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}



// This is hooked to the panic event, but only starts if its survival. This is what starts up the bots in survival.

public Action evtSurvivalStart(Event event, const char[] name, bool dontBroadcast) 
{
	if (GameMode == 3 || SurvivalVersus)
	{  
		// We don't care who left, just that at least one did
		if (!b_LeftSaveRoom)
		{
			#if DEBUG
			PrintToChatAll("A player triggered the survival event, spawning bots");
			#endif
			b_LeftSaveRoom = true;
			
			// We reset some settings
			canSpawnBoomer = true;
			canSpawnSmoker = true;
			canSpawnHunter = true;
			if (L4D2Version)
			{
				canSpawnSpitter = true;
				canSpawnJockey = true;
				canSpawnCharger = true;
			}
			InitialSpawn = true;
			
			// We check if we need to spawn bots
			CheckIfBotsNeeded(false);
			#if DEBUG
			LogMessage("Checking to see if we need bots");
			#endif
			CreateTimer(g_fInitialSpawn + 10.0, InitialSpawnReset, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

public Action InitialSpawnReset(Handle Timer)
{
	InitialSpawn = false;
}

public Action BotReadyReset(Handle Timer)
{
	BotReady = 0;
}

public Action evtUnlockVersusDoor(Event event, const char[] name, bool dontBroadcast) 
{
	if (L4D2Version || b_LeftSaveRoom || GameMode != 2 || RealPlayersOnInfected() || TempBotSpawned)
		return Plugin_Continue;
	
	#if DEBUG
	PrintToChatAll("Attempting to spawn tempbot");
	#endif
	int bot = CreateFakeClient("tempbot");
	if (bot != 0)
	{
		ChangeClientTeam(bot,TEAM_INFECTED);
		CreateTimer(0.1,kickbot,bot);
		TempBotSpawned = true;
	}
	else
	{
		LogError("Temperory Infected Bot was not spawned for the Versus Door Unlocker!");
	}
	
	return Plugin_Continue;
}

public Action InfectedBotBooterVersus(Handle Timer)
{
	//This is to check if there are any extra bots and boot them if necessary, excluding tanks, versus only
	if (GameMode == 2)
	{
		// current count ...
		int total;
		
		for (int i=1; i<=MaxClients; i++)
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
		if (total + InfectedBotQueue > g_iMaxPlayerZombies)
		{
			int kick = total + InfectedBotQueue - g_iMaxPlayerZombies; 
			int kicked = 0;
			
			// We kick any extra bots ....
			for (int i=1;(i<=MaxClients)&&(kicked < kick);i++)
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
							#if DEBUG
							LogMessage("Kicked a Bot");
							#endif
						}
					}
				}
			}
		}
	}
}

// This code, combined with Durzel's code, announce certain messages to clients when they first enter the server

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);

	// If is a bot, skip this function
	if (IsFakeClient(client))
		return;

	iPlayerTeam[client] = 1;
	
	// Durzel's code ***********************************************************************************
	char clientSteamID[32];
	int doHideHUD;
	
//	GetClientAuthString(client, clientSteamID, 32);
	
	// Try and find their HUD visibility preference
	int foundKey = GetTrieValue(usrHUDPref, clientSteamID, doHideHUD);
	if (foundKey)
	{
		if (doHideHUD)
		{
			// This user chose not to view the HUD at some point in the game
			hudDisabled[client] = 1;
		}
	}
	//else hudDisabled[client] = 1;
	// End Durzel's code **********************************************************************************
}

public Action CheckGameMode(int client, int args)
{
	if (client)
	{
		PrintToChat(client, "GameMode = %i", GameMode);
	}
}

public Action CheckQueue(int client, int args)
{
	if (client)
	{
		if (GameMode == 2)
			CountInfected();
		else
		CountInfected_Coop();
		
		PrintToChat(client, "InfectedBotQueue = %i, InfectedBotCount = %i, InfectedRealCount = %i", InfectedBotQueue, InfectedBotCount, InfectedRealCount);
	}
}

public Action JoinInfected(int client, int args)
{	
	if (client && (GameMode == 1 || GameMode == 3) && g_bJoinableTeams)
	{
		if ((g_bAdminJoinInfected && IsPlayerGenericAdmin(client)) || !g_bAdminJoinInfected)
		{
			if (HumansOnInfected() < g_iHumanCoopLimit)
			{
				ChangeClientTeam(client, TEAM_INFECTED);
				iPlayerTeam[client] = TEAM_INFECTED;
			}
			else
				PrintHintText(client, "The Infected Team is full.");
		}
	}
}

public Action JoinSurvivors(int client, int args)
{
	if (client && (GameMode == 1 || GameMode == 3))
	{
		SwitchToSurvivors(client);
	}
}

public Action ForceInfectedSuicide(int client, int args)
{
	if (client && GetClientTeam(client) == 3 && !IsFakeClient(client) && IsPlayerAlive(client) && !IsPlayerGhost(client))
	{
		int bGameMode = GameMode;
		if(bGameMode == 3) bGameMode = 4;
		if(bGameMode & g_iZSDisableGamemode)
		{
			PrintHintText(client,"[TS] %T","Not allowed to suicide during current mode",client);
			return Plugin_Handled;
		}

		if(GetEngineTime() - fPlayerSpawnEngineTime[client] < SUICIDE_TIME)
		{
			PrintHintText(client,"[TS] %T","Not allowed to suicide so quickly",client);
			return Plugin_Handled;
		}

		if( L4D2_GetSurvivorVictim(client) != -1 )
		{
			PrintHintText(client,"[TS] %T","Not allowed to suicide",client);
			return Plugin_Handled;
		}
		
		ForcePlayerSuicide(client);
	}

	return Plugin_Handled;
}

public Action Console_ZLimit(int client, int args)
{
	if (client == 0)
	{
		PrintToServer("[TS] sm_zlimit cannot be used by server.");
		return Plugin_Handled;
	}
	if(args > 1)
	{
		ReplyToCommand(client, "[TS] %T","Usage: sm_zlimit",client);		
		return Plugin_Handled;
	}
	if(args < 1) 
	{
		ReplyToCommand(client, "[TS] %T\n%T","Current Special Infected Limit",client, g_iMaxPlayerZombies,"Usage: sm_zlimit",client);	
		return Plugin_Handled;
	}
	
	char arg1[64];
	GetCmdArg(1, arg1, 64);
	if(IsInteger(arg1))
	{
		int newlimit = StringToInt(arg1);
		if(newlimit>30)
		{
			ReplyToCommand(client, "[TS] %T","why you need so many special infected?",client);
		}
		else if (newlimit<0)
		{
			ReplyToCommand(client, "[TS] %T","Usage: sm_zlimit",client);
		}
		else if(newlimit!=g_iMaxPlayerZombies)
		{
			g_iMaxPlayerZombies = newlimit;
			CreateTimer(0.1, MaxSpecialsSet);
			//C_PrintToChatAll("[{olive}TS{default}] {lightgreen}%N{default}: %t", client, "Special Infected Limit has been changed",newlimit);	
		}
		else
		{
			ReplyToCommand(client, "[TS] %T","Special Infected Limit is already",client, g_iMaxPlayerZombies);	
		}
		return Plugin_Handled;
	}
	else
	{
		ReplyToCommand(client, "[TS] %T","Usage: sm_zlimit",client);		
		return Plugin_Handled;
	}	
}

public Action Console_Timer(int client, int args)
{
	if (client == 0)
	{
		PrintToServer("[TS] sm_timer cannot be used by server.");
		return Plugin_Handled;
	}
	
	if(args > 2)
	{
		ReplyToCommand(client, "[TS] %T","Usage: sm_timer",client);		
		return Plugin_Handled;
	}
	if(args < 1) 
	{
		ReplyToCommand(client, "[TS] %T\n%T","Current Spawn Timer",client,g_iInfectedSpawnTimeMax,g_iInfectedSpawnTimeMin,"Usage: sm_timer",client );	
		return Plugin_Handled;
	}
	
	if(args == 1)
	{
		char arg1[64];
		GetCmdArg(1, arg1, 64);
		if(IsInteger(arg1))
		{
			int DD = StringToInt(arg1);
			
			if(DD<=0)
			{
				ReplyToCommand(client, "[TS] %T","Failed to set timer!",client);
			}
			else if (DD > 180)
			{
				ReplyToCommand(client, "[TS] %T","why so long?",client);
			}
			else
			{
				SetConVarInt(FindConVar("l4d_infectedbots_adjust_spawn_times"), 0);
				SetConVarInt(FindConVar("l4d_infectedbots_spawn_time_max"), DD);
				SetConVarInt(FindConVar("l4d_infectedbots_spawn_time_min"), DD);
				//C_PrintToChatAll("[{olive}TS{default}] {lightgreen}%N{default}: %t",client,"Bot Spawn Timer has been changed",DD,DD);	
			}
			return Plugin_Handled;
		}
		else
		{
			ReplyToCommand(client, "[TS] %T","Usage: sm_timer",client);		
			return Plugin_Handled;
		}	
	}
	else
	{
		char arg1[64];
		GetCmdArg(1, arg1, 64);
		char arg2[64];
		GetCmdArg(2, arg2, 64);
		if(IsInteger(arg1) && IsInteger(arg2))
		{
			int Max = StringToInt(arg2);
			int Min = StringToInt(arg1);
			if(Min>Max)
			{
				int temp = Max;
				Max = Min;
				Min = temp;
			}
			
			if(Max>180)
			{
				ReplyToCommand(client, "[TS] %T","why so long?",client);
			}
			else
			{
				SetConVarInt(FindConVar("l4d_infectedbots_adjust_spawn_times"), 0);
				SetConVarInt(FindConVar("l4d_infectedbots_spawn_time_max"), Max);
				SetConVarInt(FindConVar("l4d_infectedbots_spawn_time_min"), Min);
				//C_PrintToChatAll("[{olive}TS{green}] {lightgreen}%N{default}: %t",client,"Bot Spawn Timer has been changed",Min,Max);	
			}
			return Plugin_Handled;
		}
		else
		{
			ReplyToCommand(client, "[TS] %T","Usage: sm_timer",client);		
			return Plugin_Handled;
		}
	}
}

// Joining spectators is for developers only, commented in the final

public Action JoinSpectator(int client, int args)
{
	if ((client) && (g_bJoinableTeams))
	{
		ChangeClientTeam(client, TEAM_SPECTATOR);
	}
}

public Action AnnounceJoinInfected(Handle timer, int client)
{
	/*
	if (IsClientInGame(client) && (!IsFakeClient(client)))
	{
		if (g_bJoinableTeamsAnnounce && g_bJoinableTeams && GameMode != 2)
		{
			if(g_bAdminJoinInfected)
				//C_PrintToChat(client,"[{olive}TS{default}] %T","Join infected team in coop/survival/realism(adm only)",client);
			else
				//C_PrintToChat(client,"[{olive}TS{default}] %T","Join infected team in coop/survival/realism",client);
			//C_PrintToChat(client,"%T","Join survivor team",client);
		}
	}*/
}

public Action evtPlayerSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	// We get the client id and time
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	// If client is valid
	if (!client || !IsClientInGame(client)) return Plugin_Continue;
	
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		RemoveSurvivorModelGlow(client);
		CreateTimer(0.3, tmrDelayCreateSurvivorGlow, userid);
		CreateTimer(1.0, ColdDown_Timer,_,TIMER_FLAG_NO_MAPCHANGE);
	}

	if (GetClientTeam(client) != TEAM_INFECTED)
		return Plugin_Continue;
	
	if (IsPlayerTank(client))
	{
		char clientname[256];
		GetClientName(client, clientname, sizeof(clientname));
		if (L4D2Version && GameMode == 1 && IsFakeClient(client) && RealPlayersOnInfected() && StrContains(clientname, "Bot", false) == -1)
		{
			CreateTimer(0.1, TankBugFix, client);
		}
		if (b_LeftSaveRoom)
		{	
			#if DEBUG
			LogMessage("Tank Event Triggered");
			#endif

			TanksPlaying = 0;
			MaxPlayerTank = 0;
			for (int i=1;i<=MaxClients;i++)
			{
				// We check if player is in game
				if (!IsClientInGame(i)) continue;
				
				// Check if client is infected ...
				if (GetClientTeam(i)==TEAM_INFECTED)
				{
					// If player is a tank
					if (IsPlayerTank(i) && PlayerIsAlive(i))
					{
						TanksPlaying++;
						MaxPlayerTank++;
					}
				}
			}
			
			MaxPlayerTank = MaxPlayerTank + g_iMaxPlayerZombies;
			SetConVarInt(FindConVar("z_max_player_zombies"), MaxPlayerTank);
			#if DEBUG
			LogMessage("Incremented Max Zombies from Tank Spawn EVENT");
			#endif
			
			if (GameMode == 3)
			{
				if (IsFakeClient(client) && RealPlayersOnInfected())
				{
					if (L4D2Version && !AreTherePlayersWhoAreNotTanks() && g_bCoopPlayableTank && StrContains(clientname, "Bot", false) == -1 || L4D2Version && !g_bCoopPlayableTank && StrContains(clientname, "Bot", false) == -1)
					{
						CreateTimer(0.1, TankBugFix, client);
					}
					else if (g_bCoopPlayableTank && AreTherePlayersWhoAreNotTanks())
					{
						CreateTimer(0.5, TankSpawner, client);
						CreateTimer(0.6, kickbot, client);
					}
				}
			}
			else
			{
				MaxPlayerTank = g_iMaxPlayerZombies;
				SetConVarInt(FindConVar("z_max_player_zombies"), g_iMaxPlayerZombies);
			}
		}
	}
	else if (IsFakeClient(client))
	{
		delete FightOrDieTimer[client];
		FightOrDieTimer[client] = CreateTimer(g_fIdletime_b4slay, DisposeOfCowards, client);
	}

	// Turn on Flashlight for Infected player
	TurnFlashlightOn(client);
	
	// If its Versus and the bot is not a tank, make the bot into a ghost
	if (IsFakeClient(client) && GameMode == 2 && !IsPlayerTank(client))
		CreateTimer(0.1, Timer_SetUpBotGhost, client, TIMER_FLAG_NO_MAPCHANGE);


	return Plugin_Continue;
}

public Action evtBotReplacedPlayer(Event event, const char[] name, bool dontBroadcast) 
{
	// The purpose of using this event, is to prevent a bot from ghosting after the player leaves or joins another team
	
	int bot = GetClientOfUserId(event.GetInt("bot"));
	AlreadyGhostedBot[bot] = true;
}

public Action DisposeOfCowards(Handle timer, int coward)
{
	if (coward && IsClientInGame(coward) && IsFakeClient(coward) && GetClientTeam(coward) == TEAM_INFECTED && !IsPlayerTank(coward) && PlayerIsAlive(coward))
	{
		// Check to see if the infected thats about to be slain sees the survivors. If so, kill the timer and make a int one.
		if (GetEntProp(coward, Prop_Send, "m_hasVisibleThreats") || L4D2_GetSurvivorVictim(coward) != -1)
		{
			FightOrDieTimer[coward] = null;
			FightOrDieTimer[coward] = CreateTimer(g_fIdletime_b4slay, DisposeOfCowards, coward);
			return;
		}
		else
		{
			CreateTimer(0.1, kickbot, coward);	
			//PrintToChatAll("Kicked bot %N for not attacking", coward);
		}
	}
	FightOrDieTimer[coward] = null;
}

public Action Timer_SetUpBotGhost(Handle timer, int client)
{
	// This will set the bot a ghost, stop the bot's movement, and waits until it can spawn
	if (IsValidEntity(client))
	{
		if (!AlreadyGhostedBot[client])
		{
			SetGhostStatus(client, true);
			SetEntityMoveType(client, MOVETYPE_NONE);
			CreateTimer(h_BotGhostTime.FloatValue, Timer_RestoreBotGhost, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
			AlreadyGhostedBot[client] = false;
	}
}

public Action Timer_RestoreBotGhost(Handle timer, int client)
{
	if (IsValidEntity(client))
	{
		SetGhostStatus(client, false);
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
}

public Action evtPlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	// We get the client id and time
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client) DeleteLight(client); // Delete attached flashlight

	if(client && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVORS) 
	{
		RemoveSurvivorModelGlow(client);
		CreateTimer(1.0,ColdDown_Timer,_,TIMER_FLAG_NO_MAPCHANGE);
	}

	// If round has ended .. we ignore this
	if (b_HasRoundEnded || !b_LeftSaveRoom) return Plugin_Continue;
	
	delete FightOrDieTimer[client];
	
	
	if (!client || !IsClientInGame(client)) return Plugin_Continue;
	
	if (GetClientTeam(client) !=TEAM_INFECTED) return Plugin_Continue;
	
	if (IsPlayerTank(client))
	{
		TankWasSeen[client] = false;
	}
	
	// if victim was a bot, we setup a timer to spawn a int bot ...
	if (GetEventBool(event, "victimisbot") && GameMode == 2)
	{
		if (!IsPlayerTank(client))
		{
			int SpawnTime = GetRandomInt(g_iInfectedSpawnTimeMin, g_iInfectedSpawnTimeMax);
			if (g_bAdjustSpawnTimes && g_iMaxPlayerZombies != HumansOnInfected())
				SpawnTime = SpawnTime  - (TrueNumberOfAliveSurvivors() * g_iReducedSpawnTimesOnPlayer);
			
			if(SpawnTime < 0)
				SpawnTime = 1;
			#if DEBUG
			PrintToChatAll("playerdeath");
			#endif
			CreateTimer(float(SpawnTime), Spawn_InfectedBot, _, 0);
			InfectedBotQueue++;
		}
		
		#if DEBUG
		PrintToChatAll("An infected bot has been added to the spawn queue...");
		#endif
	}
	// This spawns a bot in coop/survival regardless if the special that died was controlled by a player, MI 5
	else if (GameMode != 2)
	{
		int SpawnTime = GetRandomInt(g_iInfectedSpawnTimeMin, g_iInfectedSpawnTimeMax);
		if (GameMode == 1 && g_bAdjustSpawnTimes)
			SpawnTime = SpawnTime - (TrueNumberOfAliveSurvivors() * g_iReducedSpawnTimesOnPlayer);
			
		if(!IsFakeClient(client)) 
		{
			SpawnTime = g_iInfectedSpawnTimeMin - TrueNumberOfAliveSurvivors() * g_iReducedSpawnTimesOnPlayer + (HumansOnInfected() - 1) * 3;
			if(SpawnTime <= 10)
				SpawnTime = 10;
		}

		if(SpawnTime <= 0)
			SpawnTime = 1;
		#if DEBUG
		PrintToChatAll("playerdeath2");
		#endif
		CreateTimer(float(SpawnTime), Spawn_InfectedBot);
		GetSpawnTime[client] = SpawnTime;
		InfectedBotQueue++;
		
		#if DEBUG
		PrintToChatAll("An infected bot has been added to the spawn queue...");
		#endif
	}
	
	//This will prevent the stats board from coming up if the cvar was set to 1 (L4D 1 only)
	if (!L4D2Version && !IsFakeClient(client) && !h_StatsBoard.BoolValue && GameMode != 2)
	{
		CreateTimer(1.0, ZombieClassTimer, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	// Removes Sphere bubbles in the map when a player dies
	if (GameMode != 2)
	{
		CreateTimer(0.1, ScrimmageTimer, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	// This fixes the spawns when the spawn timer is set to 5 or below and fixes the spitter spit glitch
	if (IsFakeClient(client) && !IsPlayerSpitter(client))
		CreateTimer(0.1, kickbot, client);
	
	return Plugin_Continue;
}

public Action ZombieClassTimer(Handle timer, int client)
{
	if (client)
	{
		SetEntProp(client, Prop_Send, "m_zombieClass", 0);
	}
}

public Action evtPlayerTeam(Event event, const char[] name, bool dontBroadcast) 
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	RemoveSurvivorModelGlow(client);
	CreateTimer(0.1, tmrDelayCreateSurvivorGlow, userid);

	CreateTimer(1.0, PlayerChangeTeamCheck,userid);//延遲一秒檢查

	// If player is a bot, we ignore this ...
	if (GetEventBool(event, "isbot")) return Plugin_Continue;
	
	// We get some data needed ...
	int newteam = event.GetInt("team");
	int oldteam = event.GetInt("oldteam");
	
	// We get the client id and time
	if(client) DeleteLight(client);

	// If player's new/old team is infected, we recount the infected and add bots if needed ...
	if (!b_HasRoundEnded && b_LeftSaveRoom && GameMode == 2)
	{
		if (oldteam == 3||newteam == 3)
		{
			CheckIfBotsNeeded(false);
		}
		if (newteam == 3)
		{
			//Kick Timer
			CreateTimer(1.0, InfectedBotBooterVersus, _, TIMER_FLAG_NO_MAPCHANGE);
			#if DEBUG
			LogMessage("A player switched to infected, attempting to boot a bot");
			#endif
		}
	}
	else if ((newteam == 3 || newteam == 1) && GameMode != 2)
	{
		// Removes Sphere bubbles in the map when a player joins the infected team, or spectator team
		
		CreateTimer(0.1, ScrimmageTimer, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action PlayerChangeTeamCheck(Handle timer,int userid)
{
	int client = GetClientOfUserId(userid);
	if (client && IsClientInGame(client) && !IsFakeClient(client))
	{
		CreateTimer(1.0,ColdDown_Timer,_,TIMER_FLAG_NO_MAPCHANGE);

		if(GameMode != 2)
		{
			int iTeam = GetClientTeam(client);
			if(iTeam == TEAM_INFECTED)
			{
				if(iPlayerTeam[client] != TEAM_INFECTED) 
				{
					ChangeClientTeam(client,TEAM_SPECTATOR);
					FakeClientCommand(client,"sm_js");
					return Plugin_Continue;
				}

				if(g_bJoinableTeams)
				{
					if((g_bAdminJoinInfected && IsPlayerGenericAdmin(client)) || !g_bAdminJoinInfected)
					{
						if (HumansOnInfected() <= g_iHumanCoopLimit)
						{
							//PrintToChatAll("%N Fake versus convar",client);
							SendConVarValue(client, h_GameMode, "versus");
							if(bDisableSurvivorModelGlow == true)
							{
								bDisableSurvivorModelGlow = false;
								for( int i = 1; i <= MaxClients; i++ )
								{
									CreateSurvivorModelGlow(i);
								}
							}

							return Plugin_Continue;
						}
					}
				}
				else
				{
					PrintHintText(client, "%T", "Can't Join The Infected Team.", client);
				}
				ChangeClientTeam(client,TEAM_SPECTATOR);
			}
			else
			{
				iPlayerTeam[client] = iTeam;
				char mode[64];
				h_GameMode.GetString(mode, sizeof(mode));
				SendConVarValue(client, h_GameMode, mode);

				if(!RealPlayersOnInfected() && bDisableSurvivorModelGlow == false)
				{
					bDisableSurvivorModelGlow = true;
					for( int i = 1; i <= MaxClients; i++ )
					{
						RemoveSurvivorModelGlow(i);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}
public Action ColdDown_Timer(Handle timer)
{
	int iAliveSurplayers = CheckAliveSurvivorPlayers_InSV();

	if(iAliveSurplayers >= 0 && iAliveSurplayers != iPlayersInSurvivorTeam)
	{
		int addition = iAliveSurplayers - 4;
		if(addition < 0) addition = 0;
		
		if(h_PlayerAddZombies.IntValue > 0) 
		{
			g_iMaxPlayerZombies = h_MaxPlayerZombies.IntValue + (h_PlayerAddZombies.IntValue * (addition/h_PlayerAddZombiesScale.IntValue));
			CreateTimer(0.1, MaxSpecialsSet);
		}
		if(g_bTankHealthAdjust)
		{
			SetConVarInt(cvarZombieHP[6], g_iTankHealth + (h_PlayerAddTankHealth.IntValue * (addition/h_PlayerAddTankHealthScale.IntValue)));
			if(g_bCommonLimitAdjust)
			{
				SetConVarInt(h_common_limit_cvar, g_iCommonLimit + (h_PlayerAddCommonLimit.IntValue * (addition/h_PlayerAddCommonLimitScale.IntValue)));
				//C_PrintToChatAll("[{olive}TS{default}] %t","Current status1",iAliveSurplayers,g_iMaxPlayerZombies,cvarZombieHP[6].IntValue,h_common_limit_cvar.IntValue);
			}
			else
			{
				SetConVarInt(h_common_limit_cvar, g_iCommonLimit);
				//C_PrintToChatAll("[{olive}TS{default}] %t","Current status3",iAliveSurplayers,g_iMaxPlayerZombies,cvarZombieHP[6].IntValue);
			}
		}
		else
		{
			if(g_bCommonLimitAdjust)
			{
				SetConVarInt(h_common_limit_cvar, g_iCommonLimit + h_PlayerAddCommonLimit.IntValue * (addition/h_PlayerAddCommonLimitScale.IntValue));
				//C_PrintToChatAll("[{olive}TS{default}] %t","Current status2",iAliveSurplayers,g_iMaxPlayerZombies,h_common_limit_cvar.IntValue);
			}
			else
			{
				SetConVarInt(h_common_limit_cvar, g_iCommonLimit);
				//C_PrintToChatAll("[{olive}TS{default}] %t","Current status4",iAliveSurplayers,g_iMaxPlayerZombies);	
			}
		}
		iPlayersInSurvivorTeam = iAliveSurplayers;
	}
}

public void OnClientDisconnect(int client)
{
	RemoveSurvivorModelGlow(client);
	
	if(roundInProgress == false) return;
		
	if(IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVORS)
		CreateTimer(1.0,ColdDown_Timer,_,TIMER_FLAG_NO_MAPCHANGE);

	if (IsClientInGame(client) && GetClientTeam(client) == TEAM_INFECTED && IsPlayerAlive(client))
	{
		char name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));

		int SpawnTime = GetRandomInt(g_iInfectedSpawnTimeMin, g_iInfectedSpawnTimeMax);
		if (g_bAdjustSpawnTimes)
			SpawnTime = SpawnTime - (TrueNumberOfAliveSurvivors() * g_iReducedSpawnTimesOnPlayer);
		
		if(SpawnTime<=0)
			SpawnTime = 1;
		#if DEBUG
		PrintToChatAll("OnClientDisconnect");
		#endif
		CreateTimer(float(SpawnTime), Spawn_InfectedBot);
		InfectedBotQueue++;
	}

	if (IsFakeClient(client))
		return;
	
	iPlayerTeam[client] = 1;
	// When a client disconnects we need to restore their HUD preferences to default for when 
	// a int client joins and fill the space.
	hudDisabled[client] = 0;
	clientGreeted[client] = 0;
	
	// Reset all other arrays
	respawnDelay[client] = 0;
	WillBeTank[client] = false;
	PlayerLifeState[client] = false;
	GetSpawnTime[client] = 0;
	TankWasSeen[client] = false;
	AlreadyGhosted[client] = false;
	PlayerHasEnteredStart[client] = false;
}

public Action ScrimmageTimer (Handle timer, int client)
{
	if (client && IsValidEntity(client))
	{
		SetEntProp(client, Prop_Send, "m_scrimmageType", 0);
	}
}

public Action CheckIfBotsNeededLater (Handle timer, bool spawn_immediately)
{
	CheckIfBotsNeeded(spawn_immediately);
}

void CheckIfBotsNeeded(bool spawn_immediately)
{
	if (b_HasRoundEnded || !b_LeftSaveRoom ) return;

	#if DEBUG
		PrintToChatAll("Checking bots");
	#endif 

	// First, we count the infected
	if (GameMode == 2)
	{
		CountInfected();
	}
	else
	{
		CountInfected_Coop();
	}
	
	// If we need more infected bots
	if ( (g_iMaxPlayerZombies - (InfectedBotCount + InfectedRealCount + InfectedBotQueue)) > 0)
	{
		if (spawn_immediately)
		{
			InfectedBotQueue++;
			#if DEBUG
			PrintToChatAll("spawn_immediately");
			#endif
			CreateTimer(0.1, Spawn_InfectedBot);
			#if DEBUG
			LogMessage("Setting up the bot now");
			#endif
		}
		else if (InitialSpawn) //round start first spawn 
		{
			InfectedBotQueue++;
			#if DEBUG
			PrintToChatAll("initial_spawn");
			#endif
			CreateTimer(g_fInitialSpawn, Spawn_InfectedBot);
			#if DEBUG
				PrintToChatAll("Setting up the initial bot now");
			#endif
		}
		else // server can't find a valid position, we use the normal time ..
		{
			#if DEBUG
			PrintToChatAll("InfectedBotQueue++");
			#endif
			InfectedBotQueue++;
			int SpawnTime = GetRandomInt(g_iInfectedSpawnTimeMin, g_iInfectedSpawnTimeMax);
			/*
			if (GameMode == 2 && g_bAdjustSpawnTimes)
				CreateTimer(float(SpawnTime - (TrueNumberOfAliveSurvivors() * g_iReducedSpawnTimesOnPlayer) ), Spawn_InfectedBot, _, 0);
			else if (GameMode == 1 && g_bAdjustSpawnTimes)
				CreateTimer(float(SpawnTime - (TrueNumberOfAliveSurvivors() * g_iReducedSpawnTimesOnPlayer) ), Spawn_InfectedBot, _, 0);
			else
				CreateTimer(float(SpawnTime), Spawn_InfectedBot);
			*/
			CreateTimer(float(SpawnTime), Spawn_InfectedBot);
		}
	}
}

void CountInfected()
{
	// reset counters
	InfectedBotCount = 0;
	InfectedRealCount = 0;
	
	// First we count the ammount of infected real players and bots
	for (int i=1;i<=MaxClients;i++)
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

// Note: This function is also used for coop/survival.
void CountInfected_Coop()
{
	#if DEBUG
	LogMessage("Counting Bots for Coop");
	#endif
	
	// reset counters
	InfectedBotCount = 0;
	InfectedRealCount = 0;
	
	// First we count the ammount of infected real players and bots
	
	for (int i=1;i<=MaxClients;i++)
	{
		// We check if player is in game
		if (!IsClientInGame(i)) continue;
		
		// Check if client is infected ...
		if (GetClientTeam(i) == TEAM_INFECTED)
		{
			char name[MAX_NAME_LENGTH];
			
			GetClientName(i, name, sizeof(name));
			
			// If someone is a tank and the tank is playable...count him in play
			if (IsPlayerTank(i) && PlayerIsAlive(i) && g_bCoopPlayableTank && !IsFakeClient(i))
			{
				InfectedRealCount++;
			}
			
			// If player is a bot ...
			if (IsFakeClient(i))
			{
				InfectedBotCount++;
				#if DEBUG
				LogMessage("Found a bot");
				#endif
			}
			else if (PlayerIsAlive(i) || (IsPlayerGhost(i)))
			{
				InfectedRealCount++;
				#if DEBUG
				LogMessage("Found a player");
				#endif
			}
		}
	}
}

public Action Event_WitchSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int witch = event.GetInt("witchid");
	CreateTimer(g_fWitchKillTime,KickWitch_Timer,EntIndexToEntRef(witch),TIMER_FLAG_NO_MAPCHANGE);
}

public Action Event_Incap(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client && !IsClientInGame(client) && GetClientTeam(client) != TEAM_SURVIVORS) return;

	int entity = g_iModelIndex[client];
	if( IsValidEntRef(entity) )
	{
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", 180 + (0 * 256) + (0 * 65536)); //Red
	}
}

public Action Event_revive_success(Event event, const char[] name, bool dontBroadcast)
{
	int subject = GetClientOfUserId(GetEventInt(event, "subject"));//被救的那位
	if(!subject && !IsClientInGame(subject) && GetClientTeam(subject) != TEAM_SURVIVORS) return;

	int entity = g_iModelIndex[subject];
	if( IsValidEntRef(entity) )
	{
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", 0 + (180 * 256) + (0 * 65536)); //Green
	}
}

public Action Event_ledge_release(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client && !IsClientInGame(client) && GetClientTeam(client) != TEAM_SURVIVORS) return;

	int entity = g_iModelIndex[client];
	if( IsValidEntRef(entity) )
	{
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", 0 + (180 * 256) + (0 * 65536)); //Green
	}
}

public Action Event_GotVomit(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client && !IsClientInGame(client) && GetClientTeam(client) != TEAM_SURVIVORS) return;

	int entity = g_iModelIndex[client];
	if( IsValidEntRef(entity) )
	{
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", 155 + (0 * 256) + (180 * 65536)); //Purple
		CreateTimer(20.0, RestoreColor_Timer, entity, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action RestoreColor_Timer(Handle timer, int entity)
{
	if( IsValidEntRef(entity) )
	{
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", 0 + (180 * 256) + (0 * 65536)); //Green
	}
}

public Action KickWitch_Timer(Handle timer, int ref)
{
	if(IsValidEntRef(ref))
	{
		int entity = EntRefToEntIndex(ref);
		if(IsWitch(entity))
		{
			bool bKill = true;
			float clientOrigin[3];
			float witchOrigin[3];
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", witchOrigin);
			for (int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVORS && IsPlayerAlive(i))
				{
					GetClientAbsOrigin(i, clientOrigin);
					if (GetVectorDistance(clientOrigin, witchOrigin, true) < Pow(h_SpawnDistanceMax.FloatValue,2.0))
					{
						bKill = false;
						break;
					}
				}
			}

			if(bKill) AcceptEntityInput(ref, "kill"); //remove witch
			else CreateTimer(g_fWitchKillTime,KickWitch_Timer,EntIndexToEntRef(entity),TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}
// The main Tank code, it allows a player to take over the tank when if allowed, and adds additional tanks if the tanks per spawn cvar was set.
public Action TankSpawner(Handle timer, int client)
{
	#if DEBUG
	LogMessage("Tank Spawner Triggred");
	#endif
	int Index[8];
	int IndexCount = 0;
	float position[3];
	int tankhealth;
	bool tankonfire;
	
	if (client && IsClientInGame(client))
	{
		tankhealth = GetClientHealth(client);
		GetClientAbsOrigin(client, position);
		if (GetEntProp(client, Prop_Data, "m_fFlags") & FL_ONFIRE && PlayerIsAlive(client))
			tankonfire = true;
	}
	
	if (g_bCoopPlayableTank)
	{
		for (int t=1;t<=MaxClients;t++)
		{
			// We check if player is in game
			if (!IsClientInGame(t)) continue;
			
			// Check if client is infected ...
			if (GetClientTeam(t)!=TEAM_INFECTED) continue;
			
			if (!IsFakeClient(t))
			{
				// If player is not a tank, or a dead one
				if (!IsPlayerTank(t) || (IsPlayerTank(t) && !PlayerIsAlive(t)))
				{
					IndexCount++; // increase count of valid targets
					Index[IndexCount] = t; //save target to index
					#if DEBUG
					PrintToChatAll("Client %i found to be valid Tank Choice", Index[IndexCount]);
					#endif
				}
			}	
		}
	}
	
	if (g_bCoopPlayableTank && IndexCount != 0 )
	{
		MaxPlayerTank--;
		#if DEBUG
		PrintToChatAll("Tank Kicked");
		#endif
		
		int tank = GetRandomInt(1, IndexCount);  // pick someone from the valid targets
		WillBeTank[Index[tank]] = true;
		
		#if DEBUG
		PrintToChatAll("Random Number pulled: %i, from %i", tank, IndexCount);
		PrintToChatAll("Client chosen to be Tank: %i", Index[tank]);
		#endif
		
		if (L4D2Version && IsPlayerJockey(Index[tank]))
		{
			// WE NEED TO DISMOUNT THE JOCKEY OR ELSE BAAAAAAAAAAAAAAAD THINGS WILL HAPPEN
			
			CheatCommand(Index[tank], "dismount");
		}
		
		ChangeClientTeam(Index[tank], TEAM_SPECTATOR);
		ChangeClientTeam(Index[tank], TEAM_INFECTED);
	}
	
	bool resetGhost[MAXPLAYERS+1];
	bool resetLife[MAXPLAYERS+1];
	
	if (g_bCoopPlayableTank && IndexCount != 0)
	{
		for (int i=1;i<=MaxClients;i++)
		{
			if ( IsClientInGame(i) && !IsFakeClient(i)) // player is connected and is not fake and it's in game ...
			{
				// If player is on infected's team and is dead ..
				if ((GetClientTeam(i)==TEAM_INFECTED) && WillBeTank[i] == false)
				{
					// If player is a ghost ....
					if (IsPlayerGhost(i))
					{
						resetGhost[i] = true;
						SetGhostStatus(i, false);
						#if DEBUG
						LogMessage("Player is a ghost, taking preventive measures to prevent the player from taking over the tank");
						#endif
					}
					else if (!PlayerIsAlive(i))
					{
						resetLife[i] = true;
						SetLifeState(i, false);
						#if DEBUG
						LogMessage("Dead player found, setting restrictions to prevent the player from taking over the tank");
						#endif
					}
				}
			}
		}
		
		// Find any human client and give client admin rights
		int anyclient = GetAnyClient();
		
		CheatCommand(anyclient, sSpawnCommand, "tank auto");
		
		// We restore the player's status
		for (int i=1;i<=MaxClients;i++)
		{
			if (resetGhost[i] == true)
				SetGhostStatus(i, true);
			if (resetLife[i] == true)
				SetLifeState(i, true);
			if (WillBeTank[i] == true)
			{
				if (client && IsClientInGame(i))
				{
					TeleportEntity(i, position, NULL_VECTOR, NULL_VECTOR);
					SetEntityHealth(i, tankhealth);
					if (tankonfire)
						CreateTimer(0.1, PutTankOnFireTimer, i, TIMER_FLAG_NO_MAPCHANGE);
					if (g_bCoopPlayableTank)
						TankWasSeen[i] = true;
				}
				WillBeTank[i] = false;
				Handle datapack = CreateDataPack();
				WritePackCell(datapack, tankhealth);
				WritePackCell(datapack, tankonfire);
				WritePackCell(datapack, i);
				CreateTimer(1.0, TankRespawner, datapack, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
			}
		}
		
		
		#if DEBUG
		if (IsPlayerTank(client) && IsFakeClient(client))
		{
			PrintToChatAll("Bot Tank Spawn Event Triggered");
		}
		else if (IsPlayerTank(client) && !IsFakeClient(client))
		{
			PrintToChatAll("Human Tank Spawn Event Triggered");
		}
		#endif
	}
	
	MaxPlayerTank = g_iMaxPlayerZombies;
	SetConVarInt(FindConVar("z_max_player_zombies"), g_iMaxPlayerZombies);
}


public Action TankRespawner(Handle timer, Handle datapack)
{
	// This function is used to check if the tank successfully spawned, and if not, respawn him
	
	// Reset the data pack
	ResetPack(datapack);
	
	int tankhealth = ReadPackCell(datapack);
	int tankonfire = ReadPackCell(datapack);
	int client = ReadPackCell(datapack);
	
	if (IsClientInGame(client) && IsFakeClient(client) && IsPlayerTank(client) && PlayerIsAlive(client))
	{
		CreateTimer(0.1, kickbot, client);
		return;
	}
	
	if (IsClientInGame(client) && IsPlayerTank(client) && PlayerIsAlive(client))
		return;
	
	WillBeTank[client] = true;
	
	bool resetGhost[MAXPLAYERS+1];
	bool resetLife[MAXPLAYERS+1];
	
	for (int i=1;i<=MaxClients;i++)
	{
		if ( IsClientInGame(i) && !IsFakeClient(i)) // player is connected and is not fake and it's in game ...
		{
			// If player is on infected's team and is dead ..
			if ((GetClientTeam(i)==TEAM_INFECTED) && WillBeTank[i] == false)
			{
				// If player is a ghost ....
				if (IsPlayerGhost(i))
				{
					resetGhost[i] = true;
					SetGhostStatus(i, false);
					#if DEBUG
					LogMessage("Player is a ghost, taking preventive measures to prevent the player from taking over the tank");
					#endif
				}
				else if (!PlayerIsAlive(i))
				{
					resetLife[i] = true;
					SetLifeState(i, false);
					#if DEBUG
					LogMessage("Dead player found, setting restrictions to prevent the player from taking over the tank");
					#endif
				}
			}
		}
	}
	
	// Find any human client and give client admin rights
	int anyclient = GetAnyClient();

	CheatCommand(anyclient, sSpawnCommand, "tank auto");

	
	// We restore the player's status
	for (int i=1;i<=MaxClients;i++)
	{
		if (resetGhost[i] == true)
			SetGhostStatus(i, true);
		if (resetLife[i] == true)
			SetLifeState(i, true);
		if (WillBeTank[i] == true && IsClientInGame(i))
		{
			if (client && IsClientInGame(i))
			{
				SetEntityHealth(i, tankhealth);
				if (tankonfire)
					CreateTimer(0.1, PutTankOnFireTimer, i, TIMER_FLAG_NO_MAPCHANGE);
				if (g_bCoopPlayableTank)
					TankWasSeen[i] = true;
			}
			WillBeTank[i] = false;
			Handle hpack = CreateDataPack();
			WritePackCell(hpack, tankhealth);
			WritePackCell(hpack, tankonfire);
			WritePackCell(hpack, i);
			CreateTimer(1.0, TankRespawner, hpack, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
		}
	}
}

public Action TankBugFix(Handle timer, int client)
{
	#if DEBUG
	LogMessage("Tank BugFix Triggred");
	#endif
	
	if (IsClientInGame(client) && IsFakeClient(client) && GetClientTeam(client) == 3)
	{
		int lifestate = GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_lifeState"));
		if (lifestate == 0)
		{
			int bot = SDKCall(hCreateTank, "Tank Bot"); //召喚坦克
			if (bot > 0 && IsValidClient(bot))
			{
				#if DEBUG
					PrintToChatAll("Ghost BugFix");
				#endif
				SetEntityModel(bot, MODEL_TANK);
				ChangeClientTeam(bot, TEAM_INFECTED);
				//SDKCall(hRoundRespawn, bot);
				SetEntProp(bot, Prop_Send, "m_usSolidFlags", 16);
				SetEntProp(bot, Prop_Send, "movetype", 2);
				SetEntProp(bot, Prop_Send, "deadflag", 0);
				SetEntProp(bot, Prop_Send, "m_lifeState", 0);
				//SetEntProp(bot, Prop_Send, "m_fFlags", 129);
				SetEntProp(bot, Prop_Send, "m_iObserverMode", 0);
				SetEntProp(bot, Prop_Send, "m_iPlayerState", 0);
				SetEntProp(bot, Prop_Send, "m_zombieState", 0);
				DispatchSpawn(bot);
				ActivateEntity(bot);

				float Origin[3], Angles[3];
				GetClientAbsOrigin(client, Origin);
				GetClientAbsAngles(client, Angles);
				KickClient(client);
				TeleportEntity(bot, Origin, Angles, NULL_VECTOR); //移動到相同位置
			}
		}	
	}
}

public Action PutTankOnFireTimer(Handle Timer, int client)
{
	if(client && IsClientInGame(client) && GetClientTeam(client) == TEAM_INFECTED)
		IgniteEntity(client, 9999.0);
}

public Action HookSound_Callback(int Clients[64], int &NumClients, char StrSample[PLATFORM_MAX_PATH], int &Entity)
{
	if (GameMode != 1 || !g_bCoopPlayableTank)
		return Plugin_Continue;

	//to work only on tank steps, its Tank_walk
	if (StrContains(StrSample, "Tank_walk", false) == -1) return Plugin_Continue;

	for (int i=1;i<=MaxClients;i++)
	{
		// We check if player is in game
		if (!IsClientInGame(i)) continue;
		
		// Check if client is infected ...
		if (GetClientTeam(i)==TEAM_INFECTED)
		{
			// If player is a tank
			if (IsPlayerTank(i) && PlayerIsAlive(i) && TankWasSeen[i] == false)
			{
				if (RealPlayersOnInfected() && AreTherePlayersWhoAreNotTanks())
				{
					CreateTimer(0.2, kickbot, i);
					CreateTimer(0.1, TankSpawner, i);
				}
			}
		}
	}
	return Plugin_Continue;
}


// This event serves to make sure the bots spawn at the start of the finale event. The director disallows spawning until the survivors have started the event, so this was
// definitely needed.
public Action evtFinaleStart(Event event, const char[] name, bool dontBroadcast) 
{
	FinaleStarted = true;
	CreateTimer(1.0, CheckIfBotsNeededLater, true);
}

int BotTypeNeeded()
{
	#if DEBUG
	LogMessage("Determining Bot type now");
	#endif
	#if DEBUG
	PrintToChatAll("Determining Bot type now");
	#endif
	
	// current count ...
	int boomers=0;
	int smokers=0;
	int hunters=0;
	int spitters=0;
	int jockeys=0;
	int chargers=0;
	int tanks=0;
	
	for (int i=1;i<=MaxClients;i++)
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
				else if (L4D2Version && IsPlayerSpitter(i))
					spitters++;	
				else if (L4D2Version && IsPlayerJockey(i))
					jockeys++;	
				else if (L4D2Version && IsPlayerCharger(i))
					chargers++;	
			}
		}
	}

	if  (L4D2Version)
	{
		if (tanks < h_TankLimit.IntValue && GetRandomInt(1, 100) < g_iSpawnTankProbability)
		{
			#if DEBUG
			LogMessage("Bot type returned Tank");
			#endif
			return 7;
		}
		else //spawn other S.I.
		{
			int random = GetRandomInt(1, 6);
			int i=0;
			while(i++<5)
			{
				if (random == 1)
				{
					if ((smokers < g_iSmokerLimit) && (canSpawnSmoker))
					{
						#if DEBUG
						LogMessage("Bot type returned Smoker");
						#endif
						return 1;
					}
					random++;
				}
				if (random == 2)
				{
					if ((boomers < g_iBoomerLimit) && (canSpawnBoomer))
					{
						#if DEBUG
						LogMessage("Bot type returned Boomer");
						#endif
						return 2;
					}
					random++;
				}
				if (random == 3)
				{
					if ((hunters < g_iHunterLimit) && (canSpawnHunter))
					{
						#if DEBUG
						LogMessage("Bot type returned Hunter");
						#endif
						return 3;
					}
					random++;
				}
				if (random == 4)
				{
					if ((spitters < g_iSpitterLimit) && (canSpawnSpitter))
					{
						#if DEBUG
						LogMessage("Bot type returned Spitter");
						#endif
						return 4;
					}
					random++;
				}
				if (random == 5)
				{
					if ((jockeys < g_iJockeyLimit) && (canSpawnJockey))
					{
						#if DEBUG
						LogMessage("Bot type returned Jockey");
						#endif
						return 5;
					}
					random++;
				}
				if (random == 6)
				{
					if ((chargers < g_iChargerLimit) && (canSpawnCharger))
					{
						#if DEBUG
						LogMessage("Bot type returned Charger");
						#endif
						return 6;
					}
					random = 1;
				}
			}
		}
	}
	else
	{
		if (tanks < h_TankLimit.IntValue && GetRandomInt(1, 100) < g_iSpawnTankProbability)
		{
			#if DEBUG
			LogMessage("Bot type returned Tank");
			#endif
			return 7;
		}
		else
		{
			int random = GetRandomInt(1, 3);
			
			int i=0;
			while(i++<10)
			{
				if (random == 1)
				{
					if ((smokers < g_iSmokerLimit) && (canSpawnSmoker)) // we need a smoker ???? can we spawn a smoker ??? is smoker bot allowed ??
					{
						#if DEBUG
						LogMessage("Returning Smoker");
						#endif
						return 1;
					}
					random++;
				}
				if (random == 2)
				{
					if ((boomers < g_iBoomerLimit) && (canSpawnBoomer))
					{
						#if DEBUG
						LogMessage("Bot type returned Boomer");
						#endif
						return 2;
					}
					random++;
				}
				if (random == 3)
				{
					if ((hunters < g_iHunterLimit) && (canSpawnHunter))
					{
						#if DEBUG
						LogMessage("Bot type returned Hunter");
						#endif
						return 3;
					}
					random=1;
				}
			}
		}
	}
	return 0;
	
}


public Action Spawn_InfectedBot(Handle timer)
{
	#if DEBUG
	PrintToChatAll("Spawn_InfectedBot(Handle timer)");
	#endif
	// If round has ended, we ignore this request ...
	if (b_HasRoundEnded || !b_LeftSaveRoom ) return;
	
	int Infected = g_iMaxPlayerZombies;
	
	if (h_Coordination.BoolValue && !InitialSpawn && !PlayerReady())
	{
		BotReady++;
		
		for (int i=1;i<=MaxClients;i++)
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
		//PrintToChatAll("BotReady: %d, Infected,: %d, InfectedBotQueue: %d",BotReady,Infected,InfectedBotQueue);
		if (BotReady >= Infected)
		{
			CreateTimer(3.0, BotReadyReset, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			if(InfectedBotQueue > 0) InfectedBotQueue--;
			if(!ThereAreNoInfectedBotsRespawnDelay()) return;
			/*if(ThereAreNoInfectedBotsRespawnDelay() && InfectedBotQueue >= 0)
			{
				PrintToChatAll("try to spawn bot");
				CreateTimer(0.2, Spawn_InfectedBot, _, TIMER_FLAG_NO_MAPCHANGE);
			}
			return;*/
		}
	}
	
	// First we get the infected count
	if (GameMode == 2)
	{
		CountInfected();
	}
	else
	{
		CountInfected_Coop();
	}
	// If infected's team is already full ... we ignore this request (a real player connected after timer started ) ..
	if ((InfectedRealCount + InfectedBotCount) >= g_iMaxPlayerZombies || (InfectedRealCount + InfectedBotCount + InfectedBotQueue) > g_iMaxPlayerZombies) 	
	{
		#if DEBUG
		LogMessage("We found a player, don't spawn a bot");
		#endif
		if(InfectedBotQueue>0) InfectedBotQueue--;
		return;
	}
	
	// If there is a tank on the field and l4d_infectedbots_spawns_disable_tank is set to 1, the plugin will check for
	// any tanks on the field
	
	if (h_DisableSpawnsTank.BoolValue)
	{
		for (int i=1;i<=MaxClients;i++)
		{
			// We check if player is in game
			if (!IsClientInGame(i)) continue;
			
			// Check if client is infected ...
			if (GetClientTeam(i)==TEAM_INFECTED)
			{
				// If player is a tank
				if (IsPlayerTank(i) && IsPlayerAlive(i) && ( (IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_hasVisibleThreats")) || !IsFakeClient(i) ))
				{
					if(InfectedBotQueue>0) InfectedBotQueue--;
					return;
				}
			}
		}
		
	}
	
	// Before spawning the bot, we determine if an real infected player is dead, since the int infected bot will be controlled by this player
	bool resetGhost[MAXPLAYERS+1];
	bool resetLife[MAXPLAYERS+1];
	bool binfectedfreeplayer = false;
	int bot = 0;
	for (int i=1;i<=MaxClients;i++)
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
					#if DEBUG
					LogMessage("Player is a ghost, taking preventive measures for spawning an infected bot");
					#endif
				}
				else if (!PlayerIsAlive(i) && GameMode == 2) // if player is just dead
				{
					resetLife[i] = true;
					SetLifeState(i, false);
				}
				else if (!PlayerIsAlive(i) && respawnDelay[i] > 0)
				{
					resetLife[i] = true;
					SetLifeState(i, false);
					#if DEBUG
					LogMessage("Found a dead player, spawn time has not reached zero, delaying player to Spawn an infected bot");
					#endif
				}
				else if (!PlayerIsAlive(i) && respawnDelay[i] <= 0)
				{
					AlreadyGhosted[i] = false;
					SetLifeState(i, true);
					binfectedfreeplayer = true;
					bot = i;
				}
				
			}
		}
	}
	
	// We get any client ....
	int anyclient = GetRandomClient();
	if(anyclient == 0)
	{
		PrintToServer("[TS] Couldn't find a valid alive survivor to spawn S.I. at this moment.",ZOMBIESPAWN_Attempts);
		CreateTimer(1.0, CheckIfBotsNeededLater, false);
		return;
	}

	// Determine the bot class needed ...
	int bot_type = BotTypeNeeded();

	if (binfectedfreeplayer)
	{		
		// We spawn the bot ...
		switch (bot_type)
		{
			case 0: // Nothing
			{
			}
			case 1: // Smoker
			{
				CheatCommand(anyclient, sSpawnCommand, "smoker auto");
			}
			case 2: // Boomer
			{	
				CheatCommand(anyclient, sSpawnCommand, "boomer auto");
			}
			case 3: // Hunter
			{
				CheatCommand(anyclient, sSpawnCommand, "hunter auto");
			}
			case 4: // Spitter
			{
				CheatCommand(anyclient, sSpawnCommand, "spitter auto");
			}
			case 5: // Jockey
			{
				CheatCommand(anyclient, sSpawnCommand, "jockey auto");
			}
			case 6: // Charger
			{
				CheatCommand(anyclient, sSpawnCommand, "charger auto");
			}
			case 7: // Tank
			{
				CheatCommand(anyclient, sSpawnCommand, "tank auto");
			}
		}
		if(IsPlayerAlive(bot)) CreateTimer(0.2, CheckIfBotsNeededLater, true);
		else CreateTimer(1.0, CheckIfBotsNeededLater, false);
	}
	else
	{
		bool bSpawnSuccessful = false;
		float vecPos[3];
		// We spawn the bot ...
		switch (bot_type)
		{
			case 0: // Nothing
			{
			}
			case 1: // Smoker
			{
				if(L4D_GetRandomPZSpawnPosition(anyclient,ZOMBIECLASS_SMOKER,ZOMBIESPAWN_Attempts,vecPos) == true)
				{
					bot = SDKCall(hCreateSmoker, "Smoker Bot");
					if (IsValidClient(bot))
					{
						SetEntityModel(bot, MODEL_SMOKER);
						bSpawnSuccessful = true;
					}					
				}
				else
				{
					PrintToServer("[TS] Couldn't find a Smoker Spawn position in %d tries",ZOMBIESPAWN_Attempts);
				}
			}
			case 2: // Boomer
			{	
				if(L4D_GetRandomPZSpawnPosition(anyclient,ZOMBIECLASS_BOOMER,ZOMBIESPAWN_Attempts,vecPos) == true)
				{
					bot = SDKCall(hCreateBoomer, "Boomer Bot");
					if (IsValidClient(bot))
					{
						SetEntityModel(bot, MODEL_BOOMER);
						bSpawnSuccessful = true;
					}					
				}
				else
				{
					PrintToServer("[TS] Couldn't find a Boomer Spawn position in %d tries",ZOMBIESPAWN_Attempts);
				}
			}
			case 3: // Hunter
			{
				if(L4D_GetRandomPZSpawnPosition(anyclient,ZOMBIECLASS_HUNTER,ZOMBIESPAWN_Attempts,vecPos) == true)
				{
					bot = SDKCall(hCreateHunter, "Hunter Bot");
					if (IsValidClient(bot))
					{
						SetEntityModel(bot, MODEL_HUNTER);
						bSpawnSuccessful = true;
					}					
				}
				else
				{
					PrintToServer("[TS] Couldn't find a Hunter Spawn position in %d tries",ZOMBIESPAWN_Attempts);
				}
			}
			case 4: // Spitter
			{
				if(L4D_GetRandomPZSpawnPosition(anyclient,ZOMBIECLASS_SPITTER,ZOMBIESPAWN_Attempts,vecPos) == true)
				{
					bot = SDKCall(hCreateSpitter, "Spitter Bot");
					if (IsValidClient(bot))
					{
						SetEntityModel(bot, MODEL_SPITTER);
						bSpawnSuccessful = true;
					}					
				}
				else
				{
					PrintToServer("[TS] Couldn't find a Spitter Spawn position in %d tries",ZOMBIESPAWN_Attempts);
				}
			}
			case 5: // Jockey
			{
				if(L4D_GetRandomPZSpawnPosition(anyclient,ZOMBIECLASS_JOCKEY,ZOMBIESPAWN_Attempts,vecPos) == true)
				{
					bot = SDKCall(hCreateJockey, "Jockey Bot");
					if (IsValidClient(bot))
					{
						SetEntityModel(bot, MODEL_JOCKEY);
						bSpawnSuccessful = true;
					}					
				}
				else
				{
					PrintToServer("[TS] Couldn't find a Jockey Spawn position in %d tries",ZOMBIESPAWN_Attempts);
				}
			}
			case 6: // Charger
			{
				if(L4D_GetRandomPZSpawnPosition(anyclient,ZOMBIECLASS_CHARGER,ZOMBIESPAWN_Attempts,vecPos) == true)
				{
					bot = SDKCall(hCreateCharger, "Charger Bot");
					if (IsValidClient(bot))
					{
						SetEntityModel(bot, MODEL_CHARGER);
						bSpawnSuccessful = true;
					}					
				}
				else
				{
					PrintToServer("[TS] Couldn't find a Charger Spawn position in %d tries",ZOMBIESPAWN_Attempts);
				}
			}
			case 7: // Tank
			{
				if(L4D_GetRandomPZSpawnPosition(anyclient,ZOMBIECLASS_TANK,ZOMBIESPAWN_Attempts,vecPos) == true)
				{
					bot = SDKCall(hCreateTank, "Tank Bot");
					if (IsValidClient(bot))
					{
						SetEntityModel(bot, MODEL_TANK);
						bSpawnSuccessful = true;
					}					
				}
				else
				{
					PrintToServer("[TS] Couldn't find a Tank Spawn position in %d tries",ZOMBIESPAWN_Attempts);
				}
			}
		}

		if (bSpawnSuccessful && IsValidClient(bot))
		{
			ChangeClientTeam(bot, 3);
			SetEntProp(bot, Prop_Send, "m_usSolidFlags", 16);
			SetEntProp(bot, Prop_Send, "movetype", 2);
			SetEntProp(bot, Prop_Send, "deadflag", 0);
			SetEntProp(bot, Prop_Send, "m_lifeState", 0);
			SetEntProp(bot, Prop_Send, "m_iObserverMode", 0);
			SetEntProp(bot, Prop_Send, "m_iPlayerState", 0);
			SetEntProp(bot, Prop_Send, "m_zombieState", 0);
			DispatchSpawn(bot);
			ActivateEntity(bot);
			TeleportEntity(bot, vecPos, NULL_VECTOR, NULL_VECTOR); //移動到相同位置
			CreateTimer(0.2, CheckIfBotsNeededLater, true);
		}
		else
		{
			CreateTimer(1.0, CheckIfBotsNeededLater, false);
		}
	}
	
	// We restore the player's status
	for (int i=1;i<=MaxClients;i++)
	{
		if (resetGhost[i] == true)
			SetGhostStatus(i, true);
		if (resetLife[i] == true)
			SetLifeState(i, true);
	}
	
	// Debug print
	#if DEBUG
	PrintToChatAll("Spawning an infected bot. Type = %i ", bot_type);
	#endif
	
	// We decrement the infected queue
	if(InfectedBotQueue>0) InfectedBotQueue--;
}

int GetAnyClient() 
{ 
	for (int target = 1; target <= MaxClients; target++) 
	{ 
		if (IsClientInGame(target)) return target; 
	} 
	return -1; 
}

public Action kickbot(Handle timer, int client)
{
	if (IsClientInGame(client) && (!IsClientInKickQueue(client)))
	{
		if (IsFakeClient(client)) KickClient(client);
	}
}

bool IsPlayerGhost (int client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost"))
		return true;
	return false;
}

bool PlayerIsAlive (int client)
{
	if (!GetEntProp(client,Prop_Send, "m_lifeState"))
		return true;
	return false;
}

bool IsPlayerSmoker (int client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_SMOKER)
		return true;
	return false;
}

bool IsPlayerHunter (int client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_HUNTER)
		return true;
	return false;
}

bool IsPlayerBoomer (int client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_BOOMER)
		return true;
	return false;
}

bool IsPlayerSpitter (int client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_SPITTER)
		return true;
	return false;
}

bool IsPlayerJockey (int client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_JOCKEY)
		return true;
	return false;
}

bool IsPlayerCharger (int client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_CHARGER)
		return true;
	return false;
}

bool IsPlayerTank (int client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_TANK)
		return true;
	return false;
}

void SetGhostStatus (int client, bool ghost)
{
	if (ghost)
		SetEntProp(client, Prop_Send, "m_isGhost", 1, 1);
	else
		SetEntProp(client, Prop_Send, "m_isGhost", 0, 1);
}

void SetLifeState (int client, bool ready)
{
	if (ready)
		SetEntProp(client, Prop_Send,  "m_lifeState", 1, 1);
	else
		SetEntProp(client, Prop_Send, "m_lifeState", 0, 1);
}

bool RealPlayersOnSurvivors ()
{
	for (int i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			if (GetClientTeam(i) == TEAM_SURVIVORS)
				return true;
		}
	return false;
}

int TrueNumberOfSurvivors ()
{
	int TotalSurvivors;
	for (int i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVORS)
				TotalSurvivors++;
	}
	return TotalSurvivors;
}

int TrueNumberOfAliveSurvivors ()
{
	int TotalSurvivors;
	for (int i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVORS && IsPlayerAlive(i))
				TotalSurvivors++;
	}
	return TotalSurvivors;
}

int HumansOnInfected ()
{
	int TotalHumans;
	for (int i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED && !IsFakeClient(i))
			TotalHumans++;
	}
	return TotalHumans;
}

bool AllSurvivorsDeadOrIncapacitated ()
{
	int PlayerIncap;
	int PlayerDead;
	
	for (int i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i))
			if (GetClientTeam(i) == TEAM_SURVIVORS)
		{
			if (GetEntProp(i, Prop_Send, "m_isIncapacitated"))
			{
				PlayerIncap++;
			}
			else if (!PlayerIsAlive(i))
			{
				PlayerDead++;
			}
		}
	}
	
	if (PlayerIncap + PlayerDead == TrueNumberOfSurvivors())
	{
		return true;
	}
	return false;
}

bool RealPlayersOnInfected ()
{
	for (int i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			if (GetClientTeam(i) == TEAM_INFECTED)
				return true;
		}
	return false;
}

bool AreTherePlayersWhoAreNotTanks ()
{
	for (int i=1;i<=MaxClients;i++)
	{	
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (GetClientTeam(i) == TEAM_INFECTED)
			{
				if (!IsPlayerTank(i) || IsPlayerTank(i) && !PlayerIsAlive(i))
					return true;
			}
		}
	}
	return false;
}

bool BotsAlive ()
{
	for (int i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i))
			if (GetClientTeam(i) == TEAM_INFECTED)
				return true;
		}
	return false;
}

bool PlayerReady()
{
	// First we count the ammount of infected real players
	for (int i=1;i<=MaxClients;i++)
	{
		// We check if player is in game
		if (!IsClientInGame(i)) continue;
		
		// Check if client is infected ...
		if (GetClientTeam(i) == TEAM_INFECTED)
		{
			// If player is a real player and is dead...
			if (!IsFakeClient(i) && !PlayerIsAlive(i))
			{
				if (!respawnDelay[i])
				{
					return true;
				}
			}
		}
	}
	return false;
}

int  FindBotToTakeOver()
{
	// First we find a survivor bot
	for (int i=1;i<=MaxClients;i++)
	{
		// We check if player is in game
		if (!IsClientInGame(i)) continue;
		
		// Check if client is survivor ...
		if (GetClientTeam(i) == TEAM_SURVIVORS)
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

//---------------------------------------------Durzel's HUD------------------------------------------

public void OnPluginEnd()
{
	ResetTimer();

	g_iPlayerSpawn = 0;

	for( int i = 1; i <= MaxClients; i++ )
	{
		RemoveSurvivorModelGlow(i);
		DeleteLight(i);
	}

	if (L4D2Version)
	{
		ResetConVar(FindConVar("survival_max_smokers"), true, true);
		ResetConVar(FindConVar("survival_max_boomers"), true, true);
		ResetConVar(FindConVar("survival_max_hunters"), true, true);
		ResetConVar(FindConVar("survival_max_spitters"), true, true);
		ResetConVar(FindConVar("survival_max_jockeys"), true, true);
		ResetConVar(FindConVar("survival_max_chargers"), true, true);
		ResetConVar(FindConVar("survival_max_specials"), true, true);
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
		ResetConVar(FindConVar("holdout_max_smokers"), true, true);
		ResetConVar(FindConVar("holdout_max_boomers"), true, true);
		ResetConVar(FindConVar("holdout_max_hunters"), true, true);
		ResetConVar(FindConVar("holdout_max_specials"), true, true);
		ResetConVar(FindConVar("z_gas_limit"), true, true);
		ResetConVar(FindConVar("z_exploding_limit"), true, true);
		ResetConVar(FindConVar("z_hunter_limit"), true, true);
	}
	ResetConVar(FindConVar("director_no_specials"), true, true);
	ResetConVar(FindConVar("hunter_leap_away_give_up_range"), true, true);
	ResetConVar(FindConVar("z_hunter_lunge_distance"), true, true);
	ResetConVar(FindConVar("hunter_pounce_ready_range"), true, true);
	ResetConVar(FindConVar("hunter_pounce_loft_rate"), true, true);
	ResetConVar(FindConVar("z_attack_flow_range"), true, true);
	ResetConVar(FindConVar("director_spectate_specials"), true, true);
	ResetConVar(FindConVar("z_spawn_safety_range"), true, true);
	ResetConVar(FindConVar("z_spawn_range"), true, true);
	ResetConVar(FindConVar("z_finale_spawn_safety_range"), true, true);
	if(L4D2Version) ResetConVar(FindConVar("z_finale_spawn_tank_safety_range"), true, true);
	ResetConVar(FindConVar("z_finale_spawn_mob_safety_range"), true, true);
	ResetConVar(FindConVar("z_spawn_flow_limit"), true, true);
	ResetConVar(FindConVar("z_tank_health"), true, true);
	ResetConVar(h_common_limit_cvar, true, true);
	ResetConVar(FindConVar("z_scrimmage_sphere"), true, true);
	ResetConVar(FindConVar("vs_max_team_switches"), true, true);
	if (!L4D2Version)
	{
		ResetConVar(FindConVar("sb_all_bot_team"), true, true);
	}
	else
	{
		ResetConVar(FindConVar("sb_all_bot_game"), true, true);
		ResetConVar(FindConVar("allow_all_bot_survivor_team"), true, true);
	}
	char mode[64];
	h_GameMode.GetString(mode, sizeof(mode));
	for( int i = 1; i <= MaxClients; i++ )
		if(IsClientInGame(i) && !IsFakeClient(i)) SendConVarValue(i, h_GameMode, mode);
	
	// Destroy the persistent storage for client HUD preferences
	delete usrHUDPref;
	
	#if DEBUG
	PrintToChatAll("\x01\x04[infhud]\x01 [%f] \x03Infected HUD\x01 stopped.", GetGameTime());
	#endif
}

public int Menu_InfHUDPanel(Menu menu, MenuAction action, int param1, int param2) { return; }

public Action TimerAnnounce(Handle timer, int client)
{
	if (IsClientInGame(client))
	{
		if (GetClientTeam(client) == TEAM_INFECTED)
		{
			// Show welcoming instruction message to client
			PrintHintText(client, "%t","Hud INFO", PLUGIN_VERSION);
			
			// This client now knows about the mod, don't tell them again for the rest of the game.
			clientGreeted[client] = 1;
		}
	}
}

public Action TimerAnnounce2(Handle timer, int client)
{
	if (IsClientInGame(client))
	{
		if (GetClientTeam(client) == TEAM_INFECTED && IsPlayerAlive(client))
		{
			C_PrintToChat(client, "[{olive}TS{default}] %T","sm_zs",client);
		}
	}
}


public void cvarZombieHPChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	// Handle a sysadmin modifying the special infected max HP cvars
	char cvarStr[255],difficulty[100];
	convar.GetName(cvarStr, sizeof(cvarStr));
	h_Difficulty.GetString(difficulty, sizeof(difficulty));
	
	#if DEBUG
	PrintToChatAll("\x01\x04[infhud]\x01 [%f] cvarZombieHPChanged(): Infected HP cvar '%s' changed from '%s' to '%s'", GetGameTime(), cvarStr, oldValue, newValue);
	#endif
	
	if (StrEqual(cvarStr, "z_hunter_health", false))
	{
		zombieHP[0] = StringToInt(newValue);
	}
	else if (StrEqual(cvarStr, "z_smoker_health", false))
	{
		zombieHP[1] = StringToInt(newValue);
	}
	else if (StrEqual(cvarStr, "z_boomer_health", false))
	{
		zombieHP[2] = StringToInt(newValue);
	}
	else if (L4D2Version && StrEqual(cvarStr, "z_spitter_health", false))
	{
		zombieHP[3] = StringToInt(newValue);
	}
	else if (L4D2Version && StrEqual(cvarStr, "z_jockey_health", false))
	{
		zombieHP[4] = StringToInt(newValue);
	}
	else if (L4D2Version && StrEqual(cvarStr, "z_charger_health", false))
	{
		zombieHP[5] = StringToInt(newValue);
	}
	else if (StrEqual(cvarStr, "z_tank_health", false) && GameMode == 2)
	{
		zombieHP[6] = RoundToFloor(StringToInt(newValue) * 1.5);	// Tank health is multiplied by 1.5x in VS
	}
	else if (StrEqual(cvarStr, "z_tank_health", false) && GameMode != 2 && StrContains(difficulty, "Easy", false) != -1)
	{
		zombieHP[6] = RoundToFloor(StringToInt(newValue) * 0.75);
	}
	else if (StrEqual(cvarStr, "z_tank_health", false) && GameMode != 2 && StrContains(difficulty, "Normal", false) != -1)
	{
		zombieHP[6] = RoundToFloor(StringToInt(newValue) * 1.0);
	}
	else if (StrEqual(cvarStr, "z_tank_health", false) && GameMode != 2 && StrContains(difficulty, "Hard", false) != -1)
	{
		zombieHP[6] = RoundToFloor(StringToInt(newValue) * 2.0);
	}
	else if (StrEqual(cvarStr, "z_tank_health", false) && GameMode != 2 && StrContains(difficulty, "Impossible", false) != -1)
	{
		zombieHP[6] = RoundToFloor(StringToInt(newValue) * 2.0);
	}
}

public Action monitorRespawn(Handle timer)
{
	// Counts down any active respawn timers
	int foundActiveRTmr = false;
	
	// If round has ended then end timer gracefully
	if (!roundInProgress)
	{
		respawnTimer = null;
		return Plugin_Stop;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (respawnDelay[i] > 0)
		{
			//PrintToChatAll("respawnDelay[i]--");
			respawnDelay[i]--;
			foundActiveRTmr = true;
		}
	}
	
	if (!foundActiveRTmr && respawnTimer != null)
	{
		// Being a ghost doesn't trigger an event which we can hook (player_spawn fires when player actually spawns),
		// so as a nasty kludge after the respawn timer expires for at least one player we set a timer for 1 second 
		// to update the HUD so it says "SPAWNING"
		if (delayedDmgTimer == null)
		{
			delayedDmgTimer = CreateTimer(1.0, delayedDmgUpdate);
		}
		
		// We didn't decrement any of the player respawn times, therefore we don't 
		// need to run this timer anymore.
		respawnTimer = null;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action delayedDmgUpdate(Handle timer) 
{
	delayedDmgTimer = null;
	ShowInfectedHUD(3);
}

public void queueHUDUpdate(int src)
{
	// queueHUDUpdate basically ensures that we're not constantly refreshing the HUD when there are one or more
	// timers active.  For example, if we have a respawn countdown timer (which is likely at any given time) then
	// there is no need to refresh 
	
	// Don't bother with infected HUD updates if the round has ended.
	if (!roundInProgress) return;
	
	if (respawnTimer == null)
	{
		ShowInfectedHUD(src);
		#if DEBUG
	}
	else
	{
		PrintToChatAll("\x01\x04[infhud]\x01 [%f] queueHUDUpdate(): Instant HUD update ignored, 1-sec timer active.", GetGameTime());
		#endif
	}	
}

public Action showInfHUD(Handle timer) 
{
	ShowInfectedHUD(1);
	return Plugin_Continue;
}

public Action Command_Say(int client, int args)
{
	char clientSteamID[32];
	//GetClientAuthString(client, clientSteamID, 32);
	
	if (g_bInfHUD)
	{
		if (!hudDisabled[client])
		{
			PrintToChat(client, "\x01\x04[infhud]\x01 %T","Hud Disable",client);
			SetTrieValue(usrHUDPref, clientSteamID, 1);
			hudDisabled[client] = 1;
		}
		else
		{
			PrintToChat(client, "\x01\x04[infhud]\x01 %T","Hud Enable",client);
			RemoveFromTrie(usrHUDPref, clientSteamID);
			hudDisabled[client] = 0;
		}
	}
	else
	{
		// Server admin has disabled Infected HUD server-wide
		PrintToChat(client, "\x01\x04[infhud]\x01 %T","Infected HUD is currently DISABLED",client);
	}	
	return Plugin_Handled;
}

public void ShowInfectedHUD(int src)
{
	if (!g_bInfHUD || IsVoteInProgress())
	{
		return;
	}
	
	// If no bots are alive, no point in showing the HUD
	if (GameMode == 2 && !BotsAlive())
	{
		return;
	}
	
	#if DEBUG
	char calledFunc[255];
	switch (src)
	{
		case 1: strcopy(calledFunc, sizeof(calledFunc), "showInfHUD");
		case 2: strcopy(calledFunc, sizeof(calledFunc), "monitorRespawn");
		case 3: strcopy(calledFunc, sizeof(calledFunc), "delayedDmgUpdate");
		case 4: strcopy(calledFunc, sizeof(calledFunc), "doomedTankCountdown");
		case 10: strcopy(calledFunc, sizeof(calledFunc), "queueHUDUpdate - client join");
		case 11: strcopy(calledFunc, sizeof(calledFunc), "queueHUDUpdate - team switch");
		case 12: strcopy(calledFunc, sizeof(calledFunc), "queueHUDUpdate - spawn");
		case 13: strcopy(calledFunc, sizeof(calledFunc), "queueHUDUpdate - death");
		case 14: strcopy(calledFunc, sizeof(calledFunc), "queueHUDUpdate - menu closed");
		case 15: strcopy(calledFunc, sizeof(calledFunc), "queueHUDUpdate - player kicked");
		case 16: strcopy(calledFunc, sizeof(calledFunc), "evtRoundEnd");
		default: strcopy(calledFunc, sizeof(calledFunc), "UNKNOWN");
	}
	
	PrintToChatAll("\x01\x04[infhud]\x01 [%f] ShowInfectedHUD() called by [\x04%i\x01] '\x03%s\x01'", GetGameTime(), src, calledFunc);
	#endif 
	
	int i, iHP;
	char iClass[100],lineBuf[100],iStatus[25];
	
	// Display information panel to infected clients
	pInfHUD = new Panel(GetMenuStyleHandle(MenuStyle_Radio));
	char information[32];
	if (GameMode == 2)
		Format(information, sizeof(information), "INFECTED BOTS(%s):", PLUGIN_VERSION);
	else
		Format(information, sizeof(information), "INFECTED TEAM(%s):", PLUGIN_VERSION);

	pInfHUD.SetTitle(information);
	pInfHUD.DrawItem(" ",ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	if (roundInProgress)
	{
		// Loop through infected players and show their status
		for (i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i)) continue;
			if (GetClientMenu(i) == MenuSource_RawPanel || GetClientMenu(i) == MenuSource_None)
			{
				if (GetClientTeam(i) == TEAM_INFECTED)
				{
					// Work out what they're playing as
					if (IsPlayerHunter(i))
					{
						strcopy(iClass, sizeof(iClass), "Hunter");
						iHP = RoundFloat((float(GetClientHealth(i)) / zombieHP[0]) * 100);
					}
					else if (IsPlayerSmoker(i))
					{
						strcopy(iClass, sizeof(iClass), "Smoker");
						iHP = RoundFloat((float(GetClientHealth(i)) / zombieHP[1]) * 100);
					}
					else if (IsPlayerBoomer(i))
					{
						strcopy(iClass, sizeof(iClass), "Boomer");
						iHP = RoundFloat((float(GetClientHealth(i)) / zombieHP[2]) * 100);
					}
					else if (L4D2Version && IsPlayerSpitter(i)) 
					{
						strcopy(iClass, sizeof(iClass), "Spitter");
						iHP = RoundFloat((float(GetClientHealth(i)) / zombieHP[3]) * 100);	
					}
					else if (L4D2Version && IsPlayerJockey(i)) 
					{
						strcopy(iClass, sizeof(iClass), "Jockey");
						iHP = RoundFloat((float(GetClientHealth(i)) / zombieHP[4]) * 100);	
					} 
					else if (L4D2Version && IsPlayerCharger(i)) 
					{
						strcopy(iClass, sizeof(iClass), "Charger");
						iHP = RoundFloat((float(GetClientHealth(i)) / zombieHP[5]) * 100);	
					} 
					else if (IsPlayerTank(i))
					{
						strcopy(iClass, sizeof(iClass), "Tank");
						iHP = RoundFloat((float(GetClientHealth(i)) / zombieHP[6]) * 100);
					}
					
					if (PlayerIsAlive(i))
					{
						// Check to see if they are a ghost or not
						if (IsPlayerGhost(i))
						{
							strcopy(iStatus, sizeof(iStatus), "GHOST");
						}
						else
						{
							if(IsPlayerTank(i) && !IsFakeClient(i)) Format(iStatus, sizeof(iStatus), "%i%% - %d%%", iHP,100-GetFrustration(i));
							else Format(iStatus, sizeof(iStatus), "%i%%", iHP);
						}
					}
					else
					{
						if (respawnDelay[i] > 0)
						{
							Format(iStatus, sizeof(iStatus), "DEAD (%i)", respawnDelay[i]);
							strcopy(iClass, sizeof(iClass), "");
							// As a failsafe if they're dead/waiting set HP to 0
							iHP = 0;
						} 
						else if (respawnDelay[i] == 0 && GameMode != 2)
						{
							Format(iStatus, sizeof(iStatus), "READY");
							strcopy(iClass, sizeof(iClass), "");
							// As a failsafe if they're dead/waiting set HP to 0
							iHP = 0;
						}
						else
						{
							Format(iStatus, sizeof(iStatus), "DEAD");
							strcopy(iClass, sizeof(iClass), "");
							// As a failsafe if they're dead/waiting set HP to 0
							iHP = 0;
						}
					}
					
					if (IsFakeClient(i))
					{
						Format(lineBuf, sizeof(lineBuf), "%N-%s", i, iStatus);
						pInfHUD.DrawItem(lineBuf);
					}
					else
					{
						Format(lineBuf, sizeof(lineBuf), "%N-%s-%s", i, iClass, iStatus);
						pInfHUD.DrawItem(lineBuf);
					}
				}
			}
			else
			{
				#if DEBUG
				PrintToChat(i, "x01\x04[infhud]\x01 [%f] Not showing infected HUD as vote/menu (%i) is active", GetClientMenu(i), GetGameTime());
				#endif
			}
		}
	}
	
	// Output the current team status to all infected clients
	// Technically the below is a bit of a kludge but we can't be 100% sure that a client status doesn't change
	// between building the panel and displaying it.
	for (i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if ( (GetClientTeam(i) == TEAM_INFECTED))
			{
				if(IsPlayerTank(i))
				{
					if(GetFrustration(i) >= 95 && GameMode != 2)
					{
						PrintHintText(i, "[TS] %T","You don't attack survivors",i);
						ForcePlayerSuicide(i);
						continue;
					}
				}
				
				if( hudDisabled[i] == 0 && (GetClientMenu(i) == MenuSource_RawPanel || GetClientMenu(i) == MenuSource_None))
				{	
					pInfHUD.Send(i, Menu_InfHUDPanel, 5);
				}
			}
		}
	}
	delete pInfHUD;
}

public Action evtTeamSwitch(Event event, const char[] name, bool dontBroadcast) 
{
	// Check to see if player joined infected team and if so refresh the HUD
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client)
	{
		if (GetClientTeam(client) == TEAM_INFECTED)
		{
			queueHUDUpdate(11);
		}
		else
		{
			// If player teamswitched to survivor, remove the HUD from their screen
			// immediately to stop them getting an advantage
			if (GetClientMenu(client) == MenuSource_RawPanel)
			{
				CancelClientMenu(client);
			}
		} 
	}
}

public Action evtInfectedSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	if(b_HasRoundStarted && g_iPlayerSpawn == 0)
	{
		CreateTimer(0.5, PluginStart);
	}
	g_iPlayerSpawn = 1;
	// Infected player spawned, so refresh the HUD
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client && IsClientInGame(client))
	{
		if (GetClientTeam(client) == TEAM_INFECTED)
		{
			queueHUDUpdate(12); 
			// If player joins server and doesn't have to wait to spawn they might not see the announce
			// until they next die (and have to wait).  As a fallback we check when they spawn if they've 
			// already seen it or not.
			if (!clientGreeted[client] && g_bAnnounce)
			{		
				CreateTimer(3.0, TimerAnnounce, client);	
			}
			if(!IsFakeClient(client) && IsPlayerAlive(client))
			{
				CreateTimer(5.0, TimerAnnounce2, client);	
				fPlayerSpawnEngineTime[client] = GetEngineTime();
			}
		}
	}
}

public Action evtInfectedDeath(Event event, const char[] name, bool dontBroadcast) 
{
	// Infected player died, so refresh the HUD
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client && IsClientConnected(client) && IsClientInGame(client))
	{
		if (GetClientTeam(client) == TEAM_INFECTED)
		{
			queueHUDUpdate(13);
		}
	}
}

public Action evtInfectedHurt(Event event, const char[] name, bool dontBroadcast) 
{
	// The life of a regular special infected is pretty transient, they won't take many shots before they 
	// are dead (unlike the survivors) so we can afford to refresh the HUD reasonably quickly when they take damage.
	// The exception to this is the Tank - with 5000 health the survivors could be shooting constantly at it 
	// resulting in constant HUD refreshes which is not efficient.  So, we check to see if the entity being 
	// shot is a Tank or not and adjust the non-repeating timer accordingly.
	
	// Don't bother with infected HUD update if the round has ended
	if (!roundInProgress) return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	delete FightOrDieTimer[client];
	FightOrDieTimer[client] = CreateTimer(g_fIdletime_b4slay, DisposeOfCowards, client);
	
	delete FightOrDieTimer[attacker];
	FightOrDieTimer[attacker] = CreateTimer(g_fIdletime_b4slay, DisposeOfCowards, attacker);
}

public Action evtInfectedWaitSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	// Don't bother with infected HUD update if the round has ended
	if (!roundInProgress) return;
	
	// Store this players respawn time in an array so we can present it to other clients
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client)
	{
		int timetowait;
		if (GameMode == 2 && !IsFakeClient(client))
		{	
			timetowait = event.GetInt("spawntime");
		}
		else if (GameMode != 2 && !IsFakeClient(client))
		{	
			//timetowait = GetSpawnTime[client];
			timetowait = g_iInfectedSpawnTimeMin - TrueNumberOfAliveSurvivors() * g_iReducedSpawnTimesOnPlayer + (HumansOnInfected() - 1) * 3;
			if(timetowait <= 8)
				timetowait = 8;

			//PrintToChatAll("evtInfectedWaitSpawn: %N - %d秒",client,timetowait);
		}
		else
		{	
			timetowait = GetSpawnTime[client];
		}
		
		respawnDelay[client] = timetowait;
		// Only start timer if we don't have one already going.
		if (respawnTimer == null) {
			// Note: If we have to start a int timer then there will be a 1 second delay before it starts, so 
			// subtract 1 from the pending spawn time
			respawnDelay[client] = (timetowait-1);
			respawnTimer = CreateTimer(1.0, monitorRespawn, _, TIMER_REPEAT);
		}
		// Send mod details/commands to the client, unless they have seen the announce already.
		// Note: We can't do this in OnClientPutInGame because the client may not be on the infected team
		// when they connect, and we can't put it in evtTeamSwitch because it won't register if the client
		// joins the server already on the Infected team.
		if (!clientGreeted[client] && g_bAnnounce)
		{
			CreateTimer(8.0, TimerAnnounce, client, TIMER_FLAG_NO_MAPCHANGE);	
		}
	}
}

void CheatCommand(int client,  char[] command, char[] arguments = "")
{
	int userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}


void TurnFlashlightOn(int client)
{
	if (GameMode == 2) return;
	if (!IsClientInGame(client)) return;
	if (GetClientTeam(client) != TEAM_INFECTED) return;
	if (!PlayerIsAlive(client)) return;
	if (IsFakeClient(client)) return;

	DeleteLight(client);

	// Declares
	int entity;
	float vOrigin[3], vAngles[3];

	// Position light
	vOrigin = view_as<float>(  { 0.5, -1.5, 50.0 });
	vAngles = view_as<float>(  { -45.0, -45.0, 90.0 });

	// Light_Dynamic
	entity = MakeLightDynamic(vOrigin, vAngles, client);
	g_iLightIndex[client] = EntIndexToEntRef(entity);

	if( g_iClientIndex[client] == GetClientUserId(client) )
	{
		SetEntProp(entity, Prop_Send, "m_clrRender", g_iClientColor[client]);
		AcceptEntityInput(entity, "TurnOff");
	}
	else
	{
		g_iClientIndex[client] = GetClientUserId(client);
		g_iClientColor[client] = GetEntProp(entity, Prop_Send, "m_clrRender");
		AcceptEntityInput(entity, "TurnOff");
	}

	entity = g_iLightIndex[client];
	if( !IsValidEntRef(entity) )
		return;

	// Specified colors
	char sTempL[12];
	Format(sTempL, sizeof(sTempL), "185 51 51");

	SetVariantEntity(entity);
	SetVariantString(sTempL);
	AcceptEntityInput(entity, "color");
	AcceptEntityInput(entity, "toggle");

	int color = GetEntProp(entity, Prop_Send, "m_clrRender");
	if( color != g_iClientColor[client] )
		AcceptEntityInput(entity, "turnon");
	g_iClientColor[client] = color;
}

void DeleteLight(int client)
{
	int entity = g_iLightIndex[client];
	g_iLightIndex[client] = 0;
	DeleteEntity(entity);
}

void DeleteEntity(int entity)
{
	if( IsValidEntRef(entity) )
		AcceptEntityInput(entity, "Kill");
}

int MakeLightDynamic(const float vOrigin[3], const float vAngles[3], int client)
{
	int entity = CreateEntityByName("light_dynamic");
	if( entity == -1)
	{
		LogError("Failed to create 'light_dynamic'");
		return 0;
	}

	char sTemp[16];
	Format(sTemp, sizeof(sTemp), "255 51 51 155");
	DispatchKeyValue(entity, "_light", sTemp);
	DispatchKeyValue(entity, "brightness", "1");
	DispatchKeyValueFloat(entity, "spotlight_radius", 0.0);
	DispatchKeyValueFloat(entity, "distance", 450.0);
	DispatchKeyValue(entity, "style", "0");
	DispatchSpawn(entity);
	AcceptEntityInput(entity, "TurnOn");

	// Attach to survivor
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", client);

	TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);
	return entity;
}

void SwitchToSurvivors(int client)
{
	if (GameMode == 2) return;
	if (!IsClientInGame(client)) return;
	if (GetClientTeam(client) == 2) return;
	if (IsFakeClient(client)) return;
	
	int bot = FindBotToTakeOver();
	
	if (bot == 0)
	{
		PrintHintText(client, "No alive survivor bots to take over.");
		return;
	}
	SDKCall(hSpec, bot, client);
	SDKCall(hSwitch, client, true);
	return;
}

public bool IsInteger(char[] buffer)
{
    int len = strlen(buffer);
    for (int i = 0; i < len; i++)
    {
        if ( !IsCharNumeric(buffer[i]) )
            return false;
    }

    return true;    
}

bool IsPlayerGenericAdmin(int client)
{
    if (CheckCommandAccess(client, "generic_admin", ADMFLAG_GENERIC, false))
    {
        return true;
    }

    return false;
}  

int CheckAliveSurvivorPlayers_InSV()
{
	int iPlayersInAliveSurvivors=0;
	for (int i = 1; i < MaxClients+1; i++)
		if(IsClientConnected(i)&&IsClientInGame(i)&&GetClientTeam(i) == TEAM_SURVIVORS && IsPlayerAlive(i))
			iPlayersInAliveSurvivors++;
	return iPlayersInAliveSurvivors;
}

bool IsWitch(int entity)
{
    if (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity))
    {
        char strClassName[64];
        GetEdictClassname(entity, strClassName, sizeof(strClassName));
        return StrEqual(strClassName, "witch");
    }
    return false;
}
// ====================================================================================================
//					SDKHOOKS TRANSMIT
// ====================================================================================================

void GetSpawnDisConvars()
{
	if(g_bMapStarted && L4D_IsMissionFinalMap())
	{	
		// Removes the boundaries for z_finale_spawn_safety_range and notify flag
		int flags = (FindConVar("z_finale_spawn_safety_range")).Flags;
		SetConVarBounds(FindConVar("z_finale_spawn_safety_range"), ConVarBound_Upper, false);
		SetConVarFlags(FindConVar("z_finale_spawn_safety_range"), flags & ~FCVAR_NOTIFY);
		SetConVarInt(FindConVar("z_finale_spawn_safety_range"),h_SpawnDistanceFinal.IntValue);
		
		if(L4D2Version)
		{
			// Removes the boundaries for z_finale_spawn_tank_safety_range and notify flag
			int flags2 = FindConVar("z_finale_spawn_tank_safety_range").Flags;
			SetConVarBounds(FindConVar("z_finale_spawn_tank_safety_range"), ConVarBound_Upper, false);
			SetConVarFlags(FindConVar("z_finale_spawn_tank_safety_range"), flags2 & ~FCVAR_NOTIFY);
			SetConVarInt(FindConVar("z_finale_spawn_tank_safety_range"),h_SpawnDistanceFinal.IntValue);

			// Add The last stand new convar "z_finale_spawn_mob_safety_range"
			int flags3 = FindConVar("z_finale_spawn_mob_safety_range").Flags;
			SetConVarBounds(FindConVar("z_finale_spawn_mob_safety_range"), ConVarBound_Upper, false);
			SetConVarFlags(FindConVar("z_finale_spawn_mob_safety_range"), flags3 & ~FCVAR_NOTIFY);
			SetConVarInt(FindConVar("z_finale_spawn_mob_safety_range"),h_SpawnDistanceFinal.IntValue);
		}
	}
	
	// Removes the boundaries for z_spawn_range and notify flag
	int flags3 = (FindConVar("z_spawn_range")).Flags;
	SetConVarBounds(FindConVar("z_spawn_range"), ConVarBound_Upper, false);
	SetConVarFlags(FindConVar("z_spawn_range"), flags3 & ~FCVAR_NOTIFY);
	
	// Removes the boundaries for z_spawn_safety_range and notify flag
	int flags4 = FindConVar("z_spawn_safety_range").Flags;
	SetConVarBounds(FindConVar("z_spawn_safety_range"), ConVarBound_Upper, false);
	SetConVarFlags(FindConVar("z_spawn_safety_range"), flags4 & ~FCVAR_NOTIFY);
	
	SetConVarInt(FindConVar("z_spawn_safety_range"),h_SpawnDistanceMin.IntValue);
	SetConVarInt(FindConVar("z_spawn_range"),h_SpawnDistanceMax.IntValue);
}

public Action SpawnWitchAuto(Handle timer)
{
	if( (FinaleStarted && h_WitchSpawnFinal.BoolValue == false) || b_HasRoundEnded) 
	{
		hSpawnWitchTimer = null;
		return;
	}
	
	float vecPos[3];
	int witches=0;
	int entity = -1;
	while ( ((entity = FindEntityByClassname(entity, "witch")) != -1) )
	{
		witches++;
	}

	int anyclient = GetRandomClient();
	if(anyclient == 0)
	{
		PrintToServer("[TS] Couldn't find a valid alive survivor to spawn witch at this moment.",ZOMBIESPAWN_Attempts);
	}
	else if (witches < h_WitchLimit.IntValue)
	{
		if(L4D_GetRandomPZSpawnPosition(anyclient,7,ZOMBIESPAWN_Attempts,vecPos) == true)
		{
			if( g_bSpawnWitchBride )
			{
				L4D2_SpawnWitchBride(vecPos,NULL_VECTOR);
			}
			else 
			{
				L4D2_SpawnWitch(vecPos,NULL_VECTOR);
			}
		}
		else
		{
			PrintToServer("[TS] Couldn't find a Witch Spawn position in %d tries", ZOMBIESPAWN_Attempts);
		}
	}

	int SpawnTime = GetRandomInt(g_iWitchPeriodMin, g_iWitchPeriodMax);
	hSpawnWitchTimer = CreateTimer(float(SpawnTime), SpawnWitchAuto);

	return;
}

int L4D2_GetSurvivorVictim(int client)
{
	int victim;

	if(L4D2Version)
	{
		/* Charger */
		victim = GetEntPropEnt(client, Prop_Send, "m_pummelVictim");
		if (victim > 0)
		{
			return victim;
		}

		victim = GetEntPropEnt(client, Prop_Send, "m_carryVictim");
		if (victim > 0)
		{
			return victim;
		}

		/* Jockey */
		victim = GetEntPropEnt(client, Prop_Send, "m_jockeyVictim");
		if (victim > 0)
		{
			return victim;
		}
	}

    /* Hunter */
	victim = GetEntPropEnt(client, Prop_Send, "m_pounceVictim");
	if (victim > 0)
	{
		return victim;
 	}

    /* Smoker */
 	victim = GetEntPropEnt(client, Prop_Send, "m_tongueVictim");
	if (victim > 0)
	{
		return victim;	
	}

	return -1;
}

public void L4D_OnEnterGhostState(int client)
{
	if(GameMode != 2)
	{
		DeleteLight(client);
		CreateTimer(0.2, Timer_InfectedKillSelf, client, TIMER_FLAG_NO_MAPCHANGE);
	}	
}

public bool ThereAreNoInfectedBotsRespawnDelay()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED && IsPlayerAlive(i) && GetEntProp(i,Prop_Send,"m_zombieClass") == ZOMBIECLASS_TANK && h_DisableSpawnsTank.BoolValue) 
		{
			if( (IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_hasVisibleThreats")) || !IsFakeClient(i) )
				return false;
		}
		if(respawnDelay[i] > 0)
			return false;
	}
	return true;
}

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	//if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}

void ResetTimer()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		PlayerHasEnteredStart[i] = false;
		delete FightOrDieTimer[i];
	}

	delete hSpawnWitchTimer;
	delete PlayerLeftStartTimer;
	delete infHUDTimer;
	delete respawnTimer;
	delete delayedDmgTimer;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damageType)
{
	if(GameMode == 2 || victim <= 0 || victim > MaxClients || !IsClientInGame(victim) || IsFakeClient(victim)) return Plugin_Continue;
	if(attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker) || IsFakeClient(attacker)) return Plugin_Continue;

	if(attacker == victim && GetClientTeam(attacker) == TEAM_INFECTED && GetEntProp(attacker,Prop_Send,"m_zombieClass") != ZOMBIECLASS_TANK) 
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action tmrDelayCreateSurvivorGlow(Handle timer, any client)
{
	CreateSurvivorModelGlow(GetClientOfUserId(client));
}

public void CreateSurvivorModelGlow(int client)
{
	if (!client || 
	!IsClientInGame(client) || 
	GetClientTeam(client) != TEAM_SURVIVORS || 
	!IsPlayerAlive(client) ||
	IsValidEntRef(g_iModelIndex[client]) == true ||
	GameMode == 2||
	g_bJoinableTeams == false ||
	bDisableSurvivorModelGlow == true ||
	b_HasRoundStarted == false) return;
	
	///////設定發光物件//////////
	// Get Client Model
	char sModelName[64];
	GetEntPropString(client, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));
	
	// Spawn dynamic prop entity
	int entity = CreateEntityByName("prop_dynamic_ornament");
	if (entity == -1) return;

	// Set new fake model
	SetEntityModel(entity, sModelName);
	DispatchSpawn(entity);

	// Set outline glow color
	SetEntProp(entity, Prop_Send, "m_CollisionGroup", 0);
	SetEntProp(entity, Prop_Send, "m_nSolidType", 0);
	SetEntProp(entity, Prop_Send, "m_nGlowRange", 4500);
	SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
	if(IsplayerIncap(client)) SetEntProp(entity, Prop_Send, "m_glowColorOverride", 180 + (0 * 256) + (0 * 65536)); //RGB
	else SetEntProp(entity, Prop_Send, "m_glowColorOverride", 0 + (180 * 256) + (0 * 65536)); //RGB
	AcceptEntityInput(entity, "StartGlowing");

	// Set model invisible
	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, 0, 0, 0, 0);
	
	// Set model attach to client, and always synchronize
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetAttached", client);
	///////發光物件完成//////////

	g_iModelIndex[client] = EntIndexToEntRef(entity);
		
	//model 只能給誰看?
	SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
}

public Action Hook_SetTransmit(int entity, int client)
{
	if( GetClientTeam(client) != TEAM_INFECTED)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

void RemoveSurvivorModelGlow(int client)
{
	int entity = g_iModelIndex[client];
	g_iModelIndex[client] = 0;

	if( IsValidEntRef(entity) )
		AcceptEntityInput(entity, "kill");
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

bool IsplayerIncap(int client)
{
	if(GetEntProp(client, Prop_Send, "m_isHangingFromLedge") || GetEntProp(client, Prop_Send, "m_isIncapacitated"))
		return true;

	return false;
}

int GetFrustration(int tank_index)
{
	return GetEntProp(tank_index, Prop_Send, "m_frustration");
}

int GetRandomClient()
{
	int iClientCount, iClients[MAXPLAYERS+1];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			iClients[iClientCount++] = i;
		}
	}
	return (iClientCount == 0) ? 0 : iClients[GetRandomInt(0, iClientCount - 1)];
}

void CheckandPrecacheModel(const char[] model)
{
	if (!IsModelPrecached(model))
	{
		PrecacheModel(model, true);
	}
}

///////////////////////////////////////////////////////////////////////////