//=============================================================================
// ThPlusWeaponCrossbow.
//=============================================================================

class ThPlusWeaponCrossbow extends ThWeaponCrossbow;

simulated function DrawCrossHair(canvas C, float StartX, float StartY)
{
	local float ScaleY;

	// scale crosshair correctly
	ScaleY = 0.8 * class'ThHUD'.static.GetScaleY(C.ClipX, C.ClipY);
	C.Style = 3;
	C.DrawColor = class'ThHUD'.Default.UnitColor * CurrentCrosshairBrightness;
	C.CurX = 0.5 * C.ClipX - 64.0 * CrossbowCrosshairScale * ScaleY;
	C.CurY = 0.5 * C.ClipY - 64.0 * CrossbowCrosshairScale * ScaleY + CrossbowCrossHairYOffset * ScaleY;
	C.DrawIcon(CrossbowCrosshair, CrossbowCrosshairScale * 2.0 * ScaleY);
}

// smoother client bring up animation

function BringUp()
{
	Super(ThieveryWeapon).BringUp();
	if (Level.NetMode != NM_Standalone && Level.NetMode != NM_ListenServer)
	{
		ClientPlayBringUp();
	}
}

simulated function PlaySelect()
{
	if (AnimSequence != 'Select')
	{
		PlayAnim('Down');
	}
	TweenAnim('Select', 0.3);
}

state ClientActive
{
	simulated function BeginState()
	{
		Super.BeginState();
		PlaySelect();
	}
}

defaultproperties
{
}
