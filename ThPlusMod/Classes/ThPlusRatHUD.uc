//=============================================================================
// ThPlusRatHUD.
//=============================================================================

class ThPlusRatHUD extends ThieveryRatHUD;

#exec TEXTURE IMPORT NAME=FadeGradient FILE=Textures\FadeGradient.pcx GROUP=HUD MIPS=OFF

var float ScaleY;
var bool bTimeDown; // map time is counting down

// mass spectate
var float LastAllocateViewsTime; // timestamp when number of views was last updated
var float LastViewActorTime[4];  // timestamp when each player or layout last changed
var Pawn LastViewActor[4];       // the last player assigned to each view

static function Render(canvas C, ThieveryPPawn tpp)
{
	local float BottomBarH, TextW, TextH, RatFragsW, Pad, InsetY;
	local string Text;
	local ThieveryPPawn ViewPawn;

	if (ThHUD(tpp.myHUD) == None || tpp.GameReplicationInfo == None
		|| tpp.bShowObjectives > 0 || tpp.bShowMapScreen || ThHUD(tpp.myHUD).bShowInfo)
	{
		return;
	}

	Default.ScaleY = class'ThHUD'.static.GetScaleY(C.ClipX, C.ClipY);
	C.Reset();
	if (tpp.ViewTarget != None && tpp.ViewTarget != tpp)
	{
		ViewPawn = ThieveryPPawn(tpp.ViewTarget);
		if (ViewPawn == None || ViewPawn.PlayerReplicationInfo == None)
		{
			return;
		}

		if (!class'ThieveryConfigClient'.Default.bMassSpectate || Default.NumViews < 2)
		{
			if (!tpp.bShowScores)
			{
				if (!tpp.bBehindView && class'ThieveryConfigClient'.Default.bShowPlayerNames)
				{
					C.Style = 3;
					DrawFloatingPlayerNames(C, ViewPawn, tpp);
				}

				BottomBarH = 32.0 * Default.ScaleY;
				C.SetPos(0.0, C.ClipY - BottomBarH);
				if (class'ThPlusConfig'.Default.bUseModernTheme)
				{
					C.Style = 4;
					C.DrawRect(texture'GreyBackground', C.ClipX, BottomBarH);
				}
				else
				{
					C.Style = 1;
					C.DrawRect(texture'BlackTexture', C.ClipX, BottomBarH);
				}

				C.Style = 3;
				DrawTime(C, tpp);

				C.Style = 1;
				C.DrawColor = C.Default.DrawColor;
				DrawHealthBar(ViewPawn, C);

				if (ViewPawn.PlayerReplicationInfo.Team == 0
					&& class'ThieveryConfigClient'.Default.ShowLightGem)
				{
					DrawLightgemFor(C, ViewPawn);
				}
			}

			C.Style = 3;
			DrawFollowing(C, tpp, ViewPawn.PlayerReplicationInfo.PlayerName);
		}

		if (class'ThieveryConfigClient'.Default.bMassSpectate)
		{
			if (tpp.Level.TimeSeconds - Default.LastAllocateViewsTime > 2.0)
			{
				Default.LastAllocateViewsTime = tpp.Level.TimeSeconds;
				AllocateViews(tpp);
			}

			if (!tpp.bShowScores)
			{
				DrawSplitViews(C, tpp, ViewPawn);
			}
		}
	}
	else if (!tpp.bShowScores)
	{
		Pad = 12.0 * Default.ScaleY;
		InsetY = 36.0 * Default.ScaleY;

		C.Style = 3;
		C.DrawColor = class'ThPlusHUD'.Default.TrueSilverColor;
		C.Font = ThHUD(tpp.myHUD).MyFontMedium;

		if (tpp.Physics == PHYS_Flying && tpp.bHidden)
		{
			Text = "free-cam";
			C.TextSize(Text, TextW, TextH);
			C.CurX = C.ClipX - TextW - Pad;
			C.CurY = C.ClipY - InsetY;
			C.DrawText(Text);
		}
		else
		{
			Text = "Rat Frags";
			C.TextSize(Text, TextW, TextH);
			C.CurX = C.ClipX - TextW - Pad;
			C.CurY = C.ClipY - InsetY;
			C.DrawText(Text);

			C.Font = ThHUD(tpp.myHUD).MyFontLarge;
			Text = string(ThieveryPlayerReplicationInfo(tpp.PlayerReplicationInfo).RatFrags);
			C.TextSize(Text, RatFragsW, TextH);
			C.CurX = C.ClipX - 0.5 * (TextW + RatFragsW) - Pad;
			C.CurY = C.ClipY - 2.0 * InsetY;
			C.DrawText(Text);
		}
	}
}

