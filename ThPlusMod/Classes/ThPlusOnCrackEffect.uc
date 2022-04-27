//=============================================================================
// ThPlusOnCrackEffect.
//=============================================================================

class ThPlusOnCrackEffect extends OnCrackEffect;

state FadingOut
{
	simulated function Timer()
	{
		Super.Timer();
		PlayerPawn(Owner).DesiredFOV = PlayerPawn(Owner).DefaultFOV;
	}
}

simulated function GoAwayTaffer()
{
	Super.GoAwayTaffer();
	PlayerPawn(Owner).DesiredFOV = PlayerPawn(Owner).DefaultFOV;
}

defaultproperties
{
}
