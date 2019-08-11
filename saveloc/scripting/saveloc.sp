#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <multicolors>

#pragma newdecls required
#pragma semicolon 1

#define MAX_LOCATIONS 1024
#define MAX_LOCATION_NAME_LENGTH 32

static ArrayList g_aPosition;
static ArrayList g_aAngles;
static ArrayList g_aVelocity;
static ArrayList g_aLocationName;
static ArrayList g_aLocationCreator;
static bool g_bIsMenuOpen[MAXPLAYERS+1];
static int g_iMostRecentLocation[MAXPLAYERS+1];

public Plugin myinfo =
{
    name        = "SaveLoc",
    author      = "JWL",
    description = "Save/Load Locations",
    version     = "1.0",
    url         = ""
};

// ====[ EVENTS ]====
public void OnPluginStart()
{
    RegConsoleCmd("sm_saveloc", Command_SaveLoc, "Save location. Usage: !saveloc");
    RegConsoleCmd("sm_loadloc", Command_LoadLoc, "Load location. Usage: !loadloc <#id OR name>");
    RegConsoleCmd("sm_locmenu", Command_LocMenu, "Show locations in menu. Usage: !locmenu");
    RegConsoleCmd("sm_nameloc", Command_NameLoc, "Name location. Usage: !nameloc <name>");

    g_aPosition = new ArrayList(3);
    g_aAngles = new ArrayList(3);
    g_aVelocity = new ArrayList(3);
    g_aLocationName = new ArrayList(ByteCountToCells(MAX_LOCATION_NAME_LENGTH));
    g_aLocationCreator = new ArrayList(ByteCountToCells(MAX_NAME_LENGTH));
}

public void OnMapStart() 
{
    ClearLocations();
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
    if (!IsPlayerAlive(client))
    {
        CPrintToChat(client, "[{green}SaveLoc{default}] {grey}You must be alive to use {purple}!loadloc");
        return Plugin_Handled;
    }
    else if (GetClientTeam(client) == CS_TEAM_SPECTATOR)
    {
        CPrintToChat(client, "[{green}SaveLoc{default}] {grey}You must join a team to use {purple}!loadloc");
        return Plugin_Handled;
    }
    else if (g_aPosition.Length == 0)
    {
        CPrintToChat(client, "[{green}SaveLoc{default}] {grey}No saved locations found.");
        return Plugin_Handled;
    }

    if (args == 0)
    {
        int id = g_iMostRecentLocation[client];
        LoadLocation(client, id);
    }
    else
    {
        char arg[MAX_LOCATION_NAME_LENGTH];
        GetCmdArg(1, arg, sizeof(arg));
        if (arg[0] == '#') // check for location by <#id>
        {
            int id = StringToInt(arg[1]);
            if (id < 0 || id > g_aPosition.Length - 1)
            {
                CPrintToChat(client, "[{green}SaveLoc{default}] {grey}Invalid location.");
                return Plugin_Handled;
            }
            else
            {
                LoadLocation(client, id);
            }
        }
        else // check for location by <name>
        {
            if (g_aLocationName.FindString(arg) == -1)
            {
                CPrintToChat(client, "[{green}SaveLoc{default}] {grey}No saved locations with that name found.");
                return Plugin_Handled;
            }
            else
            {
                int id = g_aLocationName.FindString(arg);
                LoadLocation(client, id);
            }
        }
    }

    return Plugin_Handled;
}

public Action Command_NameLoc(int client, int args)
{
    if (!client) 
    {
        return Plugin_Handled;
    }

    char creator[MAX_NAME_LENGTH];
    char clientName[MAX_NAME_LENGTH];
    int id = g_iMostRecentLocation[client];

    g_aLocationCreator.GetString(id, creator, sizeof(creator));
    GetClientName(client, clientName, sizeof(clientName));
    if (!StrEqual(clientName, creator)) // check if client is creator of location
    {
        CPrintToChat(client, "[{green}SaveLoc{default}] {grey}You must be the creator of the location to use {purple}!nameloc");
    }

    if (args == 0)
    {
        CPrintToChat(client, "[{green}SaveLoc{default}] {grey}Usage: {purple}!nameloc <name>");
        return Plugin_Handled;
    }
    else
    {
        char name[MAX_LOCATION_NAME_LENGTH];
        GetCmdArg(1, name, sizeof(name));
        if (name[0] == '#') // check if location resembles <#id>
        {
            CPrintToChat(client, "[{green}SaveLoc{default}] {grey}Location name must not start with {yellow}#");
            return Plugin_Handled;
        }
        else if (g_aLocationName.FindString(name) != -1) // check for unique location name
        {
            CPrintToChat(client, "[{green}SaveLoc{default}] {grey}Location name already taken.");
        }
        else // set the location name
        {
            NameLocation(client, name);
        }
    }   

    return Plugin_Handled; 
}

public Action Command_LocMenu(int client, int args)
{
    if (!client) 
    {
        return Plugin_Handled;
    }
    if (!IsPlayerAlive(client))
    {
        CPrintToChat(client, "[{green}SaveLoc{default}] {grey}You must be alive to use {purple}!locmenu");
        return Plugin_Handled;
    }
    else if (g_aPosition.Length == 0)
    {
        CPrintToChat(client, "[{green}SaveLoc{default}] {grey}No saved locations found.");
        return Plugin_Handled;
    }

    ShowLocMenu(client);

    return Plugin_Handled;
}

