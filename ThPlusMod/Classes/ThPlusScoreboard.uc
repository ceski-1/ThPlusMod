//=============================================================================
// ThPlusScoreboard.
//=============================================================================

class ThPlusScoreboard extends ThProScoreBoard;

#exec TEXTURE IMPORT NAME=SplashLogo FILE=Textures\SplashLogo.pcx GROUP=HUD MIPS=ON
#exec TEXTURE IMPORT NAME=SplashLogoUT FILE=Textures\SplashLogoUT.pcx GROUP=HUD MIPS=ON
#exec TEXTURE IMPORT NAME=ScoreBG0 FILE=Textures\ScoreBG0.pcx GROUP=HUD MIPS=ON
#exec TEXTURE IMPORT NAME=ScoreBG1 FILE=Textures\ScoreBG1.pcx GROUP=HUD MIPS=ON
#exec TEXTURE IMPORT NAME=ScoreBG2 FILE=Textures\ScoreBG2.pcx GROUP=HUD MIPS=ON
#exec TEXTURE IMPORT NAME=ScoreBG3 FILE=Textures\ScoreBG3.pcx GROUP=HUD MIPS=ON
#exec TEXTURE IMPORT NAME=ScoreBG4 FILE=Textures\ScoreBG4.pcx GROUP=HUD MIPS=ON
#exec TEXTURE IMPORT NAME=ScoreBG5 FILE=Textures\ScoreBG5.pcx GROUP=HUD MIPS=ON
#exec TEXTURE IMPORT NAME=ScoreBG6 FILE=Textures\ScoreBG6.pcx GROUP=HUD MIPS=ON
#exec TEXTURE IMPORT NAME=ScoreBG7 FILE=Textures\ScoreBG7.pcx GROUP=HUD MIPS=ON
#exec TEXTURE IMPORT NAME=ScoreBG8 FILE=Textures\ScoreBG8.pcx GROUP=HUD MIPS=ON
#exec TEXTURE IMPORT NAME=ScoreBG9 FILE=Textures\ScoreBG9.pcx GROUP=HUD MIPS=ON
#exec TEXTURE IMPORT NAME=ScoreBG10 FILE=Textures\ScoreBG10.pcx GROUP=HUD MIPS=ON
#exec TEXTURE IMPORT NAME=ScoreBG11 FILE=Textures\ScoreBG11.pcx GROUP=HUD MIPS=ON
#exec TEXTURE IMPORT NAME=ScoreBG12 FILE=Textures\ScoreBG12.pcx GROUP=HUD MIPS=ON
#exec TEXTURE IMPORT NAME=ScoreBG13 FILE=Textures\ScoreBG13.pcx GROUP=HUD MIPS=ON
#exec TEXTURE IMPORT NAME=ScoreBG14 FILE=Textures\ScoreBG14.pcx GROUP=HUD MIPS=ON

var ThieveryPPawn tpp;
var ThieveryGameReplicationInfo tppGRI;
var ThieveryPlayerReplicationInfo tppPRI;
var TeamChangeClient TeamWin;             // pre-game join buttons
var font ScoreFontSmall, ScoreFontMedium; // scoreboard fonts
var color ModernTeamColor[2];             // modern theme team colors
var texture SplashLetterTex[8];           // original thievery logo letters
var int PlayerCount;                      // total player count
var int TeamPlayerCount[2];               // player count of each team
var int MaxTeamPlayerCount;               // player count of team with most players
var string SpectatorNames;                // names and pings of spectators in one string
var float CScoreOffset, ScoreOffset;      // score column offsets for main scoreboard

// post-game awards
var bool bGeneratedAwards;
var string AwardName[16], AwardedPlayerName[16];

// column names for post-game stats
var string ThiefStatName[16], GuardStatName[16], ThiefMatchStatName[16];
var string LowResThiefName[16], LowResGuardName[16], LowResThiefMatchName[16];

//=============================================================================
// initial scoreboard

function ShowScores(canvas C)
{
	tpp = ThieveryPPawn(Owner);
	if (tpp == None || ThHUD(tpp.myHUD) == None)
	{
		return;
	}
	tppGRI = ThieveryGameReplicationInfo(tpp.GameReplicationInfo);
	tppPRI = ThieveryPlayerReplicationInfo(tpp.PlayerReplicationInfo);
	if (tppGRI == None || tppPRI == None)
	{
		return;
	}

	C.Reset();
	scaleY = class'ThHUD'.static.GetScaleY(C.ClipX, C.ClipY);
	FindSomeFonts(C);
	UpdatePlayersAndSort();
	switch (tpp.GetStateName())
	{
		case 'GameEnded':
			DrawPostGameScoreboard(C);
			break;
		case 'PlayerWaiting':
			UpdateTeamChangeClient();
			DrawPreGameScoreboard(C);
			break;
		default:
			DrawMainScoreboard(C);
			break;
	}
}

//=============================================================================
// update pre-game scoreboard buttons (ideally this is done in TeamChangeClient)
//
// 1. keep buttons visible when switching between windowed and fullscreen
// 2. apply team colors to text

simulated function UpdateTeamChangeClient()
{
	local WindowConsole Con;

	if (TeamWin == None)
	{
		Con = WindowConsole(tpp.Player.Console);
		if (Con != None && Con.Root != None)
		{
			TeamWin = TeamChangeClient(Con.Root.FindChildWindow(class'TeamChangeClient', true));
		}
	}

	if (TeamWin != None)
	{
		TeamWin.DoLayout();
		TeamWin.JoinRed.TextColor = GetTeamColor(0);
		TeamWin.JoinBlue.TextColor = GetTeamColor(1);
	}
}

//=============================================================================
// player count, spectators, and score sorting

simulated function UpdatePlayersAndSort()
{
	local int i;
	local string PingText;
	local PlayerReplicationInfo PRI;
	local bool bLimitAIInfo;

	// show or hide bots in scoreboard list (see ThPlusPawn.PostBeginPlay())
	bLimitAIInfo = (class'ThieveryProModSettings'.Default.bLimitAIInfo
					&& tpp.GetStateName() != 'PlayerWaiting'
					&& tpp.GetStateName() != 'GameEnded');

	PlayerCount = 0;
	TeamPlayerCount[0] = 0;
	TeamPlayerCount[1] = 0;
	SpectatorNames = "";
	for (i = 0; i < 32; i++)
	{
		Ordered[i] = None;
	}

	for (i = 0; i < 32; i++)
	{
		PRI = tppGRI.PRIArray[i];
		if (PRI != None)
		{
			if (!PRI.bIsSpectator && PRI.Team < 2 && !(bLimitAIInfo && PRI.bIsAbot))
			{
				Ordered[PlayerCount] = PRI;
				PlayerCount++;
				TeamPlayerCount[PRI.Team]++;
			}
			else if ((PRI.bIsSpectator || PRI.Team == 255) && !PRI.bIsAbot
					 && Level.NetMode != NM_Standalone)
			{
				if (SpectatorNames != "")
				{
					SpectatorNames = SpectatorNames$", ";
				}
				PingText = " ("$Min(999, PRI.Ping)$")";
				SpectatorNames = SpectatorNames$PRI.PlayerName$PingText;
			}
		}
	}
	MaxTeamPlayerCount = Max(TeamPlayerCount[0], TeamPlayerCount[1]);

	// sort players by score, then by humans/bots
	Super(TeamScoreBoard).SortScores(PlayerCount);
	if (tpp.GetStateName() != 'GameEnded')
	{
		SortScores(PlayerCount);
	}
}

//=============================================================================
// fonts

