//=============================================================================
// ThPlusEndgameThiefMatch.
//=============================================================================

class ThPlusEndgameThiefMatch extends ThEndgameSequenceThiefMatch;

simulated function DisplayThiefVictory(canvas C)
{
	class'ThPlusEndgame'.static.DrawBackground(C, texture'ThiefVictory');
}

defaultproperties
{
}