// ====[ Build Menu ]====
void ShowLocMenu(int client)
{
    Menu locMenu = new Menu(LocMenuHandler, MENU_ACTIONS_ALL);
    locMenu.SetTitle("Locations");

    for (int i = 0; i < g_aPosition.Length; i++)
    {
        char loc[MAX_LOCATION_NAME_LENGTH];
        Format(loc, sizeof(loc), "%i", i);
        locMenu.AddItem(loc, loc);
    }

    int firstItem;
    if (g_iMostRecentLocation[client] > 5)
    {
        firstItem = g_iMostRecentLocation[client] - (g_iMostRecentLocation[client] % 6);                
    }

    locMenu.DisplayAt(client, firstItem, MENU_TIME_FOREVER);
}

// ====[ Menu Handler ]====
public int LocMenuHandler(Menu menu, MenuAction action, int client, int choice) 
{
    switch(action)
    {
        case MenuAction_Display:
        {
            g_bIsMenuOpen[client] = true;
        }
        case MenuAction_DisplayItem:
        {
            char loc[MAX_LOCATION_NAME_LENGTH];
            menu.GetItem(choice, loc, sizeof(loc));
            int id = StringToInt(loc);
            char name[MAX_LOCATION_NAME_LENGTH];
            g_aLocationName.GetString(id, name, sizeof(name));

            if (id == g_iMostRecentLocation[client])
            {
                Format(loc, sizeof(loc), "> #%i %s", id, name);
            }
            else
            {
                Format(loc, sizeof(loc), "#%i %s", id, name);
            }

            return RedrawMenuItem(loc);
        }
        case MenuAction_Select:
        {
            char loc[MAX_LOCATION_NAME_LENGTH];
            menu.GetItem(choice, loc, sizeof(loc));
            ReplaceString(loc, sizeof(loc), "#", "");

            int id = StringToInt(loc);
            LoadLocation(client, id);
            menu.DisplayAt(client, menu.Selection, MENU_TIME_FOREVER);
        }
        case MenuAction_Cancel:
        {
            g_bIsMenuOpen[client] = false;
        }
    }
    
    return 0;
}

// ====[ LOCAL FUNCTIONS ]====
void SaveLocation(int client, float position[3], float angles[3], float velocity[3])
{
    if (g_aPosition.Length == MAX_LOCATIONS)
    {
        ClearLocations();
        CPrintToChatAll("[{green}SaveLoc{default}] {grey}Max saved locations reached! Resetting.");
    }

    char creator[MAX_NAME_LENGTH];
    GetClientName(client, creator, sizeof(creator));
    g_iMostRecentLocation[client] = g_aPosition.Length;
    g_aPosition.PushArray(position);
    g_aAngles.PushArray(angles);
    g_aVelocity.PushArray(velocity);
    g_aLocationName.PushString("");
    g_aLocationCreator.PushString(creator);

    CPrintToChat(client, "[{green}SaveLoc{default}] {grey}Saved {lime}#%i", g_iMostRecentLocation[client]);

    // refresh menu
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_bIsMenuOpen[i])
        {
            ShowLocMenu(i);
        }
    }
}

void LoadLocation(int client, int id)
{
    float position[3];
    float angles[3];
    float velocity[3];
    char name[MAX_LOCATION_NAME_LENGTH];
    char creator[MAX_NAME_LENGTH];
    char clientName[MAX_NAME_LENGTH];

    if (g_iMostRecentLocation[client] != id)
    {
        g_iMostRecentLocation[client] = id;
        if (g_bIsMenuOpen[client]) // refresh menu
        {
            ShowLocMenu(client);
        }
    }

    g_aPosition.GetArray(id, position, sizeof(position));
    g_aAngles.GetArray(id, angles, sizeof(angles));
    g_aVelocity.GetArray(id, velocity, sizeof(velocity));
    g_aLocationName.GetString(id, name, sizeof(name));
    g_aLocationCreator.GetString(id, creator, sizeof(creator));
    GetClientName(client, clientName, sizeof(clientName));
    TeleportEntity(client, position, angles, velocity);

    if (StrEqual(clientName, creator))
    {
        CPrintToChat(client, "[{green}SaveLoc{default}] {grey}Loaded {lime}#%i {yellow}%s", g_iMostRecentLocation[client], name);
    }
    else if (StrEqual(name, ""))
    {
        CPrintToChat(client, "[{green}SaveLoc{default}] {grey}Loaded {lime}#%i {grey}| Created by {yellow}%s", g_iMostRecentLocation[client], creator);
    }
    else if (!StrEqual(name, ""))
    {
        CPrintToChat(client, "[{green}SaveLoc{default}] {grey}Loaded {lime}#%i {yellow}%s {grey}| Created by {yellow}%s", g_iMostRecentLocation[client], name, creator);
    }
}

void NameLocation(int client, char[] name)
{
    int id = g_iMostRecentLocation[client];
    g_aLocationName.SetString(id, name);
    CPrintToChat(client, "[{green}SaveLoc{default}] {grey}Named {lime}#%i {yellow}%s", id, name);

    // refresh menu
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_bIsMenuOpen[i])
        {
            ShowLocMenu(i);
        }
    }
}

void ClearLocations()
{
    g_aPosition.Clear();
    g_aAngles.Clear();
    g_aVelocity.Clear();
    g_aLocationName.Clear();
    g_aLocationCreator.Clear();

    for (int i = 1; i <= MaxClients; i++)
    {
        g_iMostRecentLocation[i] = -1;
    }
}