simulated function FindSomeFonts(canvas C)
{
	if (C.ClipY < 720) // 0 to 719
	{
		ScoreFontSmall = Font'Engine.SmallFont';
		ScoreFontMedium = class'ThPlusHUD'.static.GetScaledFont(C, "ThClean", 16);
	}
	else // 720 and up
	{
		ScoreFontSmall = class'ThPlusHUD'.static.GetScaledFont(C, "ThClean", 10);
		if (class'ThPlusConfig'.Default.bUseModernTheme)
		{
			ScoreFontMedium = class'ThPlusHUD'.static.GetScaledFont(C, "ThSerif", 16);
		}
		else
		{
			ScoreFontMedium = class'ThPlusHUD'.static.GetScaledFont(C, "ThSans", 16);
		}
	}
}

//=============================================================================
// colors

static final operator(34) color *= (out color A, float B)
{
	A = A * B;
	return A;
}

static function color GetTeamColor(byte Team)
{
	if (Team < 2)
	{
		if (class'ThPlusConfig'.Default.bUseModernTheme)
		{
			return Default.ModernTeamColor[Team];
		}
		else
		{
			return Default.AltTeamColor[Team];
		}
	}
	return Default.WhiteColor;
}

simulated function color GetPlayerNameColor(PlayerReplicationInfo PRI)
{
	if (PRI.bAdmin)
	{
		return RedColor;
	}
	else if (PRI.PlayerName == tppPRI.PlayerName)
	{
		return GoldColor;
	}
	else if (PRI.bWaitingPlayer || (PRI.Deaths > 0 && PRI.bIsABot))
	{
		return GrayColor;
	}
	return WhiteColor;
}

simulated function color GetColorByPlayerNameOnly(string PlayerName)
{
	if (PlayerName == tppPRI.PlayerName)
	{
		return GoldColor;
	}
	return WhiteColor;
}

//=============================================================================
// line height for each player score row

simulated function float GetLineHeight(canvas C, float MinHeight, float MaxHeight)
{
	local float TrailerPad, TrailerHeight, LineHeight;

	TrailerPad = 16.0 * scaleY;
	TrailerHeight = 112.0 * scaleY;
	LineHeight = C.ClipY - ScoreStart - TrailerHeight - TrailerPad;
	LineHeight /= FMax(1.0, MaxTeamPlayerCount);
	LineHeight = FClamp(LineHeight, MinHeight, MaxHeight);
	return LineHeight;
}

//=============================================================================
// spectators

simulated function DrawSpectatorNames(canvas C)
{
	local float Pad, TimePad, BottomBarH;
	local float PosX, PosY, TextW, TextH, TrimWidth;
	local string LabelText;

	if (SpectatorNames == "")
	{
		return;
	}

	C.Reset();
	C.Style = 3;
	Pad = 12.0 * scaleY;
	TimePad = 116.0 * scaleY;
	BottomBarH = 32.0 * scaleY;

	LabelText = "Spectating: ";
	C.Font = ThHUD(tpp.myHUD).SansFontSmall;
	C.TextSize(LabelText, TextW, TextH);
	C.Font = ThHUD(tpp.myHUD).SansFontMedium;
	TrimWidth = 0.5 * C.ClipX - (Pad + TextW) - TimePad;
	SpectatorNames = class'ThPlusHUD'.static.TrimText(C, SpectatorNames, TrimWidth);

	PosX = Pad;
	PosY = C.ClipY - 0.5 * BottomBarH - 0.5 * TextH;

	ThHUD(tpp.myHUD).DrawLabelAndValue(C, PosX, PosY, LabelText, SpectatorNames, false);
}

//=============================================================================
// next map

simulated function DrawNextMapName(canvas C)
{
	local float Pad, TimePad, BottomBarH;
	local float PosX, PosY, TextW, TextH, NextMapTextW, NextMapTextH, TrimWidth;
	local string LabelText, NextMapName;

	C.Reset();
	C.Style = 3;
	Pad = 12.0 * scaleY;
	TimePad = 116.0 * scaleY;
	BottomBarH = 32.0 * scaleY;

	LabelText = "Next Map: ";
	C.Font = ThHUD(tpp.myHUD).SansFontSmall;
	C.TextSize(LabelText, TextW, TextH);
	C.Font = ThHUD(tpp.myHUD).SansFontMedium;
	TrimWidth = 0.5 * C.ClipX - (Pad + TextW) - TimePad;
	NextMapName = class'ThPlusHUD'.static.TrimText(C, tppGRI.NextMapName, TrimWidth);

	C.TextSize(NextMapName, NextMapTextW, NextMapTextH);
	PosX = C.ClipX - TextW - NextMapTextW - Pad;
	PosY = C.ClipY - 0.5 * BottomBarH - 0.5 * TextH;

	ThHUD(tpp.myHUD).DrawLabelAndValue(C, PosX, PosY, LabelText, NextMapName, false);
}

//=============================================================================
// tiled background

simulated function DrawBackground(canvas C)
{
	local int i, j, k, NumTilesX, NumTilesY;
	local float PosX, PosY, TileScale, TileSize;
	local texture Tex;

	C.Reset();
	NumTilesX = 5;
	NumTilesY = 3;
	TileScale = 768.0 / 720.0 * scaleY; // hide black bars
	TileSize = 256.0 * TileScale;
	PosX = 0.5 * C.ClipX - 0.5 * (NumTilesX * TileSize);
	PosY = 0.5 * C.ClipY - 0.5 * (NumTilesY * TileSize);
	C.bNoSmooth = true;
	for (j = 0; j < NumTilesY; j++)
	{
		for (i = 0; i < NumTilesX; i++)
		{
			C.SetPos(PosX + i * TileSize, PosY + j * TileSize);
			Tex = texture(DynamicLoadObject("ThPlusMod.ScoreBG"$k, class'Texture'));
			if (Tex != None)
			{
				C.DrawTileClipped(Tex, TileSize, TileSize, 0.0, 0.0, 256.0, 256.0);
			}
			k++;
		}
	}
	C.bNoSmooth = false;
}

//=============================================================================
// header

simulated function DrawPreGameScoreboardHeader(canvas C)
{
	local float Pad, IconScale, IconSize, TopBarH, BottomBarH;
	local float TeamOffsetX, TeamPosX[2], TextW, TextH;

	C.Reset();
	if (class'ThPlusConfig'.Default.bUseModernTheme)
	{
		Pad = 12.0 * scaleY;
		TopBarH = 128.0 * scaleY;
		IconScale = 128.0 / 256.0 * scaleY;
		IconSize = 128.0 * scaleY;
		TeamOffsetX = 210.0 * scaleY;
		TeamPosX[0] = 0.5 * C.ClipX - TeamOffsetX;
		TeamPosX[1] = 0.5 * C.ClipX + TeamOffsetX;

		// draw icons
		C.Style = 1;
		C.DrawColor = class'ThPlusHUD'.Default.TrueSilverColor;
		C.SetPos(TeamPosX[0] - 0.5 * IconSize, TopBarH);
		C.DrawIcon(texture'ThiefTile', IconScale);
		C.SetPos(TeamPosX[1] - 0.5 * IconSize, TopBarH);
		C.DrawIcon(texture'GuardTile', IconScale);

		// draw text
		C.Style = 3;
		C.DrawColor = WhiteColor;
		C.Font = ThHUD(tpp.myHUD).MyFontSmall;
		C.TextSize("THIEVES", TextW, TextH);
		C.SetPos(TeamPosX[0] - 0.5 * TextW, TopBarH + IconSize + Pad);
		C.DrawText("THIEVES");
		C.TextSize("GUARDS", TextW, TextH);
		C.SetPos(TeamPosX[1] - 0.5 * TextW, TopBarH + IconSize + Pad);
		C.DrawText("GUARDS");
	}
	else
	{
		TopBarH = 136.0 * scaleY;
		BottomBarH = 106.0 * scaleY;
		IconScale = 1.0 * scaleY;
		IconSize = 256.0 * scaleY;
		TeamOffsetX = 256.0 * scaleY;
		TeamPosX[0] = 0.5 * C.ClipX - TeamOffsetX;
		TeamPosX[1] = 0.5 * C.ClipX + TeamOffsetX;

		C.Style = 1;
		C.DrawColor = WhiteColor;

		// draw black bars
		C.SetPos(0.0, 0.0);
		C.DrawRect(texture'BlackTexture', C.ClipX, TopBarH);
		C.SetPos(0.0, C.ClipY - BottomBarH);
		C.DrawRect(texture'BlackTexture', C.ClipX, BottomBarH);

		// draw icons
		C.SetPos(TeamPosX[0] - 0.5 * IconSize, 0.0);
		C.DrawIcon(texture'ThiefHead', IconScale);
		C.SetPos(TeamPosX[1] - 0.5 * IconSize, 0.0);
		C.DrawIcon(texture'GuardHead', IconScale);
	}

	DrawPreGameHeaderSplash(C);
}

