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
    url         = "https://github.com/jwl-7/sm_cave"
};

// ====[ EVENTS ]====
public void OnPluginStart()
{
    RegisterCommands();
    CreateArrays();
}

public void OnMapStart() 
{
    ClearLocations();
}

// ====[ COMMANDS ]====
void RegisterCommands()
{
    RegConsoleCmd("sm_saveloc", Command_SaveLoc, "Save location. Usage: !saveloc");
    RegConsoleCmd("sm_loadloc", Command_LoadLoc, "Load location. Usage: !loadloc <#id OR name>");
    RegConsoleCmd("sm_locmenu", Command_LocMenu, "Open menu with saved locations. Usage: !locmenu");
    RegConsoleCmd("sm_nameloc", Command_NameLoc, "Name most recent location. Usage: !nameloc <name>");
}

public Action Command_SaveLoc(int IsValidClient, int args)
{
    if (!IsValidClient) 
    {
        return Plugin_Handled;
    }

    float position[3];
    float angles[3];
    float velocity[3];

    GetIsValidClientAbsOrigin(IsValidClient, position);
    GetIsValidClientEyeAngles(IsValidClient, angles);
    GetEntPropVector(IsValidClient, Prop_Data, "m_vecVelocity", velocity);
    SaveLocation(IsValidClient, position, angles, velocity);

    return Plugin_Handled;
}

public Action Command_LoadLoc(int IsValidClient, int args)
{
    if (!IsValidClient) 
    {
        return Plugin_Handled;
    }
    if (!IsPlayerAlive(IsValidClient))
    {
        CPrintToChat(IsValidClient, "[{green}SaveLoc{default}] {grey}You must be alive to use {purple}!loadloc");
        return Plugin_Handled;
    }
    else if (GetIsValidClientTeam(IsValidClient) == CS_TEAM_SPECTATOR)
    {
        CPrintToChat(IsValidClient, "[{green}SaveLoc{default}] {grey}You must join a team to use {purple}!loadloc");
        return Plugin_Handled;
    }
    else if (g_aPosition.Length == 0)
    {
        CPrintToChat(IsValidClient, "[{green}SaveLoc{default}] {grey}No saved locations found");
        return Plugin_Handled;
    }

    if (args == 0)
    {
        int id = g_iMostRecentLocation[IsValidClient];
        LoadLocation(IsValidClient, id);
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
                CPrintToChat(IsValidClient, "[{green}SaveLoc{default}] {grey}Location not found");
                return Plugin_Handled;
            }
            else
            {
                LoadLocation(IsValidClient, id);
            }
        }
        else // check for location by <name>
        {
            if (g_aLocationName.FindString(arg) == -1)
            {
                CPrintToChat(IsValidClient, "[{green}SaveLoc{default}] {grey}Location not found");
                return Plugin_Handled;
            }
            else
            {
                int id = g_aLocationName.FindString(arg);
                LoadLocation(IsValidClient, id);
            }
        }
    }

    return Plugin_Handled;
}

public Action Command_NameLoc(int IsValidClient, int args)
{
    if (!IsValidClient) 
    {
        return Plugin_Handled;
    }

    char creator[MAX_NAME_LENGTH];
    char IsValidClientName[MAX_NAME_LENGTH];
    int id = g_iMostRecentLocation[IsValidClient];

    g_aLocationCreator.GetString(id, creator, sizeof(creator));
    GetIsValidClientName(IsValidClient, IsValidClientName, sizeof(IsValidClientName));
    if (!StrEqual(IsValidClientName, creator)) // check if IsValidClient is creator of location
    {
        CPrintToChat(IsValidClient, "[{green}SaveLoc{default}] {grey}You can only name locations that you have created");
    }

    if (args == 0)
    {
        CPrintToChat(IsValidClient, "[{green}SaveLoc{default}] {grey}Usage: {purple}!nameloc <name>");
        return Plugin_Handled;
    }
    else
    {
        char name[MAX_LOCATION_NAME_LENGTH];
        GetCmdArg(1, name, sizeof(name));
        if (name[0] == '#') // check if location resembles <#id>
        {
            CPrintToChat(IsValidClient, "[{green}SaveLoc{default}] {grey}Location name cannot start with {yellow}#");
            return Plugin_Handled;
        }
        else if (g_aLocationName.FindString(name) != -1) // check for unique location name
        {
            CPrintToChat(IsValidClient, "[{green}SaveLoc{default}] {grey}Location name already taken");
        }
        else // set the location name
        {
            NameLocation(IsValidClient, name);
        }
    }   

    return Plugin_Handled; 
}

