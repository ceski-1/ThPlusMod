//=============================================================================
// ThPlusMutatorHUD.
//=============================================================================

class ThPlusMutatorHUD extends ThieveryMutatorHud;

var float LastLightGemTime;
var texture LightGemTex[12];

simulated function PostRender(canvas C)
{
	local ThieveryPPawn tpp;
	local float ScaleY, TextW, TextH, Pad, GemScale, GemW, GemH;
	local int Gem;

	tpp = ThieveryPPawn(Player);
	if (tpp == None || ThPlusHUD(tpp.myHUD) == None)
	{
		return;
	}

	ScaleY = 0.8 * class'ThHUD'.static.GetScaleY(C.ClipX, C.ClipY);
	Pad = 15.0 * ScaleY;
	C.Reset();
	C.Style = 3;
	C.Font = ThPlusHUD(tpp.myHUD).SansFontSmall;

	// contextual hud info (middle left part of screen)
	if (WeaponIconValue > 0.0)
	{
		C.DrawColor = WeaponIconValue * class'ThHUD'.Default.UnitColor;
		C.SetPos(64.0 * ScaleY, 0.5 * C.ClipY + 64.0 * ScaleY);
		C.DrawIcon(texture'WeaponIcon', 1.3 * ScaleY);
	}
	else if (DoorIconValue > 0.0 && tpp.bHumanAbilities && class'ThieveryConfigClient'.Default.bDoorIcon)
	{
		C.DrawColor = DoorIconValue * class'ThHUD'.Default.UnitColor;
		C.SetPos(64.0 * ScaleY, 0.5 * C.ClipY);
		C.DrawIcon(texture'DoorIcon', 0.5 * ScaleY);
	}

	// contextual hud info (upper right corner)
	if (OtherIconValue > 0.0)
	{
		if (OtherName != "")
		{
			C.DrawColor = (OtherIconValue / 255.0) * class'ThPlusHUD'.Default.TrueSilverColor;
			C.TextSize(OtherName, TextW, TextH);
			C.SetPos(C.ClipX - Pad - TextW, Pad);
			C.DrawText(OtherName);
			if (OtherTeam == Player.PlayerReplicationInfo.Team)
			{
				C.TextSize("Health: "$OtherHealth, TextW, TextH);
				C.SetPos(C.ClipX - Pad - TextW, Pad + TextH + Pad + 80.0 * ScaleY + Pad);
				C.DrawText("Health: "$OtherHealth);
			}
		}
		C.TextSize(" ", TextW, TextH);
		C.DrawColor = OtherIconValue * class'ThHUD'.Default.UnitColor;
		C.SetPos(C.ClipX - Pad - 80.0 * ScaleY, Pad + TextH + Pad);
		if (OtherTeam == 0)
		{
			if (class'ThPlusConfig'.Default.bUseModernTheme)
			{
				C.DrawIcon(texture'ThiefTile', 80.0 / 256.0 * ScaleY);
			}
			else
			{
				C.DrawIcon(texture'OtherThiefIcon', 80.0 / 64.0 * ScaleY);
			}
		}
		else if (OtherTeam == 1)
		{
			if (class'ThPlusConfig'.Default.bUseModernTheme)
			{
				C.DrawIcon(texture'GuardTile', 80.0 / 256.0 * ScaleY);
			}
			else
			{
				C.DrawIcon(texture'OtherGuardIcon', 80.0 / 64.0 * ScaleY);
			}
		}
		else if (OtherTeam == 255)
		{
			C.DrawIcon(texture'RatIcon', 80.0 / 64.0 * ScaleY);
		}
	}
	else if (WhistlerIconValue > 0.0)
	{
		C.DrawColor = (WhistlerIconValue / 255.0) * class'ThPlusHUD'.Default.TrueSilverColor;
		C.TextSize("Disabled Whistler", TextW, TextH);
		C.CurX = C.ClipX - Pad - TextW;
		C.CurY = Pad;
		C.DrawText("Disabled Whistler");
	}
	else if (SpecialIconValue > 0.0 && SpecialIconText != "")
	{
		C.DrawColor = (SpecialIconValue / 255.0) * class'ThPlusHUD'.Default.TrueSilverColor;
		C.TextSize(SpecialIconText, TextW, TextH);
		C.CurX = C.ClipX - Pad - TextW;
		C.CurY = Pad;
		C.DrawText(SpecialIconText);
	}

	// lightgem and visibility text
	if (tpp.PlayerReplicationInfo.Team == 0 && tpp.Health > 0)
	{
		if (class'ThieveryConfigClient'.Default.ShowVisibility)
		{
			C.Style = 3;
			C.Font = ThPlusHUD(tpp.myHUD).SansFontSmall;
			C.DrawColor = class'ThPlusHUD'.Default.TrueSilverColor;
			C.CurX = class'ThieveryConfigClient'.Default.hudx;
			C.CurY = class'ThieveryConfigClient'.Default.hudy;
			C.DrawText("Visibility: "$int(TotalVis * 100.0)$"%");
		}

		if (class'ThieveryConfigClient'.Default.ShowLightGem)
		{
			// smoothly change lightgem brightness
			if (Level.TimeSeconds - LastLightGemTime >= 1.0 / 60.0)
			{
				LastLightGemTime = Level.TimeSeconds;
				Gem = 1 + (TargetVis * 11.0);
				CurrentGem += Clamp(Gem - CurrentGem, -1, 1);
			}
			Gem = Clamp(CurrentGem, 1, 12) - 1;

			GemScale = 0.6 * ScaleY;
			GemW = 256.0 * GemScale;
			GemH = 64.0 * GemScale;

			C.Reset();
			C.DrawColor = class'ThHUD'.Default.UnitColor * (127.0 + (64.0 * Gem / 11.0));
			C.CurX = 0.5 * C.ClipX - 0.5 * GemW;
			C.CurY = C.ClipY - ThPlusHUD(tpp.myHUD).CompassHeight - GemH;
			C.DrawIcon(LightGemTex[Gem], GemScale);
		}
	}

	if (NextHUDMutator != None)
	{
		NextHUDMutator.PostRender(C);
	}
}

defaultproperties
{
	LightGemTex(0)=texture'LightGem1'
	LightGemTex(1)=texture'LightGem2'
	LightGemTex(2)=texture'LightGem3'
	LightGemTex(3)=texture'LightGem4'
	LightGemTex(4)=texture'LightGem5'
	LightGemTex(5)=texture'LightGem6'
	LightGemTex(6)=texture'LightGem7'
	LightGemTex(7)=texture'LightGem8'
	LightGemTex(8)=texture'LightGem9'
	LightGemTex(9)=texture'LightGemA'
	LightGemTex(10)=texture'LightGemB'
	LightGemTex(11)=texture'LightGemC'
}
