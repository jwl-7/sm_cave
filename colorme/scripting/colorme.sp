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
    url         = "" 
}; 

// ====[ EVENTS ]====
public OnPluginStart() 
{
    RegConsoleCmd("sm_colorme", Command_ColorMe, "Change color of player model.");
    mp_forcecamera = FindConVar("mp_forcecamera");
}

// ====[ COMMANDS ]====
public Action Command_ColorMe(int client, int args)
{
    if (!IsPlayerAlive(client))
    {
        CPrintToChat(client, "[{green}ColorMe{default}] {grey}You must be alive to use {purple}!colorme");
        return Plugin_Handled;
    }
    if (IsClientMoving(client))
    {
        CPrintToChat(client, "[{green}ColorMe{default}] {grey}You must be standing still to use {purple}!colorme");
        return Plugin_Handled;
    }

    Menu ColorMenu = new Menu(ColorMenuHandler, MENU_ACTIONS_ALL);
    ColorMenu.SetTitle("Color Me");
    ColorMenu.AddItem("255,255,255", "None");
    ColorMenu.AddItem("244,67,54", "Red");
    ColorMenu.AddItem("255,152,0", "Orange");
    ColorMenu.AddItem("255,235,59", "Yellow");
    ColorMenu.AddItem("76,175,80", "Green");
    ColorMenu.AddItem("33,150,243", "Blue");
    ColorMenu.AddItem("63,81,181", "Indigo");
    ColorMenu.AddItem("156,39,176", "Purple");
    ColorMenu.AddItem("103,58,183", "Deep Purple");
    ColorMenu.AddItem("233,30,99", "Pink");
    ColorMenu.AddItem("3,169,244", "Light Blue");
    ColorMenu.AddItem("0,188,212", "Cyan");
    ColorMenu.AddItem("0,150,136", "Teal");
    ColorMenu.AddItem("139,195,74", "Light Green");
    ColorMenu.AddItem("205,220,57", "Lime");
    ColorMenu.AddItem("255,193,7", "Amber");
    ColorMenu.AddItem("255,87,34", "Deep Orange")
    ColorMenu.AddItem("121,85,72", "Brown");
    ColorMenu.AddItem("158,158,158", "Grey");
    ColorMenu.AddItem("96,125,139", "Blue Grey");
    ColorMenu.AddItem("0,0,0", "Black");
    ColorMenu.AddItem("255,215,0", "Gold");
    ColorMenu.Display(client, 20);

    return Plugin_Handled;
}

// ====[ Menu Handler ]====
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
            menu.GetItem(choice, colorValue, sizeof(colorValue), _, colorName, sizeof(colorName));
            menu.DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
            
            char rgb[3][4];
            ExplodeString(colorValue, ",", rgb, sizeof(rgb), sizeof(rgb[]));

            int r = StringToInt(rgb[0]);
            int g = StringToInt(rgb[1]);
            int b = StringToInt(rgb[2]);
            SetEntityRenderColor(client, r, g, b);
            CPrintToChat(client, "[{green}ColorMe{default}] Player model set to {lime}%s", colorName);
        }

        case MenuAction_Cancel:
        {
            SetModelView(client, false);
        }
    }
    
    return 0;
}

// ====[ LOCAL FUNCTIONS ]====
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

bool IsClientMoving(int client)
{
    float buffer[3];
    GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", buffer);
    return (GetVectorLength(buffer) > 0.0);
}  