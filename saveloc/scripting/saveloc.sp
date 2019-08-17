#include <sourcemod>
#include <sourcemod-colors>
#include <sdktools>
#include <cstrike>

#pragma newdecls required
#pragma semicolon 1

#define MAXLOCATION_NAME 32
#define MSG_PREFIX "[{green}Saveloc{default}]"

static ArrayList g_aPosition;
static ArrayList g_aAngles;
static ArrayList g_aVelocity;
static ArrayList g_aLocationName;
static ArrayList g_aLocationCreator;
static bool g_bLocMenuOpen[MAXPLAYERS+1];
static int g_iMostRecentLocation[MAXPLAYERS+1];

public Plugin myinfo =
{
    name        = "SaveLoc",
    author      = "JWL",
    description = "Allows players to save/load locations that preserve position, angles, and velocity",
    version     = "1.0",
    url         = "https://github.com/jwl-7/sm_cave"
};

// ====[ EVENTS ]====
public void OnPluginStart()
{
    RegisterCommands();
    CreateArrays();
    HookEvents();
}

public void OnMapStart()
{
    ClearLocations();
}

// ====[ CLIENT EVENTS ]====
public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    CloseLocMenu(client);
}

public void OnPlayerJoinTeam(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    int team = event.GetInt("team");

    if (team == CS_TEAM_SPECTATOR)
    {
        CloseLocMenu(client);
    }
}

// ====[ COMMANDS ]====
void RegisterCommands()
{
    RegConsoleCmd("sm_saveloc", Command_SaveLoc, "Save location. Usage: !saveloc <name>");
    RegConsoleCmd("sm_loadloc", Command_LoadLoc, "Load location. Usage: !loadloc <#id OR name>");
    RegConsoleCmd("sm_locmenu", Command_LocMenu, "Open location menu. Usage: !locmenu");
    RegConsoleCmd("sm_nameloc", Command_NameLoc, "Name location. Usage: !nameloc <#id> <name>");
}

public Action Command_SaveLoc(int client, int args)
{
    if (!IsValidClient(client)) 
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
        // get location <name>
        char arg[MAXLOCATION_NAME];
        GetCmdArg(1, arg, sizeof(arg));

        if (IsValidLocationName(arg))
        {
            // save location with <name>
            SaveLocation(client, arg);
        }
        else
        {
            CPrintToChat(client, "%s {red}Location name must start with a letter and be unique.", MSG_PREFIX);
        }
    }
    else
    {
        CPrintToChat(client, "%s {grey}Usage: {purple}!saveloc <name>", MSG_PREFIX);
    }

    return Plugin_Handled;
}

public Action Command_LoadLoc(int client, int args)
{
    if (!IsValidClient(client)) 
    {
        return Plugin_Handled;
    }
    else if (!IsPlayerAlive(client))
    {
        CPrintToChat(client, "%s {red}You must be alive to use that command.", MSG_PREFIX);
        return Plugin_Handled;
    }
    else if (g_aPosition.Length == 0)
    {
        CPrintToChat(client, "%s {red}No saved locations found.", MSG_PREFIX);
        return Plugin_Handled;
    }

    if (args == 0)
    {
        // load most recent location
        int id = g_iMostRecentLocation[client];
        LoadLocation(client, id);
    }
    else if (args == 1)
    {
        // get location <#id OR name>
        char arg[MAXLOCATION_NAME];
        GetCmdArg(1, arg, sizeof(arg));
        int id;

        if (arg[0] == '#')
        {
            // load location <#id>
            id = StringToInt(arg[1]);
        }
        else
        {
            // load location <name>
            id = g_aLocationName.FindString(arg);
        }

        if (IsValidLocationId(id))
        {
            LoadLocation(client, id);
        }
        else
        {
            CPrintToChat(client, "%s {red}Location not found.", MSG_PREFIX);
        }
    }
    else
    {
        CPrintToChat(client, "%s {grey}Usage: {purple}!loadloc <#id OR name>", MSG_PREFIX);
    }

    return Plugin_Handled;
}

