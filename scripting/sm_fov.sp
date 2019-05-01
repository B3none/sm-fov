#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define DEFAULT_FOV 75

char usage[] = "sm_fov <#userid|name> <value>";
int g_Fov[MAXPLAYERS+1] = DEFAULT_FOV;
int g_CFov[MAXPLAYERS+1] = DEFAULT_FOV;

public Plugin myinfo =
{
    name = "[SM] Field of View",
    description = "Allows a client to modify their FOV.",
    author = "B3none",
    version = "1.1.0",
    url = "https://github.com/b3none"
};

public void OnPluginStart()
{
    RegAdminCmd("sm_fov", Command_Fov, ADMFLAG_SLAY, usage);
    
    HookEvent("player_spawn", Player_Spawn, EventHookMode_PostNoCopy);
}

public Action Command_Fov(int client, int args)
{
    if (args < 2)
    {
        ReplyToCommand(client, usage);
        
        return Plugin_Handled;
    }

    char arg[65];
    GetCmdArg(1, arg, sizeof(arg));
    
    char Sarg2[65];
    GetCmdArg(2, Sarg2, sizeof(Sarg2));
    
    int arg2 = StringToInt(Sarg2);

    char target_name[MAX_TARGET_LENGTH];
    int target_list[MAXPLAYERS], target_count;
    bool tn_is_ml;

    if ((target_count = ProcessTargetString(
            arg,
            client,
            target_list,
            MAXPLAYERS,
            COMMAND_FILTER_CONNECTED,
            target_name,
            sizeof(target_name),
            tn_is_ml)) <= 0)
    {
        if (IsValidClient(client))
        {
        	ReplyToTargetError(client, target_count);
        }
        
        return Plugin_Handled;
    }

    for (int i = 0; i < target_count; i++)
    {
        int target = target_list[i];
        if (IsValidClient(target)) {
            g_Fov[target] = arg2;
        }
    }

    if (tn_is_ml)
    {
        ShowActivity2(client, "[SM] ", "Changed FOV on target", target_name);
    }
    else
    {
        ShowActivity2(client, "[SM] ", "Changed FOV on target", "_s", target_name);
    }

    return Plugin_Handled;
}

public Action Player_Spawn(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    
    g_CFov[client] = g_Fov[client];
    
    SetEntProp(client, Prop_Send, "m_iFOV", g_CFov[client]);
    SetEntProp(client, Prop_Send, "m_iDefaultFOV", g_CFov[client]);
}

public void OnGameFrame()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && IsPlayerAlive(i))
        {
            int fov = g_CFov[i];
            if (fov != g_Fov[i])
            {
                int fov2 = fov + (g_Fov[i] - fov) / 4;
                
                if (fov2 == fov && g_Fov[i] > fov2)
                {
                	fov2 += 1;
                }
                
                if (fov2 == fov && g_Fov[i] < fov2)
                {
                	fov2 -= 1;
                }
                
                g_CFov[i] = fov2;
                SetEntProp(i, Prop_Send, "m_iFOV", g_CFov[i]);
                SetEntProp(i, Prop_Send, "m_iDefaultFOV", g_CFov[i]);
            }
        }
    }
}

public void OnClientPutInServer(int client)
{
    g_Fov[client] = DEFAULT_FOV;
    g_CFov[client] = DEFAULT_FOV;
}

public void OnClientDisconnect(int client)
{
    g_Fov[client] = DEFAULT_FOV;
    g_CFov[client] = DEFAULT_FOV;
}

stock bool IsValidClient(int client)
{
    return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client);
}