static function DrawFloatingPlayerNames(canvas C, ThieveryPPawn ViewPawn, ThieveryPPawn tpp)
{
	local float TextW, TextH, Pad, HealthPad;
	local string Text;
	local vector Result, PositionDiff, EyePos, TargetPos;
	local Pawn P;

	Pad = 12.0 * Default.ScaleY;
	HealthPad = 84.0 * Default.ScaleY;
	C.Font = ThHUD(tpp.myHUD).SansFontMedium;
	foreach ViewPawn.RadiusActors(class'Pawn', P, 300.0)
	{
		if ((P.IsA('ThieveryPPawn') || P.IsA('TBot'))
			&& P != ViewPawn && !P.bHidden && P.PlayerReplicationInfo != None
			&& (P.PlayerReplicationInfo.Team == 1 || (P.PlayerReplicationInfo.Team == 0 && P.ScaleGlow > 0.3)))
		{
			EyePos = ViewPawn.Location + vect(0, 0, 1) * ViewPawn.EyeHeight;
			TargetPos = P.Location + vect(0, 0, 1) * P.CollisionHeight;
			if (P.IsA('TBot'))
			{
				TargetPos.Z += 2.0 * FMax(0.0, class'ThieveryPPawn'.Default.CollisionHeight - P.CollisionHeight);
			}
			PositionDiff = TargetPos - EyePos;
			if (class'ThieveryLowLevel.TLowLevelStatics'.static.TFastTrace(ViewPawn, EyePos, TargetPos)
				&& MapToHUD(Result, ViewPawn.ViewRotation, tpp.FOVAngle, PositionDiff, C))
			{
				Text = P.PlayerReplicationInfo.PlayerName;
				if (P.IsA('TBot'))
				{
					Text = "(AI) "$Text;
				}
				C.TextSize(Text, TextW, TextH);
				C.CurX = Result.X - 0.5 * TextW;
				C.CurY = Result.Y - TextH;

				// leave some padding around the text and don't overlap health
				C.CurX = FClamp(C.CurX, Pad, C.ClipX - TextW - Pad);
				C.CurY = FClamp(C.CurY, Pad, C.ClipY - TextH - HealthPad);

				C.DrawColor = class'ThPlusScoreboard'.static.GetTeamColor(P.PlayerReplicationInfo.Team);
				C.DrawText(Text);
			}
		}
	}
}

static function DrawTime(canvas C, ThieveryPPawn tpp)
{
	local int Hours, Minutes, Seconds;
	local float PosX, PosY, TextW, TextH, Pad, BottomBarH;
	local string Time, Label;
	local GameReplicationInfo GRI;
	local ThProGRI ProGRI;

	Pad = 12.0 * Default.ScaleY;
	BottomBarH = 32.0 * Default.ScaleY;

	C.Font = ThHUD(tpp.myHUD).SansFontSmall;
	C.TextSize(" ", TextW, TextH);
	PosX = Pad;
	PosY = C.ClipY - 0.5 * BottomBarH - 0.5 * TextH;

	GRI = tpp.GameReplicationInfo;
	if (Default.bTimeDown || GRI.RemainingTime > 0)
	{
		Default.bTimeDown = true;
		ProGRI = ThProGRI(GRI);
		if (ProGRI != None && ProGRI.usingWaves
			&& ProGRI.wave < ProGRI.totalWaves && ProGRI.nextWaveTime > 0)
		{
			Label = "Next Wave: ";
			Minutes = (GRI.RemainingTime - ProGRI.nextWaveTime) / 60;
			Seconds = (GRI.RemainingTime - ProGRI.nextWaveTime) % 60;
			Time = TwoDigitString(Minutes)$":"$TwoDigitString(Seconds);
		}
		else
		{
			Label = class'ThPlusScoreboard'.Default.RemainingTime;
			Time = "00:00";
			if (GRI.RemainingTime > 0)
			{
				Minutes = GRI.RemainingTime / 60;
				Seconds = GRI.RemainingTime % 60;
				Time = TwoDigitString(Minutes)$":"$TwoDigitString(Seconds);
			}
		}
	}
	else
	{
		Label = class'ThPlusScoreboard'.Default.ElapsedTime;
		Seconds = GRI.ElapsedTime;
		Minutes = Seconds / 60;
		Hours   = Minutes / 60;
		Seconds = Seconds - (Minutes * 60);
		Minutes = Minutes - (Hours * 60);
		Time = TwoDigitString(Hours)$":"$TwoDigitString(Minutes)$":"$TwoDigitString(Seconds);
	}
	ThHUD(tpp.myHUD).DrawLabelAndValue(C, PosX, PosY, Label, Time, false);
}