simulated function DrawScoreboardHeader(canvas C)
{
	local float Pad, IconScale, IconSize, TopBarH, BottomBarH, PosX;
	local float TeamOffsetX, TeamPosX[2], TextW, TextH;

	C.Reset();
	TopBarH = 60.0 * scaleY;
	BottomBarH = 32.0 * scaleY;
	TeamOffsetX = 256.0 * scaleY;
	TeamPosX[0] = 0.5 * C.ClipX - TeamOffsetX;
	TeamPosX[1] = 0.5 * C.ClipX + TeamOffsetX;

	if (class'ThPlusConfig'.Default.bUseModernTheme)
	{
		// draw transparent black bars
		C.Style = 4;
		C.SetPos(0.0, 0.0);
		C.DrawRect(texture'GreyBackground', C.ClipX, TopBarH);
		C.SetPos(0.0, C.ClipY - BottomBarH);
		C.DrawRect(texture'GreyBackground', C.ClipX, BottomBarH);

		if (!tppGRI.bThiefMatch)
		{
			C.DrawColor = WhiteColor;
			C.Font = ThHUD(tpp.myHUD).MyFontSmall;
			Pad = 12.0 * scaleY;
			IconScale = 52.0 / 256.0 * scaleY;
			IconSize = 52.0 * scaleY;

			// draw thieves icon and text
			C.Style = 1;
			C.TextSize("THIEVES", TextW, TextH);
			PosX = TeamPosX[0] - 0.5 * (IconSize + Pad + TextW);
			C.SetPos(PosX, 0.5 * TopBarH - 0.5 * IconSize);
			C.DrawIcon(texture'ThiefTile', IconScale);
			C.Style = 3;
			C.SetPos(PosX + IconSize + Pad, 0.5 * TopBarH - 0.5 * TextH);
			C.DrawText("THIEVES");

			// draw guards icon and text
			C.Style = 1;
			C.TextSize("GUARDS", TextW, TextH);
			PosX = TeamPosX[1] - 0.5 * (IconSize + Pad + TextW);
			C.SetPos(PosX, 0.5 * TopBarH - 0.5 * IconSize);
			C.DrawIcon(texture'GuardTile', IconScale);
			C.Style = 3;
			C.SetPos(PosX + IconSize + Pad, 0.5 * TopBarH - 0.5 * TextH);
			C.DrawText("GUARDS");
		}
	}
	else
	{
		C.Style = 1;
		C.DrawColor = WhiteColor;

		// draw black bars
		C.SetPos(0.0, 0.0);
		C.DrawRect(texture'BlackTexture', C.ClipX, TopBarH);
		C.SetPos(0.0, C.ClipY - BottomBarH);
		C.DrawRect(texture'BlackTexture', C.ClipX, BottomBarH);

		if (!tppGRI.bThiefMatch)
		{
			// draw icons
			IconScale = 0.4 * scaleY;
			IconSize = 256.0 * IconScale;
			C.SetPos(TeamPosX[0] - 0.5 * IconSize, 0.0);
			C.DrawIcon(texture'ThiefHead', IconScale);
			C.SetPos(TeamPosX[1] - 0.5 * IconSize, 0.0);
			C.DrawIcon(texture'GuardHead', IconScale);
		}
	}

	DrawHeaderSplash(C);
}

//=============================================================================
// logo for header

simulated function DrawPreGameHeaderSplash(canvas C)
{
	local float VersionH, UTScale, UTWidth, IconScale, IconWidth, Alpha;
	local float TextW, TextH;

	if (!class'ThPlusConfig'.Default.bUseModernTheme)
	{
		DrawHeaderSplash(C);
		return;
	}

	C.Reset();
	C.Style = 3;

	// draw version number
	C.DrawColor = class'TInfo'.static.GetColor(77, 76, 66);
	C.Font = ThHUD(tpp.myHUD).SansFontSmall;
	C.TextSize(" ", TextW, TextH);
	VersionH = 28.0 * scaleY;
	C.CurY = 0.5 * VersionH - 0.5 * TextH;
	DrawVersion(C, true);

	// draw logo
	IconScale = 0.64 * scaleY;
	C.DrawColor = WhiteColor;
	if (SplashStage < 4)
	{
		Alpha = LetterFade[0] / 128.0;
		IconScale *= class'ThPlusHUD'.static.EaseOut(2.0, 1.0, Alpha);
		C.DrawColor *= class'ThPlusHUD'.static.EaseOut(0.0, 1.0, Alpha);
	}
	IconWidth = 512.0 * IconScale;
	C.SetPos(0.5 * C.ClipX - 0.5 * IconWidth, VersionH - 20.0 * IconScale);
	C.DrawIcon(texture'SplashLogo', IconScale);

	// draw "for unreal tournament"
	UTScale = 0.5 * scaleY;
	UTWidth = 1024.0 * UTScale;
	C.DrawColor = C.Default.DrawColor;
	if (SplashStage < 4)
	{
		C.DrawColor *= SplashMutatorOffset / 196.0;
	}
	C.SetPos(0.5 * C.ClipX - 0.5 * UTWidth, VersionH + 100.0 * IconScale);
	C.DrawIcon(texture'SplashLogoUT', UTScale);
}

simulated function DrawHeaderSplash(canvas C)
{
	local int i;
	local float TopBarH, IconScale, IconWidth, IconHeight, XScale, PosY, Alpha;
	local float TextW, TextH;
	local bool bSplash;

	bSplash = (SplashStage < 4 && (tpp.GetStateName() == 'PlayerWaiting'
			   || tpp.GetStateName() == 'GameEnded' || tppGRI.bThiefMatch));
	TopBarH = 60.0 * scaleY;

	C.Reset();
	C.Style = 3;

	// draw version number
	C.DrawColor = GrayColor;
	C.Font = ScoreFontSmall;
	C.TextSize(" ", TextW, TextH);
	C.CurY = TopBarH - 8.0 * scaleY - 0.5 * TextH;
	DrawVersion(C);

	// draw logo
	PosY = FMin(0.0, 4.0 * scaleY - 0.5 * TextH);
	if (class'ThPlusConfig'.Default.bUseModernTheme)
	{
		IconScale = 0.35 * scaleY;
		C.DrawColor = WhiteColor;
		if (bSplash)
		{
			Alpha = LetterFade[0] / 128.0;
			IconScale *= class'ThPlusHUD'.static.EaseOut(2.0, 1.0, Alpha);
			C.DrawColor *= class'ThPlusHUD'.static.EaseOut(0.0, 1.0, Alpha);
		}
		IconWidth = 512.0 * IconScale;
		IconHeight = 128.0 * IconScale;
		C.SetPos(0.5 * C.ClipX - 0.5 * IconWidth, PosY + 0.5 * TopBarH - 0.5 * IconHeight);
		C.DrawIcon(texture'SplashLogo', IconScale);
	}
	else
	{
		if (bSplash)
		{
			for (i = 0; i < NumLetters; i++)
			{
				Alpha = FMin(1.0, LetterFade[i] / 89.0);
				XScale = (1.0 + 0.67 * (1.0 - Alpha)) * scaleY;
				IconScale = (1.0 + 2.225 * (1.0 - Alpha)) * scaleY;
				C.DrawColor = C.Default.DrawColor * Alpha;
				C.CurX = 0.5 * C.ClipX + (LetterX[i] - 90.0) * XScale - 32.0 * IconScale;
				C.CurY = PosY + LetterOffset[i] * IconScale + 32.0 * (scaleY - IconScale);
				C.DrawIcon(SplashLetterTex[i], IconScale);
			}
		}
		else
		{
			C.DrawColor = C.Default.DrawColor;
			for (i = 0; i < NumLetters; i++)
			{
				C.CurX = 0.5 * C.ClipX + (LetterX[i] - 122.0) * scaleY;
				C.CurY = PosY + LetterOffset[i] * scaleY;
				C.DrawIcon(SplashLetterTex[i], scaleY);
			}
		}
	}
}