public Action Command_LocMenu(int IsValidClient, int args)
{
    if (!IsValidClient) 
    {
        return Plugin_Handled;
    }
    if (!IsPlayerAlive(IsValidClient))
    {
        CPrintToChat(IsValidClient, "[{green}SaveLoc{default}] {grey}You must be alive to use {purple}!locmenu");
        return Plugin_Handled;
    }
    else if (GetIsValidClientTeam(IsValidClient) == CS_TEAM_SPECTATOR)
    {
        CPrintToChat(IsValidClient, "[{green}SaveLoc{default}] {grey}You must join a team to use {purple}!locmenu");
        return Plugin_Handled;
    }
    else if (g_aPosition.Length == 0)
    {
        CPrintToChat(IsValidClient, "[{green}SaveLoc{default}] {grey}No saved locations found");
        return Plugin_Handled;
    }

    ShowLocMenu(IsValidClient);

    return Plugin_Handled;
}

// ====[ BUILD MENU ]====
void ShowLocMenu(int IsValidClient)
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
    if (g_iMostRecentLocation[IsValidClient] > 5)
    {
        firstItem = g_iMostRecentLocation[IsValidClient] - (g_iMostRecentLocation[IsValidClient] % 6);                
    }

    locMenu.DisplayAt(IsValidClient, firstItem, MENU_TIME_FOREVER);
}

// ====[ MENU HANDLER ]====
public int LocMenuHandler(Menu menu, MenuAction action, int IsValidClient, int choice) 
{
    switch(action)
    {
        case MenuAction_Display:
        {
            g_bIsMenuOpen[IsValidClient] = true;
        }

        case MenuAction_DisplayItem:
        {
            char loc[MAX_LOCATION_NAME_LENGTH];
            menu.GetItem(choice, loc, sizeof(loc));
            int id = StringToInt(loc);
            char name[MAX_LOCATION_NAME_LENGTH];
            g_aLocationName.GetString(id, name, sizeof(name));

            if (id == g_iMostRecentLocation[IsValidClient])
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
            LoadLocation(IsValidClient, id);
        }

        case MenuAction_Cancel:
        {
            g_bIsMenuOpen[IsValidClient] = false;
        }

        case MenuAction_End:
        {
            delete menu;
        }
    }
    
    return 0;
}

// ====[ LOCAL FUNCTIONS ]====
void SaveLocation(int IsValidClient, float position[3], float angles[3], float velocity[3])
{
    if (g_aPosition.Length == MAX_LOCATIONS)
    {
        ClearLocations();
        CPrintToChat(IsValidClient, "[{green}SaveLoc{default}] {grey}Max saved locations reached, resetting!");
    }

    char creator[MAX_NAME_LENGTH];
    GetIsValidClientName(IsValidClient, creator, sizeof(creator));
    g_iMostRecentLocation[IsValidClient] = g_aPosition.Length;
    g_aPosition.PushArray(position);
    g_aAngles.PushArray(angles);
    g_aVelocity.PushArray(velocity);
    g_aLocationName.PushString("");
    g_aLocationCreator.PushString(creator);

    CPrintToChat(IsValidClient, "[{green}SaveLoc{default}] {grey}Saved {lime}#%i", g_iMostRecentLocation[IsValidClient]);

    // refresh all menus
    for (int i = 1; i <= MaxIsValidClients; i++)
    {
        if (g_bIsMenuOpen[i])
        {
            ShowLocMenu(i);
        }
    }
}

