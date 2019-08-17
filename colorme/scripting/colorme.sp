#include <sourcemod>
#include <sourcemod-colors>

#define HIDE_CROSSHAIR 1 << 8
#define HIDE_RADAR 1 << 12
#define MSG_PREFIX "[{green}ColorMe{default}]"

Handle mp_forcecamera;

static bool g_bColorMenuOpen[MAXPLAYERS+1];

public Plugin myinfo = 
{ 
    name        = "Color Me", 
    author      = "JWL", 
    description = "Color Yourself", 
    version     = "2.0", 
    url         = "https://github.com/jwl-7/sm_cave" 
}; 

// ====[ EVENTS ]====
public void OnPluginStart() 
{
    RegConsoleCmd("sm_colorme", Command_ColorMe, "Open menu with color choices. Usage: !colorme");
    mp_forcecamera = FindConVar("mp_forcecamera");
    HookEvents();
}

public void OnMapStart()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        g_bColorMenuOpen[i] = false;
    }
}

// ====[ CLIENT EVENTS ]====
public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    CloseColorMenu(client);
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    CloseColorMenu(client);
}

public void OnPlayerJoinTeam(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    CloseColorMenu(client);
}

// ====[ COMMANDS ]====
public Action Command_ColorMe(int client, int args)
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
    else if (IsClientMoving(client))
    {
        CPrintToChat(client, "%s {red}You must be standing still to use that command.", MSG_PREFIX);
        return Plugin_Handled;
    }

    ShowColorMenu(client, 0);

    return Plugin_Handled;
}

// ====[ BUILD MENU ]====
void ShowColorMenu(int client, int selection)
{
    Menu colorMenu = new Menu(ColorMenuHandler, MENU_ACTIONS_ALL);
    colorMenu.SetTitle("Color Me");

    colorMenu.AddItem("255,255,255", "None");
    colorMenu.AddItem("244,67,54", "Red");
    colorMenu.AddItem("255,152,0", "Orange");
    colorMenu.AddItem("255,235,59", "Yellow");
    colorMenu.AddItem("76,175,80", "Green");
    colorMenu.AddItem("33,150,243", "Blue");
    colorMenu.AddItem("63,81,181", "Indigo");
    colorMenu.AddItem("156,39,176", "Purple");
    colorMenu.AddItem("103,58,183", "Deep Purple");
    colorMenu.AddItem("233,30,99", "Pink");
    colorMenu.AddItem("3,169,244", "Light Blue");
    colorMenu.AddItem("0,188,212", "Cyan");
    colorMenu.AddItem("0,150,136", "Teal");
    colorMenu.AddItem("139,195,74", "Light Green");
    colorMenu.AddItem("205,220,57", "Lime");
    colorMenu.AddItem("255,193,7", "Amber");
    colorMenu.AddItem("255,87,34", "Deep Orange")
    colorMenu.AddItem("121,85,72", "Brown");
    colorMenu.AddItem("158,158,158", "Grey");
    colorMenu.AddItem("96,125,139", "Blue Grey");
    colorMenu.AddItem("0,0,0", "Black");
    colorMenu.AddItem("255,215,0", "Gold");

    colorMenu.DisplayAt(client, selection, MENU_TIME_FOREVER);
}

// ====[ MENU HANDLER ]====
public int ColorMenuHandler(Menu menu, MenuAction action, int client, int choice) 
{
    switch(action)
    {
        case MenuAction_Display:
        {
            g_bColorMenuOpen[client] = true;
            SetModelView(client, true);
        }

        case MenuAction_Select:
        {
            char colorValue[12];
            char colorName[32]
            char rgb[3][4];
            menu.GetItem(choice, colorValue, sizeof(colorValue), _, colorName, sizeof(colorName));
            ExplodeString(colorValue, ",", rgb, sizeof(rgb), sizeof(rgb[]));

            int r = StringToInt(rgb[0]);
            int g = StringToInt(rgb[1]);
            int b = StringToInt(rgb[2]);
            SetEntityRenderColor(client, r, g, b);

            CPrintToChat(client, "%s {grey}Player model set to {blue}%s", MSG_PREFIX, colorName);

            ShowColorMenu(client, menu.Selection);
        }

        case MenuAction_Cancel:
        {
            g_bColorMenuOpen[client] = false;
            SetModelView(client, false);
        }

        case MenuAction_End:
        {
            delete menu;
        }
    }
    
    return 0;
}

// ====[ THIRD-PERSON MIRROR VIEW ]====
void SetModelView(int client, bool view)
{
    if (view)
    {
        SendConVarValue(client, mp_forcecamera, "1");
        SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0); 
        SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
        SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
        SetEntProp(client, Prop_Send, "m_iFOV", 120);
        SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_RADAR);
        SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_CROSSHAIR);
        SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.0);
    }
    else
    {
        char value[6];
        GetConVarString(mp_forcecamera, value, 6);
        SendConVarValue(client, mp_forcecamera, value);
        SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
        SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
        SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
        SetEntProp(client, Prop_Send, "m_iFOV", 90);
        SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") & ~HIDE_RADAR);
        SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") & ~HIDE_CROSSHAIR);
        SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
    }
}

// ====[ HELPER FUNCTIONS]====
void HookEvents()
{
    HookEvent("player_spawn", OnPlayerSpawn);
    HookEvent("player_death", OnPlayerDeath);
    HookEvent("player_team", OnPlayerJoinTeam);
}

void CloseColorMenu(int client)
{
    if (g_bColorMenuOpen[client])
    {
        CancelClientMenu(client, true);
        g_bColorMenuOpen[client] = false;
    }
}

stock bool IsValidClient(int client)
{
    return client >= 1 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client);
}

stock bool IsClientMoving(int client)
{
    float buffer[3];
    GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", buffer);
    
    return (GetVectorLength(buffer) > 0.0);
}  