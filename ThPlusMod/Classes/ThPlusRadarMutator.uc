//=============================================================================
// ThPlusRadarMutator.
//=============================================================================

class ThPlusRadarMutator extends ThreatIndicatorMutator;

function ModifyPlayer(Pawn Other)
{
	local ThPlusRadarController T;

	Super(Mutator).ModifyPlayer(Other);

	if (PlayerPawn(Other) == None)
	{
		return;
	}

	foreach AllActors(class'ThPlusRadarController', T)
	{
		if (PlayerPawn(T.Owner) == PlayerPawn(Other))
		{
			return;
		}
	}

	Spawn(class'ThPlusRadarController', PlayerPawn(Other));
}

defaultproperties
{
}