simulated function DrawVersion(canvas C, optional bool bFadeOnly)
{
	local float TextW, TextH;
	local string Text;
	local bool bSplash;

	bSplash = (SplashStage < 4 && (tpp.GetStateName() == 'PlayerWaiting'
			   || tpp.GetStateName() == 'GameEnded' || tppGRI.bThiefMatch));

	Text = class'ThieveryDeathMatchPlus'.Default.VersionString;
	C.TextSize(Text, TextW, TextH);
	C.CurX = 0.5 * C.ClipX - 0.5 * TextW;
	if (bSplash)
	{
		if (SplashStage == 3 && !bFadeOnly)
		{
			C.CurX += (0.5 * SplashMutatorOffset - 98.0) * scaleY;
		}
		if (SplashStage == 3 || bFadeOnly)
		{
			C.DrawColor *= SplashMutatorOffset / 196.0;
			C.DrawText(Text);
		}
		return;
	}
	C.DrawText(Text);
}

//=============================================================================
// trailer

function DrawScoreboardTrailer(canvas C)
{
	local int Hours, Minutes, Seconds;
	local float PosX, PosY, TextW, TextH, BottomBarH, TrailerHeight;
	local string Time, Label, Text;
	local ThProGRI ProGRI;

	C.Reset();
	C.Style = 3;

	// draw level title
	C.DrawColor = GrayColor;
	C.Font = ThHUD(tpp.myHUD).SansFontSmall;
	C.TextSize(Level.Title, TextW, TextH);
	C.SetPos(0.5 * C.ClipX - 0.5 * TextW, C.ClipY - 48.0 * scaleY - 0.5 * TextH);
	C.DrawText(Level.Title);

	// draw wave time, remaining time, or elapsed time
	BottomBarH = 32.0 * scaleY;
	PosX = 0.5 * C.ClipX;
	PosY = C.ClipY - 0.5 * BottomBarH - 0.5 * TextH;
	if (bTimeDown || tppGRI.RemainingTime > 0)
	{
		bTimeDown = true;
		ProGRI = ThProGRI(tppGRI);
		if (ProGRI != None && ProGRI.usingWaves
			&& ProGRI.wave < ProGRI.totalWaves && ProGRI.nextWaveTime > 0)
		{
			Label = "Next Wave: ";
			Minutes = (tppGRI.RemainingTime - ProGRI.nextWaveTime) / 60;
			Seconds = (tppGRI.RemainingTime - ProGRI.nextWaveTime) % 60;
			Time = TwoDigitString(Minutes)$":"$TwoDigitString(Seconds);
		}
		else
		{
			Label = RemainingTime;
			Time = "00:00";
			if (tppGRI.RemainingTime > 0)
			{
				Minutes = tppGRI.RemainingTime / 60;
				Seconds = tppGRI.RemainingTime % 60;
				Time = TwoDigitString(Minutes)$":"$TwoDigitString(Seconds);
			}
		}
	}
	else
	{
		Label = ElapsedTime;
		Seconds = tppGRI.ElapsedTime;
		Minutes = Seconds / 60;
		Hours   = Minutes / 60;
		Seconds = Seconds - (Minutes * 60);
		Minutes = Minutes - (Hours * 60);
		Time = TwoDigitString(Hours)$":"$TwoDigitString(Minutes)$":"$TwoDigitString(Seconds);
	}
	ThHUD(tpp.myHUD).DrawLabelAndValue(C, PosX, PosY, Label, Time, true);

	// draw match ended or restart text
	if (tppGRI.GameEndedComments != "")
	{
		Text = Ended;
		if (Level.NetMode == NM_Standalone)
		{
			Text = Text@Continue;
		}
	}
	else if (tpp.Health <= 0)
	{
		Text = Restart;
	}

	if (Text != "")
	{
		C.DrawColor = GreenColor;
		C.Font = ThHUD(tpp.myHUD).SansFontMedium;
		C.TextSize(Text, TextW, TextH);
		TrailerHeight = 112.0 * scaleY;
		C.SetPos(PosX - 0.5 * TextW, C.ClipY - TrailerHeight);
		C.DrawText(Text);
	}
}

//=============================================================================
// pre-game scoreboard

simulated function DrawPreGameScoreboard(canvas C)
{
	local byte Team;
	local int i, TeamRow[2];
	local float Pad, IconSize, TextW, TextH, PosY, LineH, TopBarH;
	local float TeamOffsetX, TeamPosX[2], TrailerHeight;

	if (class'ThPlusConfig'.Default.bUseModernTheme)
	{
		C.Reset();
		C.DrawRect(texture'BlackTexture', C.ClipX, C.ClipY);
		DrawBackground(C);
	}

	C.Reset();
	C.Font = ScoreFontMedium;
	C.TextSize(" ", TextW, TextH);
	if (class'ThPlusConfig'.Default.bUseModernTheme)
	{
		Pad = 12.0 * scaleY;
		TopBarH = 128.0 * scaleY;
		IconSize = 128.0 * scaleY;
		ScoreStart = TopBarH + IconSize + Pad + TextH + Pad;
	}
	else
	{
		Pad = 2.0 * scaleY;
		TopBarH = 136.0 * scaleY;
		ScoreStart = TopBarH + TextH + Pad;
	}

	// draw player names and pings
	TeamOffsetX = 210.0 * scaleY;
	TeamPosX[0] = 0.5 * C.ClipX - 80.0 * scaleY - TeamOffsetX;
	TeamPosX[1] = 0.5 * C.ClipX - 80.0 * scaleY + TeamOffsetX;
	TrailerHeight = 112.0 * scaleY;
	LineH = GetLineHeight(C, TextH, 1.5 * TextH);
	for (i = 0; i < PlayerCount; i++)
	{
		Team = Ordered[i].Team;
		PosY = ScoreStart + TeamRow[Team] * LineH;
		if (PosY + LineH < C.ClipY - TrailerHeight)
		{
			DrawPreGamePlayerNameAndPing(C, Ordered[i], TeamPosX[Team], PosY);
			TeamRow[Team]++;
		}
	}

	DrawPreGameScoreboardHeader(C);
	DrawCountdown(C);
	DrawScoreboardTrailer(C);
	DrawSpectatorNames(C);
}

