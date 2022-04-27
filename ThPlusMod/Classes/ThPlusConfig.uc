//=============================================================================
// ThPlusConfig.
//=============================================================================

class ThPlusConfig extends Info config(ThieveryMod);

var globalconfig bool bUseFOVCorrection;  // fov adjusted to current aspect ratio
var globalconfig bool bUseMouseSmoothing; // false = none, true = ut99 behavior
var globalconfig float ViewBob;           // 0.0 (none) to 1.0 (thievery default)
var globalconfig bool bRaiseBehindView;   // raise behind view to eye height
var globalconfig int AutoHideHealth;      // 0 = disabled, 1 = enabled, 2 = full health only
var globalconfig bool bAutoHideLoot;      // auto-hide loot text
var globalconfig bool bAutoHideCompass;   // auto-hide compass
var globalconfig bool bUseSlimHotbar;     // darker and lower height hotbar
var globalconfig int FrobItemOffset;      // 0 = above crosshair, 1 = at crosshair, 2 = below crosshair
var globalconfig bool bShowBotWindowHelp; // select/close/back text and icons
var globalconfig bool bShowBotNamesOnMap; // bot names on map screen
var globalconfig bool bUseModernTheme;    // fonts, colors, portraits, backgrounds

defaultproperties
{
	bUseFOVCorrection=true
	bUseMouseSmoothing=false
	ViewBob=0.5
	bRaiseBehindView=true
	AutoHideHealth=1
	bAutoHideLoot=true
	bAutoHideCompass=true
	bUseSlimHotbar=true
	FrobItemOffset=1
	bShowBotWindowHelp=true
	bShowBotNamesOnMap=false
	bUseModernTheme=true
}
