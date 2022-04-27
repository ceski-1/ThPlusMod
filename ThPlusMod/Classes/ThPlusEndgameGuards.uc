//=============================================================================
// ThPlusEndgameGuards.
//=============================================================================

class ThPlusEndgameGuards extends ThEndgameSequenceGuards;

simulated function DisplayThiefVictory(canvas C)
{
	class'ThPlusEndgame'.static.DrawBackground(C, texture'GuardVictory');
}

defaultproperties
{
}