simulated function DrawPreGamePlayerNameAndPing(canvas C, PlayerReplicationInfo PRI,
												float PosX, float PosY)
{
	local float Pad, TextW, TextH;
	local string Text;

	C.Reset();
	C.Style = 3;

	// draw name
	C.DrawColor = GetPlayerNameColor(PRI);
	C.Font = ScoreFontMedium;
	Text = PRI.PlayerName;
	if (PRI.bIsABot || PRI.IsA('BotReplicationInfo'))
	{
		Text = "(AI) "$Text;
	}
	Text = class'ThPlusHUD'.static.TrimText(C, Text, 272.0 * scaleY);
	C.SetPos(PosX, PosY);
	C.DrawText(Text);

	// draw ping
	if (C.ClipX > 512.0 && Level.NetMode != NM_Standalone)
	{
		C.TextSize(" ", TextW, TextH);
		PosY += 0.5 * TextH;
		Pad = 12.0 * scaleY;
		C.DrawColor = C.Default.DrawColor;
		C.Font = ScoreFontSmall;

		C.TextSize(PingString$": 999", TextW, TextH);
		C.SetPos(PosX - Pad - TextW, PosY - 0.5 * TextH);
		C.DrawText(PingString$":");

		Text = string(Min(999, PRI.Ping));
		C.TextSize(Text, TextW, TextH);
		C.SetPos(PosX - Pad - TextW, PosY - 0.5 * TextH);
		C.DrawText(Text);
	}
}

simulated function DrawCountdown(canvas C)
{
	local int TSeconds;
	local float TextW, TextH, PosY;
	local string Text;

	if (tpp.ProgressTimeOut > Level.TimeSeconds)
	{
		if (Level.NetMode == NM_ListenServer)
		{
			TSeconds = ThieveryDeathmatchPlus(Level.Game).ThieveryCountDown;
		}
		else
		{
			TSeconds = int(tpp.ProgressTimeOut - Level.TimeSeconds);
		}

		if (TSeconds <= 30)
		{
			if (class'ThPlusConfig'.Default.bUseModernTheme)
			{
				PosY = 200.0 * scaleY;
			}
			else
			{
				PosY = 106.0 * scaleY;
			}
			C.Reset();
			C.Style = 3;
			C.DrawColor = WhiteColor;
			C.Font = ThHUD(tpp.myHUD).MyFontSmall;
			Text = "Game Start: "$TSeconds;
			C.TextSize(Text, TextW, TextH);
			C.SetPos(0.5 * C.ClipX - 0.5 * TextW, PosY - 0.5 * TextH);
			C.DrawText(Text);
		}
	}
}

//=============================================================================
// main scoreboard

simulated function DrawMainScoreboard(canvas C)
{
	local byte Team;
	local int i, TeamRow[2];
	local float TeamPosX[2], PosY, TextW, SmallTextH, MediumTextH, LineH, TrailerHeight;
	local bool bIsRoomForLocation;

	CScoreOffset = 1024.0 * 0.3 * scaleY;
	ScoreOffset = 1024.0 * 0.4 * scaleY;

	C.Reset();
	C.Style = 3;

	// draw column names
	C.Font = ThHUD(tpp.myHUD).SansFontMedium;
	C.TextSize(" ", TextW, MediumTextH);
	ScoreStart = 64.0 * scaleY + MediumTextH;
	PosY = ScoreStart - MediumTextH;
	TeamPosX[0] = 0.5 * C.ClipX + 1024.0 / 14.0 * scaleY - 512.0 * scaleY;
	TeamPosX[1] = 0.5 * C.ClipX + 1024.0 / 14.0 * scaleY;
	DrawColumnNames(C, TeamPosX, PosY);

	// draw player names and scores
	C.Font = ScoreFontSmall;
	C.TextSize(" ", TextW, SmallTextH);
	TrailerHeight = 112.0 * scaleY;
	LineH = GetLineHeight(C, Max(2.0 * SmallTextH, MediumTextH), 2.0 * MediumTextH);
	bIsRoomForLocation = (LineH >= SmallTextH + MediumTextH);
	for (i = 0; i < PlayerCount; i++)
	{
		Team = Ordered[i].Team;
		PosY = ScoreStart + TeamRow[Team] * LineH;
		if (PosY + LineH < C.ClipY - TrailerHeight)
		{
			DrawPlayerName(C, ThieveryPlayerReplicationInfo(Ordered[i]), TeamPosX[Team], PosY);
			DrawPlayerScore(C, ThieveryPlayerReplicationInfo(Ordered[i]), TeamPosX[Team], PosY);
			DrawTimeAndPing(C, Ordered[i], TeamPosX[Team], PosY);
			if (bIsRoomForLocation)
			{
				DrawLocation(C, Ordered[i], TeamPosX[Team], PosY + MediumTextH);
			}
			TeamRow[Team]++;
		}
	}

	DrawScoreboardHeader(C);
	DrawScoreboardTrailer(C);
	DrawSpectatorNames(C);
}

simulated function DrawColumnNames(canvas C, float TeamPosX[2], float PosY)
{
	local float TextW, TextH;
	local ThProGRI ProGRI;

	C.DrawColor = GetTeamColor(0);

	if (tppGRI.bThiefMatch)
	{
		C.TextSize("Lives", TextW, TextH);
		C.SetPos(TeamPosX[0] + CScoreOffset - TextW, PosY);
		C.DrawText("Lives");

		C.TextSize("Kills", TextW, TextH);
		C.SetPos(TeamPosX[0] + ScoreOffset - TextW, PosY);
		C.DrawText("Kills");

		C.DrawColor = GetTeamColor(1);

		C.SetPos(TeamPosX[1] + ScoreOffset - TextW, PosY);
		C.DrawText("Kills");
	}
	else
	{
		if (tppPRI.Team == 0 || tppPRI.Team == 255)
		{
			ProGRI = ThProGRI(tppGRI);
			if (ProGRI != None && ProGRI.usingWaves)
			{
				C.TextSize("Lives", TextW, TextH);
				C.SetPos(TeamPosX[0] + CScoreOffset - TextW, PosY);
				C.DrawText("Lives");
			}
			else
			{
				C.TextSize("Score", TextW, TextH);
				C.SetPos(TeamPosX[0] + CScoreOffset - TextW, PosY);
				C.DrawText("Score");
			}

			C.TextSize("Loot", TextW, TextH);
			C.SetPos(TeamPosX[0] + ScoreOffset - TextW, PosY);
			C.DrawText("Loot");
		}

		C.DrawColor = GetTeamColor(1);

		if (tppPRI.Team == 1 || tppPRI.Team == 255)
		{
			C.TextSize("Score", TextW, TextH);
			C.SetPos(TeamPosX[1] + CScoreOffset - TextW, PosY);
			C.DrawText("Score");
		}

		C.TextSize("Kills", TextW, TextH);
		C.SetPos(TeamPosX[1] + ScoreOffset - TextW, PosY);
		C.DrawText("Kills");
	}
}

simulated function DrawPlayerName(canvas C, ThieveryPlayerReplicationInfo PRI, float PosX, float PosY)
{
	local float TextW, TextH, TrimWidth;
	local string Text;

	C.Reset();
	C.Style = 3;
	C.DrawColor = GetPlayerNameColor(PRI);
	C.Font = ThHUD(tpp.myHUD).SansFontMedium;
	Text = PRI.PlayerName;
	TrimWidth = 240.0 * scaleY;
	if (PRI.bIsABot || PRI.IsA('BotReplicationInfo'))
	{
		Text = class'ThPlusHUD'.static.TrimText(C, "(AI) "$Text, TrimWidth);
	}
	else if (PRI.bHasSupplyChest && PRI.Team == tppPRI.Team)
	{
		// make "chest" always visible
		C.TextSize(" (Chest)", TextW, TextH);
		Text = class'ThPlusHUD'.static.TrimText(C, Text, TrimWidth - TextW);
		Text = Text$" (Chest)";
	}
	else
	{
		Text = class'ThPlusHUD'.static.TrimText(C, Text, TrimWidth);
	}
	C.SetPos(PosX, PosY);
	C.DrawText(Text);
}