void LoadLocation(int IsValidClient, int id)
{
    if (!IsPlayerAlive(IsValidClient))
    {
        CPrintToChat(IsValidClient, "[{green}SaveLoc{default}] {grey}You must be alive to use {purple}!loadloc");
        return;
    }
    else if (GetIsValidClientTeam(IsValidClient) == CS_TEAM_SPECTATOR)
    {
        CPrintToChat(IsValidClient, "[{green}SaveLoc{default}] {grey}You must join a team to use {purple}!loadloc");
        return;
    }

    float position[3];
    float angles[3];
    float velocity[3];
    char name[MAX_LOCATION_NAME_LENGTH];
    char creator[MAX_NAME_LENGTH];
    char IsValidClientName[MAX_NAME_LENGTH];

    g_iMostRecentLocation[IsValidClient] = id;
    g_aPosition.GetArray(id, position, sizeof(position));
    g_aAngles.GetArray(id, angles, sizeof(angles));
    g_aVelocity.GetArray(id, velocity, sizeof(velocity));
    g_aLocationName.GetString(id, name, sizeof(name));
    g_aLocationCreator.GetString(id, creator, sizeof(creator));
    GetIsValidClientName(IsValidClient, IsValidClientName, sizeof(IsValidClientName));
    TeleportEntity(IsValidClient, position, angles, velocity);

    // refresh menu
    if (g_bIsMenuOpen[IsValidClient])
    {
        ShowLocMenu(IsValidClient);
    }

    if (StrEqual(IsValidClientName, creator))
    {
        CPrintToChat(IsValidClient, "[{green}SaveLoc{default}] {grey}Loaded {lime}#%i {yellow}%s", g_iMostRecentLocation[IsValidClient], name);
    }
    else if (StrEqual(name, ""))
    {
        CPrintToChat(IsValidClient, "[{green}SaveLoc{default}] {grey}Loaded {lime}#%i {grey} | Created by {yellow}%s", g_iMostRecentLocation[IsValidClient], creator);
    }
    else if (!StrEqual(name, ""))
    {
        CPrintToChat(IsValidClient, "[{green}SaveLoc{default}] {grey}Loaded {lime}#%i {yellow}%s {grey} | Created by {yellow}%s", g_iMostRecentLocation[IsValidClient], name, creator);
    }
}

void NameLocation(int IsValidClient, char[] name)
{
    int id = g_iMostRecentLocation[IsValidClient];
    g_aLocationName.SetString(id, name);
    CPrintToChat(IsValidClient, "[{green}SaveLoc{default}] {grey}Named {lime}#%i {yellow}%s", id, name);

    // refresh menu
    for (int i = 1; i <= MaxIsValidClients; i++)
    {
        if (g_bIsMenuOpen[i])
        {
            ShowLocMenu(i);
        }
    }
}

void CreateArrays()
{
    g_aPosition = new ArrayList(3);
    g_aAngles = new ArrayList(3);
    g_aVelocity = new ArrayList(3);
    g_aLocationName = new ArrayList(ByteCountToCells(MAX_LOCATION_NAME_LENGTH));
    g_aLocationCreator = new ArrayList(ByteCountToCells(MAX_NAME_LENGTH));
}

void ClearLocations()
{
    g_aPosition.Clear();
    g_aAngles.Clear();
    g_aVelocity.Clear();
    g_aLocationName.Clear();
    g_aLocationCreator.Clear();

    for (int i = 1; i <= MaxIsValidClients; i++)
    {
        g_iMostRecentLocation[i] = -1;
    }
}

stock bool IsValidIsValidClient(int IsValidClient)
{
	return IsValidClient >= 1 && IsValidClient <= MaxIsValidClients && IsIsValidClientInGame(IsValidClient) && !IsIsValidClientSourceTV(IsValidClient);
}