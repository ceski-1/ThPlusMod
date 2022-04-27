//=============================================================================
// ThPlusWeaponBow.
//=============================================================================

class ThPlusWeaponBow extends ThWeaponBow;

simulated event RenderOverlays(canvas C)
{
	local ThieveryPPawn tpp;

	tpp = ThieveryPPawn(Owner);
	if (tpp != None && tpp.DesiredFOV != tpp.DefaultFOV)
	{
		// hide arrows when fov is changing. same behavior as other weapons
		return;
	}

	ArrowLoadingOffset = Default.ArrowLoadingOffset;
	if (tpp != None)
	{
		// fov correction
		ArrowLoadingOffset *= tpp.DefaultFOV / 90.0;
	}

	Super.RenderOverlays(C);
}

function vector CalcArrowStart()
{
	local vector PVO, DrawOffset;
	local ThieveryPPawn tpp;

	tpp = ThieveryPPawn(Owner);
	if (tpp != None)
	{
		PVO.X = 1825.0 - Min(0.9, CurrentChargeTime) / 0.9 * 600.0;
		PVO.Y = 400.0;
		PVO.Z = -800.0;

		// fov correction
		DrawOffset = (0.01 * tpp.DefaultFOV / tpp.FOVAngle * PVO) >> tpp.ViewRotation;

		if (Level.NetMode == NM_DedicatedServer
			|| (Level.NetMode == NM_ListenServer && tpp.RemoteRole == ROLE_AutonomousProxy))
		{
			DrawOffset += tpp.BaseEyeHeight * vect(0, 0, 1);
			if (tpp.LeanCurve != 0.0)
			{
				DrawOffset += tpp.GetLeanoffset();
			}
		}
		else
		{
			DrawOffset += tpp.EyeHeight * vect(0, 0, 1) + tpp.WalkBob;
		}
		return DrawOffset;
	}
	return Super.CalcArrowStart();
}

defaultproperties
{
}