simulated function DrawPlayerScore(canvas C, ThieveryPlayerReplicationInfo PRI, float PosX, float PosY)
{
	local int WaveLives;
	local ThProGRI ProGRI;

	ProGRI = ThProGRI(tppGRI);

	C.Reset();
	C.Style = 3;
	C.DrawColor = GetColorByPlayerNameOnly(PRI.PlayerName);
	C.Font = ThHUD(tpp.myHUD).SansFontMedium;

	if (tppGRI.bThiefMatch)
	{
		if (PRI.Team == 0)
		{
			if (ProGRI != None && ProGRI.usingWaves)
			{
				WaveLives = (ProGRI.totalWaves - ProGRI.wave) * ProGRI.livesPerWave;
				DrawWaveLives(C, PRI.PlayerLives, WaveLives, PosX + CScoreOffset, PosY);
			}
			else
			{
				DrawAScore(C, PRI.PlayerLives, PosX + CScoreOffset, PosY);
			}
		}

		if (PRI.Team < 2)
		{
			DrawAScore(C, PRI.ThiefKills, PosX + ScoreOffset, PosY);
		}
	}
	else
	{
		if (PRI.Team == 0)
		{
			if (tppPRI.Team == 0 || tppPRI.Team == 255)
			{
				if (ProGRI != None && ProGRI.usingWaves)
				{
					WaveLives = (ProGRI.totalWaves - ProGRI.wave) * ProGRI.livesPerWave;
					DrawWaveLives(C, PRI.PlayerLives, WaveLives, PosX + CScoreOffset, PosY);
				}
				else
				{
					DrawAScore(C, PRI.Score, PosX + CScoreOffset, PosY);
				}
				DrawAScore(C, PRI.Loot, PosX + ScoreOffset, PosY);
			}
		}
		else if (PRI.Team == 1)
		{
			if (tppPRI.Team == 1 || tppPRI.Team == 255)
			{
				DrawAScore(C, PRI.Score, PosX + CScoreOffset, PosY);
			}
			DrawAScore(C, PRI.ThiefKills, PosX + ScoreOffset, PosY);
		}
	}
}

simulated function DrawAScore(canvas C, float Score, float PosX, float PosY)
{
	local float TextW, TextH;
	local string Text;

	if (Score >= 0)
	{
		Text = string(int(Score));
		C.TextSize(Text, TextW, TextH);
		C.SetPos(PosX - TextW, PosY);
		C.DrawText(Text);
	}
}

simulated function DrawWaveLives(canvas C, int Lives, int WaveLives, float PosX, float PosY)
{
	local float TextW, TextH;
	local string Text;

	Text = string(Lives);
	if (WaveLives > 0)
	{
		Text = Text$" ("$WaveLives$")";
	}
	C.TextSize(Text, TextW, TextH);
	C.SetPos(PosX - TextW, PosY);
	C.DrawText(Text);
}

simulated function DrawTimeAndPing(canvas C, PlayerReplicationInfo PRI, float PosX, float PosY)
{
	local float T, Pad, TextW, TextH, SmallTextH, MediumTextH;
	local float TimeW, PingW, SmallTextPosX, SmallTextPosY;
	local string Text;

	if (Level.NetMode == NM_Standalone || C.ClipX < 512.0)
	{
		return;
	}

	C.Reset();
	C.Style = 3;
	Pad = 12.0 * scaleY;
	C.Font = ThHUD(tpp.myHUD).SansFontMedium;
	C.TextSize(" ", TextW, MediumTextH);
	C.Font = ScoreFontSmall;
	C.TextSize(" ", TextW, SmallTextH);
	if (C.ClipX > 900.0)
	{
		C.TextSize(TimeString$": 999", TimeW, TextH);
		C.TextSize(PingString$": 999", PingW, TextH);
		SmallTextPosX = PosX - Pad - FMax(TimeW, PingW);

		C.DrawColor = GrayColor;
		C.SetPos(SmallTextPosX, PosY);
		C.DrawText(TimeString$":");

		T = (Level.TimeSeconds + tppPRI.StartTime - PRI.StartTime) / 60.0;
		Text = string(Clamp(T, 1, 999));
		C.TextSize(Text, TextW, TextH);
		C.SetPos(PosX - Pad - TextW, PosY);
		C.DrawText(Text);

		SmallTextPosY = PosY + SmallTextH;
		C.DrawColor = C.Default.DrawColor;
		C.SetPos(SmallTextPosX, SmallTextPosY);
		C.DrawText(PingString$":");
	}
	else
	{
		SmallTextPosY = PosY + 0.5 * MediumTextH - 0.5 * SmallTextH;
		C.DrawColor = C.Default.DrawColor;
	}
	Text = string(Min(999, PRI.Ping));
	C.TextSize(Text, TextW, TextH);
	C.SetPos(PosX - Pad - TextW, SmallTextPosY);
	C.DrawText(Text);
}

simulated function DrawLocation(canvas C, PlayerReplicationInfo PRI, float PosX, float PosY)
{
	local string Text;

	if (tppPRI.Team != PRI.Team || tppGRI.bThiefMatch || C.ClipX < 512.0)
	{
		return;
	}

	if (PRI.PlayerLocation != None)
	{
		Text = PRI.PlayerLocation.LocationName;
	}
	else if (PRI.PlayerZone != None)
	{
		Text = PRI.PlayerZone.ZoneName;
	}

	if (Text != "")
	{
		C.Reset();
		C.Style = 3;
		C.DrawColor = GrayColor;
		C.Font = ScoreFontSmall;
		C.SetPos(PosX, PosY);
		C.DrawText(InString@Text);
	}
}

//=============================================================================
// post-game scoreboard