public Action Command_NameLoc(int client, int args)
{
    if (!IsValidClient(client)) 
    {
        return Plugin_Handled;
    }
    else if (g_aPosition.Length == 0)
    {
        CPrintToChat(client, "%s {red}No saved locations found.", MSG_PREFIX);
        return Plugin_Handled;
    }

    if (args == 0)
    {
        CPrintToChat(client, "%s {grey}Usage: {purple}!nameloc <#id> <name>", MSG_PREFIX);
    }
    else if (args == 1)
    {
        // name most recent location
        char arg[MAXLOCATION_NAME];
        GetCmdArg(1, arg, sizeof(arg));
        int id = g_iMostRecentLocation[client];

        if (IsValidLocationName(arg) && IsClientLocationCreator(client, id))
        {
            NameLocation(client, id, arg);
        }
        else if (!IsClientLocationCreator(client, id))
        {
            CPrintToChat(client, "%s {red}You can't name another player's location.", MSG_PREFIX);
        }
        else
        {
            CPrintToChat(client, "%s {red}Location name must start with a letter and be unique.", MSG_PREFIX);
        }
    }
    else if (args == 2)
    {
        // name specified location
        char arg1[MAXLOCATION_NAME];
        char arg2[MAXLOCATION_NAME];
        GetCmdArg(1, arg1, sizeof(arg1));
        GetCmdArg(2, arg2, sizeof(arg2));
        int id = StringToInt(arg1[1]);

        if (IsValidLocationId(id))
        {

            if (IsValidLocationName(arg2) && IsClientLocationCreator(client, id))
            {
                NameLocation(client, id, arg2);
            }
            else if (!IsClientLocationCreator(client, id))
            {
                CPrintToChat(client, "%s {red}You can't name another player's location.", MSG_PREFIX);
            }
            else
            {
                CPrintToChat(client, "%s {red}Location name must start with a letter and be unique.", MSG_PREFIX);
            }
        }
        else
        {
            CPrintToChat(client, "%s {red}Location not found.", MSG_PREFIX);
        }
    }
    else
    {
        CPrintToChat(client, "%s {grey}Usage: {purple}!nameloc <#id> <name>", MSG_PREFIX);
    }

    return Plugin_Handled; 
}

public Action Command_LocMenu(int client, int args)
{
    if (!IsValidClient(client)) 
    {
        return Plugin_Handled;
    }
    else if (!IsPlayerAlive(client))
    {
        CPrintToChat(client, "%s {red}You must be alive to use that command.", MSG_PREFIX);
        return Plugin_Handled;
    }
    else if (g_aPosition.Length == 0)
    {
        CPrintToChat(client, "%s {red}No saved locations found.", MSG_PREFIX);
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

    // fill the menu with all locations
    for (int i = 0; i < g_aPosition.Length; i++)
    {
        char item[MAXLOCATION_NAME];
        Format(item, sizeof(item), "%i", i);
        locMenu.AddItem(item, item);
    }

    // calculate which page of the menu contains client's most recent location
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
            g_bLocMenuOpen[client] = true;
        }

        case MenuAction_DisplayItem:
        {
            char item[MAXLOCATION_NAME];
            menu.GetItem(choice, item, sizeof(item));

            int id = StringToInt(item);
            char name[MAXLOCATION_NAME];
            g_aLocationName.GetString(id, name, sizeof(name));

            if (id == g_iMostRecentLocation[client])
            {
                Format(item, sizeof(item), "> #%i %s", id, name);
            }
            else
            {
                Format(item, sizeof(item), "#%i %s", id, name);
            }

            return RedrawMenuItem(item);
        }

        case MenuAction_Select:
        {
            char item[MAXLOCATION_NAME];
            menu.GetItem(choice, item, sizeof(item));
            ReplaceString(item, sizeof(item), "#", "");
            int id = StringToInt(item);

            LoadLocation(client, id);
        }

        case MenuAction_Cancel:
        {
            g_bLocMenuOpen[client] = false;
        }

        case MenuAction_End:
        {
            delete menu;
        }
    }
    
    return 0;
}