static function DrawHealthBar(ThieveryPPawn ViewPawn, canvas C)
{
	local float BottomBarH, CompassWidth;
	local float PosX, PosY, HealthIconScale, HealthIconW, HealthIconH;
	local float HealthIconSpacing, HealthFullW, HealthInsetX, HealthPaddingY;
	local int i, HealthIcons;

	BottomBarH = 32.0 * Default.ScaleY;
	CompassWidth = 102.4 * Default.ScaleY;

	HealthIcons = int(float(ViewPawn.Health) / ViewPawn.MaxHealth * 22.0);
	HealthIcons = Clamp(HealthIcons, int(ViewPawn.Health > 0), 22);

	HealthIconScale = 0.25 * Default.ScaleY;
	HealthIconW = 64.0 * HealthIconScale;
	HealthIconH = 128.0 * HealthIconScale;

	HealthFullW = (0.5 * C.ClipX) - (0.5 * CompassWidth) - (4.0 * Default.ScaleY);
	HealthIconSpacing = (HealthFullW - HealthIconW) / (0.5 + 21.0 + 0.5);
	HealthInsetX = 0.5 * HealthIconSpacing;
	HealthPaddingY = 8.0 * Default.ScaleY;

	PosY = C.ClipY - BottomBarH - HealthPaddingY - HealthIconH;
	for (i = 0; i < HealthIcons; i++)
	{
		PosX = float(i) * HealthIconSpacing + HealthInsetX;
		C.SetPos(PosX, PosY);
		C.DrawIcon(texture'HealthShield2', HealthIconScale);
	}
}

static function DrawLightGemFor(canvas C, ThieveryPPawn ViewPawn)
{
	local float TargetVis;
	local float GemScale, GemW, GemH, InsetY, BottomBarH, HealthIconH, HealthPaddingY;
	local int Gem;

	if (!ViewPawn.bHidden)
	{
		TargetVis = class'ThieveryMutator'.static.CalculateCurrentVisibility(ViewPawn);
	}
	Gem = 1 + (TargetVis * 11.0);
	Default.CurrentGem += Clamp(Gem - Default.CurrentGem, -1, 1);
	Gem = Clamp(Default.CurrentGem, 1, 12) - 1;

	GemScale = 0.6 * (0.8 * Default.ScaleY);
	GemW = 256.0 * GemScale;
	GemH = 64.0 * GemScale;
	BottomBarH = 32.0 * Default.ScaleY;
	HealthIconH = 128.0 * 0.25 * Default.ScaleY;
	HealthPaddingY = 8.0 * Default.ScaleY;
	InsetY = BottomBarH + HealthPaddingY + 0.5 * HealthIconH + 0.5 * GemH;

	C.SetPos(0.5 * C.ClipX - 0.5 * GemW, C.ClipY - InsetY);
	C.DrawIcon(class'ThPlusMutatorHUD'.Default.LightGemTex[Gem], GemScale);
}

static function DrawFollowing(canvas C, ThieveryPPawn tpp, string PlayerName)
{
	local float Pad, TimePad, BottomBarH;
	local float PosX, PosY, TextW, TextH, PlayerW, PlayerH, TrimWidth;
	local string LabelText;

	Pad = 12.0 * Default.ScaleY;
	TimePad = 116.0 * Default.ScaleY;
	BottomBarH = 32.0 * Default.ScaleY;

	LabelText = "Following: ";
	C.Font = ThHUD(tpp.myHUD).SansFontSmall;
	C.TextSize(LabelText, TextW, TextH);
	C.Font = ThHUD(tpp.myHUD).SansFontMedium;
	TrimWidth = 0.5 * C.ClipX - (Pad + TextW) - TimePad;
	PlayerName = class'ThPlusHUD'.static.TrimText(C, PlayerName, TrimWidth);

	C.TextSize(PlayerName, PlayerW, PlayerH);
	PosX = C.ClipX - TextW - PlayerW - Pad;
	PosY = C.ClipY - 0.5 * BottomBarH - 0.5 * TextH;
	ThHUD(tpp.myHUD).DrawLabelAndValue(C, PosX, PosY, LabelText, PlayerName, false);
}

static function AllocateViews(ThieveryPPawn tpp)
{
	local int i, LastNumViews;
	local Pawn P;

	foreach tpp.AllActors(class'Pawn', P)
	{
		if (P.IsA('ThieveryPPawn')
			|| (P.IsA('TBot') && class'ThieveryConfigClient'.Default.bShowAIInMass))
		{
			if (P.PlayerReplicationInfo != None
				&& P.PlayerReplicationInfo.Team == Pawn(tpp.ViewTarget).PlayerReplicationInfo.Team)
			{
				Default.ViewActor[i] = P;
				i++;
				if (i == 4)
				{
					break;
				}
			}
		}
	}
	LastNumViews = Default.NumViews;
	Default.NumViews = i;
	while (i < 4)
	{
		Default.ViewActor[i] = None;
		i++;
	}

	// track when the player or layout changes
	for (i = 0; i < 4; i++)
	{
		if (Default.ViewActor[i] != Default.LastViewActor[i]
			|| Default.NumViews != LastNumViews)
		{
			Default.LastViewActor[i] = Default.ViewActor[i];
			Default.LastViewActorTime[i] = tpp.Level.TimeSeconds;
		}
	}
}