simulated function DrawPostGameScoreboard(canvas C)
{
	local byte Team;
	local int i, TeamRow[2];
	local float Pad, TopBarH, TextW, MediumTextH, MediumRowH, SectionRowH;
	local float PosY, AwardPosY, ResultPosY, ThiefMatchPosX, TeamPosX[2];
	local float PadA, PadB, NameW, ScoreW, StatW, ThiefMatchW, ThievesW;
	local float LineH, TrailerHeight;
	local texture Tex;
	local ThieveryPlayerReplicationInfo OrderedPRI;

	// draw background
	if (class'ThPlusConfig'.Default.bUseModernTheme)
	{
		DrawBackground(C);
	}
	else
	{
		C.Reset();
		C.DrawColor = class'TInfo'.static.GetColor(8, 8, 7);
		C.DrawRect(texture'WhiteTexture', C.ClipX, C.ClipY);
	}

	C.Reset();
	Pad = 8.0 * scaleY;
	TopBarH = 60.0 * scaleY;
	C.Font = ScoreFontMedium;
	C.TextSize(" ", TextW, MediumTextH);
	MediumRowH = 1.4 * MediumTextH;
	SectionRowH = 1.6 * MediumTextH;

	// draw section title backgrounds
	if (class'ThPlusConfig'.Default.bUseModernTheme)
	{
		C.Style = 4;
		Tex = texture'LightGrey';
	}
	else
	{
		C.DrawColor = class'TInfo'.static.GetColor(6, 6, 5);
		Tex = texture'WhiteTexture';
	}
	C.SetPos(0.0, TopBarH);
	C.DrawRect(Tex, C.ClipX, SectionRowH);
	if (!tppGRI.bThiefMatch)
	{
		C.SetPos(0.0, TopBarH + SectionRowH + Pad + 4.0 * MediumRowH + Pad);
		C.DrawRect(Tex, C.ClipX, SectionRowH);
	}

	C.Reset();
	C.Style = 3;
	C.DrawColor = WhiteColor;
	C.Font = ScoreFontMedium;
	if (tppGRI.bThiefMatch)
	{
		// draw section title name
		C.TextSize("Results", TextW, MediumTextH);
		PosY = TopBarH + 0.5 * SectionRowH - 0.5 * MediumTextH;
		C.SetPos(0.5 * C.ClipX - 0.5 * TextW, PosY);
		C.DrawText("Results");

		ResultPosY = TopBarH + SectionRowH + Pad;
	}
	else
	{
		// draw section title names
		C.TextSize("Awards", TextW, MediumTextH);
		PosY = TopBarH + 0.5 * SectionRowH - 0.5 * MediumTextH;
		C.SetPos(0.5 * C.ClipX - 0.5 * TextW, PosY);
		C.DrawText("Awards");
		C.TextSize("Results", TextW, MediumTextH);
		PosY += SectionRowH + Pad + 4.0 * MediumRowH + Pad;
		C.SetPos(0.5 * C.ClipX - 0.5 * TextW, PosY);
		C.DrawText("Results");

		// draw awards
		AwardPosY = TopBarH + SectionRowH + Pad;
		PosY = AwardPosY + 0.5 * MediumRowH - 0.5 * MediumTextH;
		GenerateAwards(C);
		DrawAwards(C, MediumRowH, PosY);

		ResultPosY = AwardPosY + 4.0 * MediumRowH + Pad + SectionRowH + Pad;
	}

	// calculate column widths and positions
	if (C.ClipX > 512.0)
	{
		if (tppGRI.bThiefMatch)
		{
			NameW = 240.0 * scaleY;
			ScoreW = 96.0 * scaleY;
			StatW = 80.0 * scaleY;
			ThiefMatchW = NameW + ScoreW + 6.0 * StatW;
			ThiefMatchPosX = 0.5 * C.ClipX - 0.5 * ThiefMatchW;
		}
		else
		{
			NameW = 160.0 * scaleY;
			ScoreW = 64.0 * scaleY;
			StatW = 50.0 * scaleY;
			PadA = 16.0 * scaleY;
			PadB = 44.0 * scaleY;
			ThievesW = PadA + NameW + ScoreW + 6.0 * StatW + PadB;
			TeamPosX[0] = 0.5 * C.ClipX - 512.0 * scaleY + PadA;
			TeamPosX[1] = 0.5 * C.ClipX - 512.0 * scaleY + ThievesW;
		}
	}
	else
	{
		NameW = 320.0 * scaleY;
		ScoreW = 128.0 * scaleY;
		PadA = 32.0 * scaleY;
		ThiefMatchW = NameW + ScoreW;
		ThiefMatchPosX = 0.5 * C.ClipX - 0.5 * ThiefMatchW;
		TeamPosX[0] = 0.5 * C.ClipX - 512.0 * scaleY + PadA;
		TeamPosX[1] = 0.5 * C.ClipX + PadA;
	}

	// draw column names
	PosY = ResultPosY + 0.5 * MediumRowH - 0.5 * MediumTextH;
	if (tppGRI.bThiefMatch)
	{
		if (C.ClipX < 1024.0)
		{
			DrawPostGameColumnNames(C, 0, NameW, ScoreW, StatW, LowResThiefMatchName, ThiefMatchPosX, PosY);
		}
		else
		{
			DrawPostGameColumnNames(C, 0, NameW, ScoreW, StatW, ThiefMatchStatName, ThiefMatchPosX, PosY);
		}
	}
	else
	{
		if (C.ClipX < 1024.0)
		{
			DrawPostGameColumnNames(C, 0, NameW, ScoreW, StatW, LowResThiefName, TeamPosX[0], PosY);
			DrawPostGameColumnNames(C, 1, NameW, ScoreW, StatW, LowResGuardName, TeamPosX[1], PosY);
		}
		else
		{
			DrawPostGameColumnNames(C, 0, NameW, ScoreW, StatW, ThiefStatName, TeamPosX[0], PosY);
			DrawPostGameColumnNames(C, 1, NameW, ScoreW, StatW, GuardStatName, TeamPosX[1], PosY);
		}
	}

	// draw player names and stats
	ScoreStart = ResultPosY + MediumRowH;
	TrailerHeight = 112.0 * scaleY;
	LineH = GetLineHeight(C, MediumTextH, 1.4 * MediumTextH);
	for (i = 0; i < PlayerCount; i++)
	{
		if (!Ordered[i].bIsABot)
		{
			if (tppGRI.bThiefMatch)
			{
				if (Ordered[i].Team == 0)
				{
					PosY = ScoreStart + TeamRow[0] * LineH + (0.5 * LineH - 0.5 * MediumTextH);
					if (PosY + LineH < C.ClipY - TrailerHeight)
					{
						OrderedPRI = ThieveryPlayerReplicationInfo(Ordered[i]);
						DrawPostGameStats(C, NameW, ScoreW, StatW, OrderedPRI, ThiefMatchPosX, PosY);
						TeamRow[0]++;
					}
				}
			}
			else
			{
				Team = Ordered[i].Team;
				PosY = ScoreStart + TeamRow[Team] * LineH + (0.5 * LineH - 0.5 * MediumTextH);
				if (PosY + LineH < C.ClipY - TrailerHeight)
				{
					OrderedPRI = ThieveryPlayerReplicationInfo(Ordered[i]);
					DrawPostGameStats(C, NameW, ScoreW, StatW, OrderedPRI, TeamPosX[Team], PosY);
					TeamRow[Team]++;
				}
			}
		}
	}

	ResetSplashOnce();
	DrawScoreboardHeader(C);
	DrawScoreboardTrailer(C);
	DrawSpectatorNames(C);
	DrawNextMapName(C);
}

simulated function GenerateAwards(canvas C)
{
	local int i, j, Pos;
	local ThieveryPlayerStatisticsReplicated Stats;
	local string Award, AllAwards;

	if (bGeneratedAwards)
	{
		return;
	}
	bGeneratedAwards = true;

	for (i = 0; i < 8; i++)
	{
		AwardedPlayerName[i] = "";
	}

	for (i = 0; i < PlayerCount; i++)
	{
		if (Ordered[i].bIsABot)
		{
			continue;
		}
		Stats = tppGRI.GetStatsFor(Ordered[i].PlayerID);
		if (Stats == None)
		{
			continue;
		}
		AllAwards = Stats.AwardString$Stats.AwardString2$Stats.AwardString3;
		if (AllAwards == "")
		{
			continue;
		}

		AllAwards = AllAwards$", ";
		Pos = InStr(AllAwards, ", ");
		while (Pos != -1)
		{
			Award = Left(AllAwards, Pos);
			for (j = 0; j < 8; j++)
			{
				if (Award == AwardName[j])
				{
					AwardedPlayerName[j] = class'ThPlusHUD'.static.TrimText(C, Ordered[i].PlayerName, 240.0 * scaleY);
					break;
				}
			}
			AllAwards = Mid(AllAwards, Pos + 2);
			Pos = InStr(AllAwards, ", ");
		}
	}
}

simulated function DrawAwards(canvas C, float MediumRowH, float PosY)
{
	local int i, j, k;
	local float AwardNameW, AwardedPlayerNameW, ColW[4], MinColW, PosX[4], TextH, Pad;

	C.Reset();
	C.Style = 3;
	C.Font = ScoreFontMedium;

	// calculate column widths and positions
	for (i = 0; i < 8; i++)
	{
		C.TextSize(AwardName[i]$":", AwardNameW, TextH);
		C.TextSize(AwardedPlayerName[i], AwardedPlayerNameW, TextH);
		if (i < 4)
		{
			ColW[0] = FMax(ColW[0], AwardNameW);
			ColW[1] = FMax(ColW[1], AwardedPlayerNameW);
		}
		else
		{
			ColW[2] = FMax(ColW[2], AwardNameW);
			ColW[3] = FMax(ColW[3], AwardedPlayerNameW);
		}
		MinColW = FMax(MinColW, AwardNameW);
	}
	Pad = 16.0 * scaleY;
	ColW[0] += Pad;
	ColW[1] = FMax(ColW[1], MinColW) + 2.0 * Pad;
	ColW[2] += Pad;
	ColW[3] = FMax(ColW[3], MinColW);
	PosX[0] = 0.5 * C.ClipX - 0.5 * (ColW[0] + ColW[1] + ColW[2] + ColW[3]);
	PosX[1] = PosX[0] + ColW[0];
	PosX[2] = PosX[1] + ColW[1];
	PosX[3] = PosX[2] + ColW[2];

	// draw awards
	for (i = 0; i < 2; i++)
	{
		for (j = 0; j < 4; j++)
		{
			C.DrawColor = class'ThPlusHUD'.Default.TrueSilverColor;
			C.SetPos(PosX[2 * i], PosY + MediumRowH * j);
			C.DrawText(AwardName[k]$":");

			C.DrawColor = GetColorByPlayerNameOnly(AwardedPlayerName[i]);
			C.SetPos(PosX[2 * i + 1], PosY + MediumRowH * j);
			C.DrawText(AwardedPlayerName[k]);

			k++;
		}
	}
}

