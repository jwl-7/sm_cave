#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <multicolors>

#pragma newdecls required
#pragma semicolon 1

#define MAX_LOCS 128

static ArrayList g_aPosition[MAXPLAYERS+1];
static ArrayList g_aAngles[MAXPLAYERS+1];
static ArrayList g_aVelocity[MAXPLAYERS+1];
static int g_iCurrLoc[MAXPLAYERS+1];

static bool g_bLocMenuOpen[MAXPLAYERS+1];

public Plugin myinfo =
{
    name        = "SaveLoc",
    author      = "JWL",
    description = "saveloc/loadloc",
    version     = "1.0",
    url         = ""
};

// ====[ EVENTS ]====
public void OnPluginStart()
{
    RegConsoleCmd("sm_saveloc", Command_SaveLoc, "Save location/velocity. Usage: !saveloc");
    RegConsoleCmd("sm_loadloc", Command_LoadLoc, "Load location/velocity. Usage: !loadloc <#id>");
    RegConsoleCmd("sm_locmenu", Command_LocMenu, "Show locations in menu. Usage: !locmenu");

    for (int i = 1; i <= MaxClients; i++) 
    {
        g_aPosition[i] = new ArrayList(3);
        g_aAngles[i] = new ArrayList(3);
        g_aVelocity[i] = new ArrayList(3);
    }
}

public void OnMapStart() 
{
    for (int i = 1; i <= MaxClients; i++)
    {
        ClearClientLocations(i);
    }
}

public void OnClientConnected(int client) 
{
    ClearClientLocations(client);
}

public void OnClientDisconnect_Post(int client)
{
    ClearClientLocations(client);
}

// ====[ COMMANDS ]====
public Action Command_SaveLoc(int client, int args)
{
    if (!client) 
    {
        return Plugin_Handled;
    }

    float position[3];
    float angles[3];
    float velocity[3];

    GetClientAbsOrigin(client, position);
    GetClientEyeAngles(client, angles);
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
    SaveLocation(client, position, angles, velocity);

    return Plugin_Handled;
}

public Action Command_LoadLoc(int client, int args)
{
    if (!client) 
    {
        return Plugin_Handled;
    }
    if (GetClientTeam(client) == CS_TEAM_SPECTATOR)
    {
        CPrintToChat(client, "[{green}SaveLoc{default}] {grey}You must join a team to use {purple}!loadloc");
        return Plugin_Handled;
    }
    if (!IsPlayerAlive(client))
    {
        CPrintToChat(client, "[{green}SaveLoc{default}] {grey}You must be alive to use {purple}!loadloc");
        return Plugin_Handled;
    }
    if (g_aPosition[client].Length == 0)
    {
        CPrintToChat(client, "[{green}SaveLoc{default}] No saved locations found.");
        return Plugin_Handled;
    }
    else
    {
        if (args == 0)
        {
            int id = g_iCurrLoc[client];
            LoadLocation(client, id);
        }
        else
        {
            char arg[32];
            GetCmdArg(1, arg, sizeof(arg));
            if (arg[0] != '#')
            {
                CPrintToChat(client, "[{green}SaveLoc{default}] Usage: {purple}!loadloc #<id>");
                return Plugin_Handled;
            }

            int id = StringToInt(arg[1]);
            if (id < 0 || id > g_aPosition[client].Length - 1)
            {
                CPrintToChat(client, "[{green}SaveLoc{default}] {grey}Invalid location.");
                return Plugin_Handled;
            }
            else
            {
                LoadLocation(client, id);
            }
        }
    }

    return Plugin_Handled;
}

public Action Command_LocMenu(int client, int args)
{
    if (!IsPlayerAlive(client))
    {
        CPrintToChat(client, "[{green}SaveLoc{default}] {grey}You must be alive to use {purple}!locmenu");
        return Plugin_Handled;
    }
    if (g_aPosition[client].Length == 0)
    {
        CPrintToChat(client, "[{green}SaveLoc{default}] No saved locations found.");
        return Plugin_Handled;
    }
    
    showLocMenu(client);

    return Plugin_Handled;
}

// ====[ Build Menu ]====
void showLocMenu(int client)
{
    Menu LocMenu = new Menu(LocMenuHandler, MENU_ACTIONS_ALL);
    LocMenu.SetTitle("Locations");

    for (int i = 0; i < g_aPosition[client].Length; i++)
    {
        char loc[8];
        Format(loc, sizeof(loc), "#%i", i);
        LocMenu.AddItem(loc, loc);
    }

    int firstItem;
    if (g_iCurrLoc[client] > 5)
    {
        firstItem = g_iCurrLoc[client] - (g_iCurrLoc[client] % 6);                
    }
    LocMenu.DisplayAt(client, firstItem, MENU_TIME_FOREVER);
}

// ====[ Menu Handler ]====
public int LocMenuHandler(Menu menu, MenuAction action, int client, int choice) 
{
    switch(action)
    {
        case MenuAction_Display:
        {
            g_bLocMenuOpen[client] = true;
        }
        case MenuAction_DisplayItem:
        {
            char loc[8];
            menu.GetItem(choice, loc, sizeof(loc));
            ReplaceString(loc, sizeof(loc), "#", "");

            int id = StringToInt(loc);

            if (id == g_iCurrLoc[client])
            {
                Format(loc, sizeof(loc), ">#%i", id);
                return RedrawMenuItem(loc);
            }
        }
        case MenuAction_Select:
        {
            char loc[8];
            menu.GetItem(choice, loc, sizeof(loc));
            ReplaceString(loc, sizeof(loc), "#", "");

            int id = StringToInt(loc);
            LoadLocation(client, id);
            menu.DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
        }
        case MenuAction_Cancel:
        {
            g_bLocMenuOpen[client] = false;
        }
    }
    
    return 0;
}

// ====[ LOCAL FUNCTIONS ]====
void SaveLocation(int client, float position[3], float angles[3], float velocity[3])
{
    if (g_aPosition[client].Length == MAX_LOCS)
    {
        ClearClientLocations(client);
        CPrintToChat(client, "[{green}SaveLoc{default}] {grey}Max locations reached, resetting.");
    }

    g_iCurrLoc[client] = g_aPosition[client].Length;
    g_aPosition[client].PushArray(position);
    g_aAngles[client].PushArray(angles);
    g_aVelocity[client].PushArray(velocity);

    if (g_bLocMenuOpen[client])
    {
        showLocMenu(client);
    }

    CPrintToChat(client, "[{green}SaveLoc{default}] {grey}Saved {lime}#%i", g_iCurrLoc[client]);
}

void LoadLocation(int client, int id)
{
    float position[3];
    float angles[3];
    float velocity[3];

    g_iCurrLoc[client] = id;
    g_aPosition[client].GetArray(id, position, sizeof(position));
    g_aAngles[client].GetArray(id, angles, sizeof(angles));
    g_aVelocity[client].GetArray(id, velocity, sizeof(velocity));

    TeleportEntity(client, position, angles, velocity);
    CPrintToChat(client, "[{green}SaveLoc{default}] {grey}Loaded {lime}#%i", g_iCurrLoc[client]);
}

void ClearClientLocations(int client)
{
    g_aPosition[client].Clear();
    g_aAngles[client].Clear();
    g_aVelocity[client].Clear();
    g_iCurrLoc[client] = -1;
}