static function DrawSplitViews(canvas C, ThieveryPPawn tpp, ThieveryPPawn ViewPawn)
{
	local bool bOldHideWeapon;

	if (Default.NumViews > 1)
	{
		if (ViewPawn.Weapon != None)
		{
			bOldHideWeapon = ViewPawn.Weapon.bHideWeapon;
			ViewPawn.Weapon.bHideWeapon = true;
		}

		C.Reset();
		C.DrawRect(texture'BlackTexture', C.ClipX, C.ClipY);
		switch (Default.NumViews)
		{
			case 2:
				DrawASplitView(C, tpp, 0, 0.0, 0.0, 1.0, 0.5);
				DrawASplitView(C, tpp, 1, 0.0, 0.5, 1.0, 0.5);
				break;
			case 3:
				DrawASplitView(C, tpp, 0, 0.0, 0.0, 0.5, 0.5);
				DrawASplitView(C, tpp, 1, 0.5, 0.0, 0.5, 0.5);
				DrawASplitView(C, tpp, 2, 0.0, 0.5, 1.0, 0.5);
				break;
			case 4:
				DrawASplitView(C, tpp, 0, 0.0, 0.0, 0.5, 0.5);
				DrawASplitView(C, tpp, 1, 0.5, 0.0, 0.5, 0.5);
				DrawASplitView(C, tpp, 2, 0.0, 0.5, 0.5, 0.5);
				DrawASplitView(C, tpp, 3, 0.5, 0.5, 0.5, 0.5);
				break;
			default:
				break;
		}

		if (ViewPawn.Weapon != None)
		{
			ViewPawn.Weapon.bHideWeapon = bOldHideWeapon;
		}
	}
}

static function DrawASplitView(canvas C, ThieveryPPawn tpp, int ViewNum,
							   float PosX, float PosY, float ViewW, float ViewH)
{
	local vector CamLoc;
	local rotator CamRot;
	local int Pad;
	local float CamFOV, PosV, dT;
	local bool bOldHidden;
	local string Text;
	local Pawn SplitActor;

	SplitActor = Default.ViewActor[ViewNum];
	if (SplitActor == None)
	{
		return;
	}

	Pad = Max(1, int(1.0 * Default.ScaleY + 0.5));
	PosX = PosX * C.ClipX + Pad;
	PosY = PosY * C.ClipY + 2 * Pad;
	ViewW = ViewW * C.ClipX - 4 * Pad;
	ViewH = ViewH * C.ClipY - 4 * Pad;

	// calculate location, rotation, and fov
	CamLoc = SplitActor.Location + vect(0, 0, 1) * SplitActor.EyeHeight;
	if (SplitActor.IsA('TBot'))
	{
		CamLoc.Z += FMax(0.0, class'ThieveryPPawn'.Default.BaseEyeHeight - SplitActor.EyeHeight);
		CamLoc.Z += FMax(0.0, class'ThieveryPPawn'.Default.CollisionHeight - SplitActor.CollisionHeight);
	}
	CamRot = SplitActor.Rotation;
	CamRot.Roll = 0.0;
	CamFOV = 2.0 * atan(0.75 * ViewW / ViewH) * 180.0 / Pi;

	// draw view
	bOldHidden = SplitActor.bHidden;
	SplitActor.bHidden = true;
	C.DrawPortal(PosX, PosY, ViewW, ViewH, tpp, CamLoc, CamRot, CamFOV);
	SplitActor.bHidden = bOldHidden;

	// draw player name
	C.Reset();
	C.Style = 3;
	C.DrawColor = class'ThPlusScoreboard'.static.GetTeamColor(SplitActor.PlayerReplicationInfo.Team);
	C.Font = ThHUD(tpp.myHUD).SansFontMedium;
	C.SetPos(PosX + 12.0 * Default.ScaleY, PosY + 12.0 * Default.ScaleY);
	Text = SplitActor.PlayerReplicationInfo.PlayerName;
	if (SplitActor.IsA('TBot'))
	{
		Text = "(AI) "$Text;
	}
	C.DrawText(Text);

	// fade in from black when the player or layout changes
	dT = tpp.Level.TimeSeconds - Default.LastViewActorTime[ViewNum];
	if (dT < 0.7)
	{
		PosV = 127.0 * FMin(1.0, dT / 0.7);
		C.Style = 4;
		C.SetPos(PosX, PosY);
		C.DrawTile(texture'FadeGradient', ViewW, ViewH, 0.0, PosV, 1.0, 1.0);
	}
}

defaultproperties
{
}
