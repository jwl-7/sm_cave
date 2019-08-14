#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <multicolors>

#pragma newdecls required
#pragma semicolon 1

#define MAXLOCATION_NAME 32
#define MSG_PREFIX "%s"

static ArrayList g_aPosition;
static ArrayList g_aAngles;
static ArrayList g_aVelocity;
static ArrayList g_aLocationName;
static ArrayList g_aLocationCreator;
static bool g_bLocationMenuOpen[MAXPLAYERS+1];
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

public Action Command_SaveLoc(int client, int args)
{
    if (!IsValidClient) 
    {
        return Plugin_Handled;
    }

    if (args == 0)
    {
        // save location with empty <name>
        SaveLocation(client, "");
    }
    else if (args == 1)
    {
        // save location with <name>
        char name[MAXLOCATION_NAME];
        GetCmdArg(1, name, sizeof(name));
        SaveLocation(client, name);
    }
    else
    {
        // print command usage
        CPrintToChat(client, "%s {grey}Usage: {purple}!saveloc {grey}OR {purple}!saveloc <name>", MSG_PREFIX);
    }

    return Plugin_Handled;
}

public Action Command_LoadLoc(int client, int args)
{
    if (!IsValidClient) 
    {
        return Plugin_Handled;
    }

    if (!IsPlayerAlive(client))
    {
        CPrintToChat(client, "%s {lightred}You must be alive to use that command.");
        return Plugin_Handled;
    }
    else if (GetClientTeam(client) == CS_TEAM_SPECTATOR)
    {
        CPrintToChat(client, "%s {lightred}You must be alive to use that command.");
        return Plugin_Handled;
    }
    else if (g_aPosition.Length == 0)
    {
        CPrintToChat(client, "%s {lightred}No saved locations found.");
        return Plugin_Handled;
    }

    if (args == 0)
    {
        // if no arguments, load the client's most recent location
        int id = g_iMostRecentLocation[client];
        LoadLocation(client, id);
    }
    else // check the argument for <#id OR name>
    {
        char arg[MAXLOCATION_NAME];
        GetCmdArg(1, arg, sizeof(arg));
        if (arg[0] == '#') // check for location by <#id>
        {
            int id = StringToInt(arg[1]);
            if (id < 0 || id > g_aPosition.Length - 1) // location does not exist
            {
                CPrintToChat(client, "%s {lightred}Location not found.");
            }
            else
            {
                LoadLocation(client, id);
            }
        }
        else // check for location by <name>
        {
            if (g_aLocationName.FindString(arg) == -1) // location does not exist
            {
                CPrintToChat(client, "%s {lightred}Location not found.");
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
    if (!IsValidClient) 
    {
        return Plugin_Handled;
    }

    char creator[MAX_NAME_LENGTH];
    char clientName[MAX_NAME_LENGTH];

    if (args == 0)
    {
        CPrintToChat(client, "%s {grey}Usage: {purple}!nameloc <name>");
    }
    else
    {
        if (args == 1)
        {
            // name most recent location
            int id = g_iMostRecentLocation[client];
        }
        else
        {
            // name specified location
            char arg1[MAXLOCATION_NAME];
            char arg2[MAXLOCATION_NAME];

            GetCmdArg(1, arg1, sizeof(arg1));
            GetCmdArg(2, arg2, sizeof(arg2));

            if (arg1[0] != '#')
            {
                CPrintToChat(client, 
                            "%s 
                            {grey}Usage: {purple}!nameloc <name> 
                            {grey}OR {purple}!nameloc <#id> <name>");
            }
            else if (arg2[0] == '#')
            {
                CPrintToChat(client, 
                            "%s 
                            {grey}Usage: {purple}!nameloc <name> 
                            {grey}OR {purple}!nameloc <#id> <name>");
            }
        }
    }
    else if (args == 1)
    {
        // name most recent location
        int id = g_iMostRecentLocation[client];

        // check if client created the location
        g_aLocationCreator.GetString(id, creator, sizeof(creator));
        GetClientName(client, clientName, sizeof(clientName));
        if (!StrEqual(clientName, creator))
        {
            CPrintToChat(client, "%s {lightred}You can't name another player's location.");
        }
        else
        {

        }
    else
    {

    }

    char creator[MAX_NAME_LENGTH];
    char clientName[MAX_NAME_LENGTH];
    int id = g_iMostRecentLocation[client];

    g_aLocationCreator.GetString(id, creator, sizeof(creator));
    GetClientName(client, clientName, sizeof(clientName));
    if (!StrEqual(clientName, creator)) // check if client created the location
    {
        CPrintToChat(client, "%s {lightred}You can't name another player's location.");
    }

    if (args == 0)
    {
        CPrintToChat(client, "%s {grey}Usage: {purple}!nameloc <name>");
    }
    else
    {
        char name[MAXLOCATION_NAME];
        GetCmdArg(1, name, sizeof(name));
        if (name[0] == '#') // check if location resembles <#id>
        {
            CPrintToChat(client, "%s {lightred}Location name can't start with '#'.");
        }
        else if (g_aLocationName.FindString(name) != -1) // check for unique location name
        {
            CPrintToChat(client, "%s {lightred}Location name already taken.");
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
    if (!IsValidClient) 
    {
        return Plugin_Handled;
    }
    if (!IsPlayerAlive(client))
    {
        CPrintToChat(client, "%s {lightred}You must be alive to use that command.");
        return Plugin_Handled;
    }
    else if (GetClientTeam(client) == CS_TEAM_SPECTATOR)
    {
        CPrintToChat(client, "%s {lightred}You must be alive to use that command.");
        return Plugin_Handled;
    }
    else if (g_aPosition.Length == 0)
    {
        CPrintToChat(client, "%s {lightred}No saved locations found.");
        return Plugin_Handled;
    }

    ShowLocMenu(client);

    return Plugin_Handled;
}

// ====[ BUILD MENU ]====
void ShowLocMenu(int client)
{
    Menu locMenu = new Menu(LocMenuHandler, MENU_ACTIONS_ALL);
    locMenu.SetTitle("Locations");

    // fill the menu with all saved locations
    for (int i = 0; i < g_aPosition.Length; i++)
    {
        char loc[MAXLOCATION_NAME];
        Format(loc, sizeof(loc), "%i", i);
        locMenu.AddItem(loc, loc);
    }

    // make sure the menu displays at the client's most recent location
    int firstItem;
    if (g_iMostRecentLocation[client] > 5)
    {
        firstItem = g_iMostRecentLocation[client] - (g_iMostRecentLocation[client] % 6);                
    }

    locMenu.DisplayAt(client, firstItem, MENU_TIME_FOREVER);
}

// ====[ MENU HANDLER ]====
public int LocMenuHandler(Menu menu, MenuAction action, int client, int choice) 
{
    switch (action)
    {
        case MenuAction_Display:
        {
            g_bLocationMenuOpen[client] = true;
        }

        case MenuAction_DisplayItem:
        {
            char loc[MAXLOCATION_NAME];
            menu.GetItem(choice, loc, sizeof(loc));

            int id = StringToInt(loc);
            char name[MAXLOCATION_NAME];
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
            char loc[MAXLOCATION_NAME];
            menu.GetItem(choice, loc, sizeof(loc));
            ReplaceString(loc, sizeof(loc), "#", "");

            int id = StringToInt(loc);
            LoadLocation(client, id);
        }

        case MenuAction_Cancel:
        {
            g_bLocationMenuOpen[client] = false;
        }

        case MenuAction_End:
        {
            delete menu;
        }
    }
    
    return 0;
}

// ====[ SAVE LOCATION ]====
void SaveLocation(int client, char[MAXLOCATION_NAME] name)
{
    // check if location <name> resembles <#id>
    if (name[0] == '#')
    {
        CPrintToChat(client, "%s {lightred}Location name can't start with '#'.", MSG_PREFIX);
        return;
    }

    float position[3];
    float angles[3];
    float velocity[3];
    char creator[MAX_NAME_LENGTH];
    int id;

    GetClientAbsOrigin(client, position);
    GetClientEyeAngles(client, angles);
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
    GetClientName(client, creator, sizeof(creator));
    
    g_iMostRecentLocation[client], id = g_aPosition.Length;
    g_aPosition.PushArray(position);
    g_aAngles.PushArray(angles);
    g_aVelocity.PushArray(velocity);
    g_aLocationName.PushString(name);
    g_aLocationCreator.PushString(creator);

    CPrintToChat(client, "%s {grey}Saved {yellow}#%i {olive}%s", MSG_PREFIX, id, name);

    // refresh all open menus
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_bLocationMenuOpen[i])
        {
            ShowLocMenu(i);
        }
    }
}

// =====[ LOAD LOCATION ]=====
void LoadLocation(int client, int id)
{
    if (!IsPlayerAlive(client))
    {
        CPrintToChat(client, "%s {lightred}You must be alive to use that command.");
        return;
    }
    else if (GetClientTeam(client) == CS_TEAM_SPECTATOR)
    {
        CPrintToChat(client, "%s {lightred}You must be alive to use that command.");
        return;
    }

    float position[3];
    float angles[3];
    float velocity[3];
    char name[MAXLOCATION_NAME];
    char creator[MAX_NAME_LENGTH];
    char clientName[MAX_NAME_LENGTH];

    g_aPosition.GetArray(id, position, sizeof(position));
    g_aAngles.GetArray(id, angles, sizeof(angles));
    g_aVelocity.GetArray(id, velocity, sizeof(velocity));
    g_aLocationName.GetString(id, name, sizeof(name));
    g_aLocationCreator.GetString(id, creator, sizeof(creator));

    GetClientName(client, clientName, sizeof(clientName));
    TeleportEntity(client, position, angles, velocity);

    // print chat message if loading new location
    if (g_iMostRecentLocation[client] != id)
    {
        g_iMostRecentLocation[client] = id;

        if (StrEqual(clientName, creator))
        {
            CPrintToChat(client, "%s {grey}Loaded {lime}#%i {yellow}%s", id, name);
        }
        else if (StrEqual(name, ""))
        {
            CPrintToChat(client, "%s {grey}Loaded {lime}#%i {default}| {grey}Created by {lime}%s", id, creator);
        }
        else if (!StrEqual(name, ""))
        {
            CPrintToChat(client, "%s {grey}Loaded {lime}#%i {yellow}%s {default}| {grey}Created by {lime}%s", id, name, creator);
        }
    }

    // refresh menu
    if (g_bLocationMenuOpen[client])
    {
        ShowLocMenu(client);
    }
}

// =====[ NAME LOCATION ]=====
void NameLocation(int client, int id, char[MAXLOCATION_NAME] name)
{
    int id = g_iMostRecentLocation[client];
    g_aLocationName.SetString(id, name);

    CPrintToChat(client, "%s {grey}Named {lime}#%i {yellow}%s", id, name);

    // refresh menu
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_bLocationMenuOpen[i])
        {
            ShowLocMenu(i);
        }
    }
}

// =====[ HELPER FUNCTIONS ]=====
void CreateArrays()
{
    g_aPosition = new ArrayList(3);
    g_aAngles = new ArrayList(3);
    g_aVelocity = new ArrayList(3);
    g_aLocationName = new ArrayList(ByteCountToCells(MAXLOCATION_NAME));
    g_aLocationCreator = new ArrayList(ByteCountToCells(MAX_NAME_LENGTH));
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
        g_bLocationMenuOpen[i] = false;
    }
}

stock bool IsValidClient(int client)
{
	return client >= 1 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client);
}