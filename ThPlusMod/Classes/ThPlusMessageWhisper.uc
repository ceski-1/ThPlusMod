//=============================================================================
// ThPlusMessageWhisper.
//=============================================================================

class ThPlusMessageWhisper extends ThPlusMessageShout;

static function DrawBasicMessage(canvas C, float PosX, float PosY,
								 string MessageString)
{
	// do nothing
}

static function string GetPrefix(PlayerReplicationInfo RelatedPRI_1)
{
	local string Prefix, Loc;

	if (RelatedPRI_1.Team < 2)
	{
		Prefix = Default.TeamPrefix[RelatedPRI_1.Team];
		if (class'ThieveryConfigClient'.Default.bTeamMessagesShowLocation)
		{
			if (RelatedPRI_1.PlayerLocation != None)
			{
				Loc = RelatedPRI_1.PlayerLocation.LocationName;
			}
			else if (RelatedPRI_1.PlayerZone != None)
			{
				Loc = RelatedPRI_1.PlayerZone.ZoneName;
			}

			if (Loc != "")
			{
				Prefix = "("$Loc$") "$Prefix;
			}
		}
		return Prefix;
	}
	return "";
}

static function string AssembleString(HUD myHUD, optional int Switch,
									  optional PlayerReplicationInfo RelatedPRI_1,
									  optional String MessageString)
{
	local string Prefix;

	if (RelatedPRI_1 == None || RelatedPRI_1.PlayerName == "")
	{
		return "";
	}
	Prefix = GetPrefix(RelatedPRI_1);
	return Prefix$RelatedPRI_1.PlayerName$Default.infix@MessageString;
}

defaultproperties
{
	infix=" whispers : "
}
