//=============================================================================
// ThPlusServerInfo.
//=============================================================================

class ThPlusServerInfo extends ThServerInfo;

// parent class uses this for rat frags, not server stats
function DrawServerStats(canvas C, GameReplicationInfo GRI)
{
	local int i, LineNum;
	local float XL, YL, XL2, YL2;
	local ThieveryPlayerReplicationInfo PRI;

	// draw section title
	C.Style = 3;
	C.DrawColor = class'TInfo'.static.GetColor(168, 16, 45);
	C.Font = GetTitleFont();
	C.TextSize(" ", XL, YL);
	C.SetPos(C.ClipX / 8.0 * 5.0, C.ClipY / 8.0 * 3.0);
	C.DrawText("Killer Rats");

	C.Style = 1; // 3 is preferred but set to 1 to match parent class
	C.Font = GetValueFont();
	C.TextSize(" ", XL2, YL2);
	for (i = 0; i < 32; i++)
	{
		PRI = ThieveryPlayerReplicationInfo(GRI.PRIArray[i]);
		if (PRI != None && PRI.Team == 255 && !PRI.bIsABot)
		{
			// draw player name
			C.DrawColor = class'TInfo'.static.GetColor(106, 106, 98);
			C.CurX = C.ClipX / 8.0 * 5.0;
			C.CurY = C.ClipY / 8.0 * 3.0 + (YL + 1.0) + (YL2 + 1.0) * LineNum;
			C.DrawText(PRI.PlayerName);

			// draw rat frags (moved right to avoid overlapping player names)
			C.DrawColor = class'TInfo'.static.GetColor(169, 169, 157);
			C.CurX = C.ClipX / 8.0 * 7.0;
			C.CurY = C.ClipY / 8.0 * 3.0 + (YL + 1.0) + (YL2 + 1.0) * LineNum;
			C.DrawText(PRI.RatFrags);

			LineNum++;
		}
	}
}

defaultproperties
{
}
