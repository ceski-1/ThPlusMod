//=============================================================================
// ThPlusConfigWindow.
//=============================================================================

class ThPlusConfigWindow extends ThPlayerWindow;

function Created()
{
	Super.Created();
	bSizable = false;
}

function SetSizePos()
{
	SetSize(256, 394);
	WinLeft = (Root.WinWidth - WinWidth) / 2;
	WinTop = (Root.WinHeight - WinHeight) / 2;
}

defaultproperties
{
	ClientClass=class'ThPlusConfigClient'
	WindowTitle="ThPlusMod Config"
}
