//=============================================================================
// ThPlusReplacer.
//=============================================================================

class ThPlusReplacer extends SpawnNotify;

simulated function Actor ReplaceActor(Actor A, class<Actor> ReplacementClass)
{
	local Actor ReplacementActor;

	ReplacementActor = Spawn(ReplacementClass, A.Owner, A.Tag, A.Location, A.Rotation);
	if (ReplacementActor != None)
	{
		ReplacementActor.Instigator = A.Instigator;
		A.Destroy();
		return ReplacementActor;
	}
	return A;
}

simulated event Actor SpawnNotification(Actor A)
{
	switch (A.Class)
	{
		case class'OnCrackEffect':
			return ReplaceActor(A, class'ThPlusOnCrackEffect');
		case class'ThreatIndicatorMutator':
			return ReplaceActor(A, class'ThPlusRadarMutator');
		case class'ThWeaponBow':
			return ReplaceActor(A, class'ThPlusWeaponBow');
		case class'ThWeaponBowLightweight':
			return ReplaceActor(A, class'ThPlusWeaponBowLight');
		case class'ThWeaponCrossbow':
			return ReplaceActor(A, class'ThPlusWeaponCrossbow');
		case class'ThProjectileScoutingOrbD':
			return ReplaceActor(A, class'ThPlusProjectileScoutingOrb');
		case class'ThEndgameSequence':
			return ReplaceActor(A, class'ThPlusEndgame');
		case class'ThEndgameSequenceGuards':
			return ReplaceActor(A, class'ThPlusEndgameGuards');
		case class'ThEndgameSequenceThiefMatch':
			return ReplaceActor(A, class'ThPlusEndgameThiefMatch');
		default:
			return A;
	}
}

defaultproperties
{
}
