#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define DEFAULT_FOV 90
#define MAX_FOV 120
#define MESSAGE_PREFIX "[\x02Redline\x01]"

char usage[] = "sm_fov <value>";
int g_Fov[MAXPLAYERS+1] = DEFAULT_FOV;
int g_CFov[MAXPLAYERS+1] = DEFAULT_FOV;

public Plugin myinfo =
{
    name = "[SM] Field of View",
    description = "Allows a client to modify their FOV.",
    author = "B3none",
    version = "1.2.0",
    url = "https://github.com/b3none"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_fov", Command_Fov, usage);
    
    HookEvent("player_spawn", Player_Spawn, EventHookMode_PostNoCopy);
}

public Action Command_Fov(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, usage);
        
        return Plugin_Handled;
    }

    char arg[64];
    GetCmdArg(1, arg, sizeof(arg));
    
    int fov = StringToInt(arg);
    
    if (IsValidClient(client))
    {
        g_Fov[client] = fov;
    }

    ReplyToCommand(client, "%s Your FOV has been updated.", MESSAGE_PREFIX);

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
        if (!IsValidClient(i) || !IsPlayerAlive(i))
        {
        	continue;	
        }
        
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
