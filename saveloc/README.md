# SaveLoc
This plugin allows the player to save/load locations, which preserve position/angle/velocity.

## Commands
* ```sm_saveloc``` - Save location. Usage: ```!saveloc <name>```
* ```sm_loadloc``` - Load location. Usage: ```!loadloc <#id OR name>```
* ```sm_locmenu``` - Open location menu. Usage: ```!locmenu```
* ```sm_nameloc``` - Name location. Usage: ```!nameloc <#id> <name>```

## Features
* Players can save, load, and name their locations
* Players can load each other's locations by <#id OR name>
* Location menu shows all saved locations
* Location menu automatically updates new saved locations/names

## Usage Guide
* ```sm_saveloc```
    * ```!saveloc``` - Saves location with an <#id>
    * ```!saveloc <name>``` - Saves location with an <#id> and specified <name>
        * location <name> must start with a letter and be unique
* ```sm_loadloc```
    * ```!loadloc``` - Loads most recent location
    * ```!loadloc <#id>``` - Loads location by <#id>
    * ```!loadloc <name>``` - Loads location by <name>
* ```sm_locmenu```
    * ```!locmenu``` - Opens location menu
        * menu shows all saved locations created by every player
        * selecting a location on the menu loads the location
        * player's most recent location is indicated by '>'
* ```sm_nameloc```
    * ```!nameloc <name>``` - Names most recent location
    * ```!nameloc <#id> <name>``` - Names specified location
        * players can't name each other's locations
        * location <name> must start with a letter and be unique