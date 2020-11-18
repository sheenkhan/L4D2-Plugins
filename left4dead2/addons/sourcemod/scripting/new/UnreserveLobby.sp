#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

Handle sv_allow_lobby_connect_only = INVALID_HANDLE;
Handle mp_gamemode = INVALID_HANDLE;
Handle sv_maxplayers = INVALID_HANDLE;
Handle mode_name_to_client_count = INVALID_HANDLE;

public Plugin myinfo =
{
    name = "Remove Lobby Reservation",
    author = "Deximy, 闲月疏云",
    version = "1.0",
    url = "https://blog.deximy.xyz"
}

public OnPluginStart()
{
    RegAdminCmd("sm_unreserve", OnUnreserveLobby, ADMFLAG_GENERIC);

    sv_allow_lobby_connect_only = FindConVar("sv_allow_lobby_connect_only");
    sv_maxplayers = FindConVar("sv_maxplayers");
    mp_gamemode = FindConVar("mp_gamemode");
    
    HookConVarChange(sv_maxplayers, OnMaxPlayerChange);
    
    mode_name_to_client_count = CreateTrie();
    SetTrieValue(mode_name_to_client_count, "coop", 4);
    SetTrieValue(mode_name_to_client_count, "versus", 8);
    SetTrieValue(mode_name_to_client_count, "survival", 4);
    SetTrieValue(mode_name_to_client_count, "scavenge", 8);
    SetTrieValue(mode_name_to_client_count, "realism", 4);
    SetTrieValue(mode_name_to_client_count, "community5", 4);
}

public Action OnUnreserveLobby(int client, int args)
{
    L4D_LobbyUnreserve();
    SetConVarBool(sv_allow_lobby_connect_only, false);
    return Plugin_Continue;
}

public void OnClientPutInServer(client)
{
    if (ShouldUnreserveLobby())
    {
        SetConVarBool(sv_allow_lobby_connect_only, false);
        L4D_LobbyUnreserve();
    }
}

public void OnModeUnLoad()
{
    SetConVarBool(sv_allow_lobby_connect_only, true);
}

public OnMaxPlayerChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (ShouldUnreserveLobby())
    {
        SetConVarBool(sv_allow_lobby_connect_only, false);
        L4D_LobbyUnreserve();
    }
}

bool ShouldUnreserveLobby()
{
    int client_count = GetRealClientCount();
    return client_count == GetModeMaxPlayer() || client_count == GetConVarInt(sv_maxplayers);
}

int GetModeMaxPlayer()
{
    char mode_name[32];
    GetConVarString(mp_gamemode, mode_name, sizeof(mode_name));
    int count = 0;
    GetTrieValue(mode_name_to_client_count, mode_name, count);
    return count;
}

int GetRealClientCount()
{
    int count = 0;
    for (int i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && !IsFakeClient(i))
            count++;
    return count + 1;
}