// ====[ SAVE LOCATION ]====
void SaveLocation(int client, char[] name)
{
    float position[3];
    float angles[3];
    float velocity[3];
    char creator[MAX_NAME_LENGTH];
    int id = g_aPosition.Length;

    GetClientAbsOrigin(client, position);
    GetClientEyeAngles(client, angles);
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
    GetClientName(client, creator, sizeof(creator));
    
    g_iMostRecentLocation[client] = id;
    g_aPosition.PushArray(position);
    g_aAngles.PushArray(angles);
    g_aVelocity.PushArray(velocity);
    g_aLocationName.PushString(name);
    g_aLocationCreator.PushString(creator);

    CPrintToChat(client, "%s {grey}Saved {yellow}#%i {lightgreen}%s", MSG_PREFIX, id, name);

    for (int i = 1; i <= MaxClients; i++)
    {
        RefreshLocMenu(i);
    }
}

// =====[ LOAD LOCATION ]=====
void LoadLocation(int client, int id)
{
    if (!IsPlayerAlive(client))
    {
        CPrintToChat(client, "%s {red}You must be alive to use that command.", MSG_PREFIX);
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

    // print message if loading new location
    if (g_iMostRecentLocation[client] != id)
    {
        g_iMostRecentLocation[client] = id;

        if (StrEqual(clientName, creator))
        {
            CPrintToChat(client, "%s {grey}Loaded {yellow}#%i {lightgreen}%s", MSG_PREFIX, id, name);
        }
        else
        {
            if (StrEqual(name, ""))
            {
                CPrintToChat(client, 
                    "%s {grey}Loaded {yellow}#%i {default}| {grey}Created by {lime}%s", 
                    MSG_PREFIX, id, creator);
            }
            else
            {
                CPrintToChat(client, 
                    "%s {grey}Loaded {yellow}#%i {lightgreen}%s {default}| {grey}Created by {lime}%s", 
                    MSG_PREFIX, id, name, creator);
            }
        }
    }

    RefreshLocMenu(client);
}

// =====[ NAME LOCATION ]=====
void NameLocation(int client, int id, char[] name)
{
    g_aLocationName.SetString(id, name);

    CPrintToChat(client, "%s {grey}Named {yellow}#%i {lightgreen}%s", MSG_PREFIX, id, name);

    for (int i = 1; i <= MaxClients; i++)
    {
        RefreshLocMenu(i);
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
        g_bLocMenuOpen[i] = false;
    }
}

void HookEvents()
{
    HookEvent("player_death", OnPlayerDeath);
    HookEvent("player_team", OnPlayerJoinTeam);
}

void RefreshLocMenu(int client)
{
    if (g_bLocMenuOpen[client])
    {
        ShowLocMenu(client);
    }
}

void CloseLocMenu(int client)
{
    if (g_bLocMenuOpen[client])
    {
        CancelClientMenu(client, true);
        g_bLocMenuOpen[client] = false;
    }
}

bool IsValidLocationId(int id)
{
    return !(id < 0) && !(id > g_aPosition.Length - 1);
}

bool IsValidLocationName(char[] name)
{
    // check if location name starts with letter and is unique
    return IsCharAlpha(name[0]) && g_aLocationName.FindString(name) == -1;
}

bool IsClientLocationCreator(int client, int id)
{
    char clientName[MAX_NAME_LENGTH];
    char creator[MAX_NAME_LENGTH];

    GetClientName(client, clientName, sizeof(clientName));
    g_aLocationCreator.GetString(id, creator, sizeof(creator));

    return StrEqual(clientName, creator);
}

stock bool IsValidClient(int client)
{
    return client >= 1 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client);
}