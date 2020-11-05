#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.6"
	
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

ConVar BlockSecondaryDrop;
ConVar BlockM60Drop;
ConVar BlockDropMidAction;

public Plugin myinfo =
{
	name = "[L4D2] Weapon Drop",
	author = "Machine, dcx2, Electr000999 /z, Senip, Shao",
	description = "Allows players to drop the weapon they are holding.",
	version = PLUGIN_VERSION,
	url = "www.AlliedMods.net"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_drop", Command_Drop);
	RegConsoleCmd("sm_g", Command_Drop);
	CreateConVar("sm_drop_version", PLUGIN_VERSION, "[L4D2] Weapon Drop Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	BlockSecondaryDrop = CreateConVar ("block_secondary_drop", "1" , "Prevent players from dropping their secondaries? (Fixes bugs that can come with incapped weapons or A-Posing.)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	BlockM60Drop = CreateConVar ("block_m60_drop", "1" , "Prevent players from dropping the M60? (Allows for better compatibility with certain plugins.)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	BlockDropMidAction = CreateConVar ("block_drop_mid_action", "1" , "Prevent players from dropping objects in between actions? (Fixes throwable cloning.)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	LoadTranslations("common.phrases");
	
	AutoExecConfig(true, "l4d2_drop");
}

public Action Command_Drop(int client, int args)
{
	if (args > 2)
	{
		if (GetAdminFlag(GetUserAdmin(client), Admin_Root))
			ReplyToCommand(client, "[SM] Usage: sm_drop <#userid|name> <slot to drop>");
	}
	else if (args == 0)
	{
		DropActiveWeapon(client);
	}
	else if (args > 0)
	{
		if (GetAdminFlag(GetUserAdmin(client), Admin_Root))
		{
			char target[MAX_TARGET_LENGTH], arg[8];
			GetCmdArg(1, target, sizeof(target));
			GetCmdArg(2, arg, sizeof(arg));
			int slot = StringToInt(arg);
			int targetid = FindTarget(client, target);
			if (targetid > 0 && IsClientInGame(targetid))
			{
				if(slot > 0)
					DropSlot(targetid, slot);
				else
					DropActiveWeapon(targetid);
					
				return Plugin_Handled;
			}

			char target_name[MAX_TARGET_LENGTH];
			int target_list[MAXPLAYERS], target_count; 
			bool tn_is_ml;
	
			if ((target_count = ProcessTargetString(
				target,
				client,
				target_list,
				MAXPLAYERS,
				0,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			for (int i=0; i<target_count; i++)
			{
				if(slot > 0)
					DropSlot(target_list[i], slot);
				else
					DropActiveWeapon(target_list[i]);
			}
		}
	}
	return Plugin_Handled;
}

public void DropSlot(int client, int slot)
{
	if (IsValidSurvivor(client) && IsPlayerAlive(client))
	{
		slot--;
		int weapon = GetPlayerWeaponSlot(client, slot);
		if (IsValidEnt(weapon))
		{
			if (DropBlocker(weapon))
			{
				DropWeapon(client, weapon);
			}
		}
	}
}

void DropActiveWeapon(int client)
{
	if (IsValidSurvivor(client) && IsPlayerAlive(client))
	{
		int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

		if (IsValidEnt(weapon))
		{
			if (DropBlocker(weapon) != -1)
			{
				DropWeapon(client, weapon);
			}
		}
	}
}

stock int DropBlocker(int weapon)
{
	char classname[32];
	GetEntityClassname(weapon, classname, sizeof(classname));

	if (BlockSecondaryDrop.BoolValue)
	{
		if (StrEqual(classname, "weapon_chainsaw") || StrEqual(classname, "weapon_pistol") || StrEqual(classname, "weapon_pistol_magnum") || StrEqual(classname, "weapon_melee"))
		{
			return -1;
		}
	}
	if (BlockM60Drop.BoolValue)
	{
		if(StrEqual(classname, "weapon_rifle_m60"))
		{
			return -1;
		}
	}
	return weapon;
}

void DropWeapon(int client, int weapon)
{
	if (BlockDropMidAction.BoolValue)
	{
		if (GetEntPropFloat(weapon,Prop_Data,"m_flNextPrimaryAttack") >= GetGameTime())
		{
			return;
		}
	}

	int ammo = GetPlayerReserveAmmo(client, weapon);
	SDKHooks_DropWeapon(client, weapon);
	SetPlayerReserveAmmo(client, weapon, 0);
	SetEntProp(weapon, Prop_Send, "m_iExtraPrimaryAmmo", ammo);

	char classname[32];
	GetEntityClassname(weapon, classname, sizeof(classname));
	
	if (StrEqual(classname, "weapon_defibrillator"))
	{
		int modelindex = GetEntProp(weapon, Prop_Data, "m_nModelIndex");
		SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", modelindex);
	}
	else if (StrEqual(classname, "weapon_rifle_m60"))
	{
		if (GetEntProp(weapon, Prop_Data, "m_iClip1") == 0)
			SetEntProp(weapon, Prop_Send, "m_iClip1", 1);
	}
}

//https://forums.alliedmods.net/showthread.php?t=260445
stock void SetPlayerReserveAmmo(int client, int weapon, int ammo){
	int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammotype >= 0 ) {
		SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, ammotype);
		ChangeEdictState(client, FindDataMapInfo(client, "m_iAmmo"));
	}
}

stock int GetPlayerReserveAmmo(int client, int weapon) {
	int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if(ammotype >= 0){
		return GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
	}
	return 0;
}

stock bool IsValidSpect(int client){ 
	return (IsValidClient(client) && GetClientTeam(client) == 1 );
}

stock bool IsValidSurvivor(int client){
	return (IsValidClient(client) && GetClientTeam(client) == 2 );
}

stock bool IsValidInfected(int client){
	return (IsValidClient(client) && GetClientTeam(client) == 3 );
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}

stock bool IsValidEnt(int entity)
{
	return (entity > 0 && entity > MaxClients  && IsValidEntity(entity) && entity != INVALID_ENT_REFERENCE);
}