#include <sourcemod>
#include <multicolors>

#define HIDE_CROSSHAIR 1 << 8
#define HIDE_RADAR 1 << 12

Handle mp_forcecamera;

public Plugin myinfo = 
{ 
    name        = "Color Me", 
    author      = "JWL", 
    description = "Color Yourself", 
    version     = "2.0", 
    url         = "https://github.com/jwl-7/sm_cave" 
}; 

// ====[ EVENTS ]====
public OnPluginStart() 
{
    RegConsoleCmd("sm_colorme", Command_ColorMe, "Open menu to change color of player model. Usage: !colorme");
    mp_forcecamera = FindConVar("mp_forcecamera");
}

// ====[ COMMANDS ]====
public Action Command_ColorMe(int client, int args)
{
    if (!IsPlayerAlive(client))
    {
        CPrintToChat(client, "[{green}ColorMe{default}] {lightred}You must be alive to use this command.");
        return Plugin_Handled;
    }
    if (IsClientMoving(client))
    {
        CPrintToChat(client, "[{green}ColorMe{default}] {lightred}You must be standing still to use this command.");
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
            CPrintToChat(client, "[{green}ColorMe{default}] {grey}Player model set to {lime}%s", colorName);

            ShowColorMenu(client, menu.Selection);
        }

        case MenuAction_Cancel:
        {
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
    if (!IsPlayerAlive(client))
    {
        return;
    }
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
stock bool IsClientMoving(int client)
{
    float buffer[3];
    GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", buffer);
    return (GetVectorLength(buffer) > 0.0);
}  