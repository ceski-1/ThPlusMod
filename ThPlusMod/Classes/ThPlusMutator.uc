//=============================================================================
// ThPlusMutator.
//=============================================================================

class ThPlusMutator extends Mutator;

function ModifyLogin(out class<PlayerPawn> SpawnClass, out string Portal, out string Options)
{
	Super.ModifyLogin(SpawnClass, Portal, Options);
	if (SpawnClass == class'ThieveryProPawn')
	{
		SpawnClass = class'ThPlusPawn';
	}
}

function ModifyPlayer(Pawn Other)
{
	local ThPlusPawn tpp;
	local int MinNetSpeed, MaxNetSpeed;

	Super.ModifyPlayer(Other);
	tpp = ThPlusPawn(Other);
	if (tpp != none)
	{
		tpp.bAllowFOVCorrection = class'ThPlusConfigServer'.Default.bAllowFOVCorrection;
		tpp.bAllowViewBob = class'ThPlusConfigServer'.Default.bAllowViewBob;
		tpp.bAllowRaiseBehindView = class'ThPlusConfigServer'.Default.bAllowRaiseBehindView;
		tpp.bReplayPendingMove = class'ThPlusConfigServer'.Default.bReplayPendingMove;
		tpp.bLimitClientAdjust = class'ThPlusConfigServer'.Default.bLimitClientAdjust;
		MinNetSpeed = Max(500, class'ThPlusConfigServer'.Default.MinNetSpeed);
		MaxNetSpeed = Max(0, class'ThPlusConfigServer'.Default.MaxNetSpeed);
		if (MaxNetSpeed > 0)
		{
			MaxNetSpeed = Max(MinNetSpeed, MaxNetSpeed);
		}
		tpp.MinNetSpeed = MinNetSpeed;
		tpp.MaxNetSpeed = MaxNetSpeed;
	}
}

event PreBeginPlay()
{
	Level.Game.BaseMutator.AddMutator(Self);
	switch (Level.Game.HudType)
	{
		case class'ThHUD':
		case class'ThProHud':
		case class'ThieveryThiefMatchHUD':
			Level.Game.HudType = class'ThPlusHUD';
			break;
		default:
			break;
	}
	switch (Level.Game.ScoreBoardType)
	{
		case class'ThieveryScoreBoard':
		case class'ThProScoreBoard':
		case class'ThieveryScoreBoardThiefMatch':
			Level.Game.ScoreBoardType = class'ThPlusScoreboard';
			break;
		default:
			break;
	}
	Spawn(class'ThPlusReplacer');
}

function AddMutator(Mutator M)
{
	if (M != Self)
	{
		if (M.Class != class'ThPlusMutator')
		{
			Super.AddMutator(M);
		}
		else
		{
			M.Destroy();
		}
	}
}

defaultproperties
{
}
