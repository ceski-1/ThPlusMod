//=============================================================================
// ThPlusProjectileScoutingOrb.
//=============================================================================

class ThPlusProjectileScoutingOrb extends ThProjectileScoutingOrbD;

function StartScouting(ThieveryPPawn tpp)
{
	if (!bInstigatorStartedScouting
		&& (tpp.CurrentReadBook != None || tpp.GetStateName() == 'PlayerReadingBook'))
	{
		// player threw a scouting orb and then started reading before it
		// landed. bypass initial forced activation to avoid state change bug
		bInstigatorStartedScouting = true;
		return;
	}
	Super.StartScouting(tpp);
}

defaultproperties
{
	ItemName="Scouting Orb"
}
