# ThPlusMod
A collection of quality of life improvements for Thievery UT.

## Features
* FOV correction for widescreen resolutions
* Basic high resolution font support
* HUD scales correctly at higher resolutions
* Mouse smoothing can be fully disabled
* Adjustable view bob
* Auto-hide support for health icons, loot text, and compass
* Smoother net client movement
* Fixes and improvements for many HUD elements including the loadout screen, weapon hotbar, item wheel, bot order window, scoreboards, and more
* Updated configuration files that are optimized for modern computers, restore server browser functionality, and list all previously hidden ProMod settings

## Requirements
* **Clients**: Unreal Tournament [v436](https://unrealarchive.org/patches-updates/unreal-tournament/patches/patch-436/index.html)
* **Servers**: Unreal Tournament [v436](https://unrealarchive.org/patches-updates/unreal-tournament/patches/patch-436/index.html) or [v451b](https://unrealarchive.org/patches-updates/unreal-tournament/patches/utpg-patch-451b/index.html)
* [Thievery UT v1.7.5](https://www.moddb.com/mods/thievery-ut/downloads/thievery-ut-175)
* [Enhanced OpenGL Renderer v3.7](https://www.cwdohnal.com/utglr/#Installation%20instructions) (Recommended) or [Enhanced Direct3D9 Renderer v1.3](https://www.cwdohnal.com/utglr/)

## Installation
Extract the archive to your `UnrealTournament` directory.

## Usage
* **Clients**: Launch the game with `Thievery.exe` to play.
* **Servers**: To run a dedicated server, add the mutator to the command line. For example:
  ```
  ucc server TH-Flats.unr?game=ThieveryMod.ThieveryDeathMatchPlus?mutator=ThPlusMod.ThPlusMutator INI=ThAux.ini LOG=ThieveryDedicatedServer.log USERINI=ThieveryUser.ini -lanplay
  ```

## Client Settings
Client settings can be changed in-game (**Menu Bar > Mod > ThPlusMod Config**). These settings are also under `[ThPlusMod.ThPlusConfig]` in `ThieveryMod.ini`.

`bUseFOVCorrection=True`  
Use FOV correction.

`bUseMouseSmoothing=False`  
False fully disables mouse smoothing, otherwise UT99's smoothing is used.

`ViewBob=0.5`  
View bob amount. 0.0 to 1.0.

`bRaiseBehindView=True`  
Raise 3rd-person camera to eye height.

`AutoHideHealth=1`  
0: Always show, 1: Auto-hide, 2: Auto-hide at full health only.

`bAutoHideLoot=True`  
Auto-hide loot text.

`bAutoHideCompass=True`  
Auto-hide compass.

`bUseSlimHotbar=True`  
Use a darker and lower height weapon hotbar.

`FrobItemOffset=1`  
Offset when using an item that moves to the center of the screen (e.g. lockpicks).  
0: Above crosshair, 1: At crosshair, 2: Below crosshair

`bShowBotWindowHelp=True`  
Show the Select/Close/Back text and icons on the bot order window.

`bShowBotNamesOnMap=False`  
Show bot names on map screen.

`bUseModernTheme=True`  
Toggle between two sets of fonts, colors, portraits, and backgrounds.

## Server Settings
These settings are under `[ThPlusMod.ThPlusConfigServer]` in `ThieveryMod.ini`.

`bAllowFOVCorrection=True`  
Allow players to use FOV correction.

`bAllowViewBob=True`  
Allow players to adjust view bob amount.

`bAllowRaiseBehindView=True`  
Allow players to raise the 3rd-person camera height.

`bReplayPendingMove=True`  
Smoother client movement by replaying the pending move after saved moves (experimental).

`bLimitClientAdjust=True`  
Smoother client movement by limiting the frequency of client adjustments (experimental).

`MinNetSpeed=2600`  
Minimum client netspeed.

`MaxNetSpeed=10000`  
Maximum client netspeed. Maximum client framerate is `MaxNetSpeed / 64`.

## Compiling
1. Extract the source files to your `UnrealTournament` directory.
2. Run `MakeThPlusMod.bat` from `UnrealTournament\ThPlusMod`.
3. Generate fonts using UnrealEd from [OldUnreal-UTPatch469b](https://github.com/OldUnreal/UnrealTournamentPatches). See ThPlusFonts.txt for more details.
