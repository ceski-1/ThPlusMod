//=============================================================================
// ThPlusConfigMenu.
//=============================================================================

class ThPlusConfigMenu extends UMenuModMenuItem;

function Setup()
{
	class'ThPlusConfig'.Default.ViewBob = class'ThPlusConfigClient'.static.GetViewBob();
	class'ThPlusConfig'.Default.AutoHideHealth = class'ThPlusConfigClient'.static.GetAutoHideHealth();
	class'ThPlusConfig'.Default.FrobItemOffset = class'ThPlusConfigClient'.static.GetFrobItemOffset();
	class'ThPlusConfig'.static.StaticSaveConfig();
	class'ThPlusConfigServer'.static.StaticSaveConfig();
}

function Execute()
{
	MenuItem.Owner.Root.CreateWindow(class'ThPlusConfigWindow', 0, 0, 0, 0, , true);
}

defaultproperties
{
	MenuCaption="ThPlusMod Config"
	MenuHelp="Configure ThPlusMod"
}