simulated function DrawPostGameColumnNames(canvas C, byte Team, float NameW, float ScoreW, float StatW,
										   string ColumnName[16], float PosX, float PosY)
{
	local int i, Pos;
	local float TextW, TextH;
	local string Text;

	C.Reset();
	C.Style = 3;
	C.DrawColor = GetTeamColor(Team);
	C.Font = ScoreFontMedium;

	// draw name
	C.SetPos(PosX, PosY);
	C.DrawText("Name");

	// draw score
	PosX += NameW + ScoreW;
	C.TextSize("Score", TextW, TextH);
	C.SetPos(PosX - TextW, PosY);
	C.DrawText("Score");

	// draw stats
	if (C.ClipX > 512.0)
	{
		PosY += 0.5 * TextH;
		C.DrawColor *= 0.75;
		C.Font = ScoreFontSmall;
		for (i = 0; i < 6; i++)
		{
			if (ColumnName[i] != "")
			{
				PosX += StatW;
				Pos = InStr(ColumnName[i], " ");
				if (Pos == -1)
				{
					// draw text
					C.TextSize(ColumnName[i], TextW, TextH);
					C.SetPos(PosX - TextW, PosY - 0.5 * TextH);
					C.DrawText(ColumnName[i]);
				}
				else
				{
					// draw text before space
					Text = Left(ColumnName[i], Pos);
					C.TextSize(Text, TextW, TextH);
					C.SetPos(PosX - TextW, PosY - TextH);
					C.DrawText(Text);

					// draw text after space on new line
					Text = Mid(ColumnName[i], Pos + 1);
					C.TextSize(Text, TextW, TextH);
					C.SetPos(PosX - TextW, PosY);
					C.DrawText(Text);
				}
			}
		}
	}
}

simulated function DrawPostGameStats(canvas C, float NameW, float ScoreW, float StatW,
									 ThieveryPlayerReplicationInfo PRI, float PosX, float PosY)
{
	local int i;
	local float TextW, TextH;
	local string Text, Stat[6];
	local ThieveryPlayerStatisticsReplicated Stats;

	Stats = tppGRI.GetStatsFor(PRI.PlayerID);
	if (Stats == None)
	{
		return;
	}

	C.Reset();
	C.Style = 3;
	C.DrawColor = GetPlayerNameColor(PRI);
	C.Font = ScoreFontMedium;

	// draw ready indicator
	if (PRI.bReadyToStartNextMap)
	{
		C.TextSize("*", TextW, TextH);
		C.SetPos(PosX - 6.0 * scaleY - 0.5 * TextW, PosY + 2.0 * scaleY);
		C.DrawText("*");
	}

	// draw name
	Text = class'ThPlusHUD'.static.TrimText(C, PRI.PlayerName, NameW);
	C.SetPos(PosX, PosY);
	C.DrawText(Text);

	// draw score
	PosX += NameW + ScoreW;
	Text = string(int(PRI.Score));
	C.TextSize(Text, TextW, TextH);
	C.SetPos(PosX - TextW, PosY);
	C.DrawText(Text);

	if (C.ClipX > 512.0)
	{
		// select stats
		if (tppGRI.bThiefMatch)
		{
			Stat[0] = string(Stats.ObjectivePoints);
			Stat[1] = string(Stats.Loot);
			Stat[2] = string(Stats.DamageDealt);
			Stat[3] = string(Stats.GuardKills);
			Stat[4] = string(Stats.GuardKOs);
			Stat[5] = string(Stats.ThiefKills);
		}
		else
		{
			if (PRI.Team == 0)
			{
				Stat[0] = string(Stats.ObjectivePoints);
				Stat[1] = string(Stats.Loot);
				Stat[2] = string(Stats.Stealth);
				Stat[3] = string(Stats.GuardKills);
				Stat[4] = string(Stats.GuardKOs);
				Stat[5] = string(Stats.ThiefKills);
			}
			else if (PRI.Team == 1)
			{
				Stat[0] = string(Stats.Loot);
				Stat[1] = string(-Stats.LightsExtinguished);
				Stat[2] = string(Stats.ThiefKills);
				Stat[3] = string(Stats.DamageDealt);
			}
		}

		// draw stats
		C.DrawColor *= 0.75;
		C.TextSize(" ", TextW, TextH);
		PosY += 0.5 * TextH;
		C.Font = ScoreFontSmall;
		C.TextSize(" ", TextW, TextH);
		PosY -= 0.5 * TextH;
		for (i = 0; i < 6; i++)
		{
			PosX += StatW;
			if (Stat[i] != "")
			{
				C.TextSize(Stat[i], TextW, TextH);
				C.SetPos(PosX - TextW, PosY);
				C.DrawText(Stat[i]);
			}
		}
	}
}

//=============================================================================

defaultproperties
{
	ModernTeamColor(0)=(R=168,G=16,B=45)
	ModernTeamColor(1)=(R=16,G=96,B=168)
	SplashLetterTex(0)=texture'SplashT'
	SplashLetterTex(1)=texture'SplashH'
	SplashLetterTex(2)=texture'SplashI'
	SplashLetterTex(3)=texture'SplashE'
	SplashLetterTex(4)=texture'SplashV'
	SplashLetterTex(5)=texture'SplashE'
	SplashLetterTex(6)=texture'SplashR'
	SplashLetterTex(7)=texture'SplashY'
	AwardName(0)="ShadowLurker"
	AwardName(1)="Blackjack Happy"
	AwardName(2)="Guard Bait"
	AwardName(3)="Bloodlust"
	AwardName(4)="Fat Cat"
	AwardName(5)="Sharpshooter"
	AwardName(6)="ThiefsBane"
	AwardName(7)="GuardsBane"
	ThiefStatName(0)="Obj. Points"
	ThiefStatName(1)="Loot"
	ThiefStatName(2)="Stealth"
	ThiefStatName(3)="Guard Kills"
	ThiefStatName(4)="Guard KOs"
	ThiefStatName(5)="Thief Kills"
	GuardStatName(0)="Loot Ret."
	GuardStatName(1)="Torches Relit"
	GuardStatName(2)="Thief Kills"
	GuardStatName(3)="Damage Dealt"
	ThiefMatchStatName(0)="Obj. Points"
	ThiefMatchStatName(1)="Loot"
	ThiefMatchStatName(2)="Damage Dealt"
	ThiefMatchStatName(3)="Guard Kills"
	ThiefMatchStatName(4)="Guard KOs"
	ThiefMatchStatName(5)="Thief Kills"
	LowResThiefName(0)="OP"
	LowResThiefName(1)="Lt"
	LowResThiefName(2)="St"
	LowResThiefName(3)="GK"
	LowResThiefName(4)="GKO"
	LowResThiefName(5)="TK"
	LowResGuardName(0)="Ret"
	LowResGuardName(1)="Rlt"
	LowResGuardName(2)="TK"
	LowResGuardName(3)="Dmg"
	LowResThiefMatchName(0)="OP"
	LowResThiefMatchName(1)="Lt"
	LowResThiefMatchName(2)="Dmg"
	LowResThiefMatchName(3)="GK"
	LowResThiefMatchName(4)="GKO"
	LowResThiefMatchName(5)="TK"
}
