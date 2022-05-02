//=============================================================================
// ThPlusHUD.
//=============================================================================

class ThPlusHUD extends ThProHud;

#exec OBJ LOAD FILE=ThPlusFonts.u PACKAGE=ThPlusFonts
#exec TEXTURE IMPORT NAME=BarSlotFill FILE=Textures\BarSlotFill.pcx GROUP=HUD MIPS=ON FLAGS=2
#exec TEXTURE IMPORT NAME=GuardBar FILE=Textures\GuardBar.pcx GROUP=HUD MIPS=ON FLAGS=2
#exec TEXTURE IMPORT NAME=GuardSlimBar FILE=Textures\GuardSlimBar.pcx GROUP=HUD MIPS=ON FLAGS=2
#exec TEXTURE IMPORT NAME=GuardVictory FILE=Textures\GuardVictory.pcx GROUP=HUD MIPS=ON
#exec TEXTURE IMPORT NAME=ScopeOverlay FILE=Textures\ScopeOverlay.pcx GROUP=HUD MIPS=ON
#exec TEXTURE IMPORT NAME=ThiefBar FILE=Textures\ThiefBar.pcx GROUP=HUD MIPS=ON FLAGS=2
#exec TEXTURE IMPORT NAME=ThiefSlimBar FILE=Textures\ThiefSlimBar.pcx GROUP=HUD MIPS=ON FLAGS=2
#exec TEXTURE IMPORT NAME=ThiefVictory FILE=Textures\ThiefVictory.pcx GROUP=HUD MIPS=ON

var ThieveryGameReplicationInfo tppGRI;
var ThieveryPlayerReplicationInfo tppPRI;

var float MyClipY;            // update fonts when screen size changes
var font HotbarFont;          // font for weapon hotbar slots
var font MapFont;             // font for map names only
var font SmallChatFont;       // font for various say/chat messages
var font SansFontTiny;        // font for loadout screen tooltips
var color TrueSilverColor;    // default text color

var Effects HUDMesh;          // used for drawing various meshes
var texture BodyIcon[2];      // held body icon
var string TeamName[2];       // "Thieves" or "Guards"
var bool bShowingEffects;     // offset tooltip when potion effects text is showing
var float LongShowTime;       // hud auto-hides after this amount of time
var float ShortShowTime;      // hud auto-hides sooner under certain conditions
var float FadeTime;           // hud auto-hide fade in/out time;
var float LastImportantChangeTime; // timestamp when health, weapon, or selected item last changed
var ThieveryWeapon SharedGroupWeapon; // weapon in inventory group "2" when shared by two weapons

// health
var float LastHealthTime;     // timestamp when health last changed
var bool bHealthChanged;      // player's health changed or is gradually healing
var int LastHealthIcons;      // last number of health icons
var int LastSmallHealthIcons; // last number of small health icons (when healing)
var bool bLastShowHealth;     // track changes to health icon visibility
var float HealthAlpha;        // for moving and fading health icons
var float ShowHealthTime;     // timestamp when health started being shown
var float HideHealthTime;     // timestamp when health started being hidden
var float HealthY;            // location of top edge of health icons (plus padding)
var float HealthInsetX;       // inset from left edge of canvas
var float HealthInsetY;       // inset from bottom edge of canvas
var float HealthIconH;        // scaled height of health icon
var float HealthFullW;        // entire usable width available to health icons
var float HealthPaddingY;     // padding between bottom edge of canvas and bottom edge of health icon

// weapon
var bool bHotbarVisible;      // hide the weapon icon if the hotbar is visible
var bool bLastShowBar;        // track changes to weapon hotbar visibility
var float HotbarWidth[2];     // unscaled pixel width of hotbar textures
var texture HotbarTex[2];     // standard weapon hotbar textures
var texture SlimBarTex[2];    // darker and lower height hotbar textures
var float HotbarAutoScale;    // limit hotbar scale to avoid overlapping lightgem and compass
var byte TotalHotkeys[2];     // number of weapon hotkeys used by each team
var float HotbarY;            // location of top edge of hotbar (plus text spacing)
var float BarAlpha;           // for moving and fading weapon hotbar
var float ShowBarTime;        // timestamp when hotbar started being shown
var float HideBarTime;        // timestamp when hotbar started being hidden

// selected item / item wheel
var class<ThieveryPickup> LastPickupClass; // last selected item class
var float LastPickupTime;     // timestamp when selected item last changed
var float WheelExpandTime;    // amount of time item wheel takes to expand
var float WheelContractTime;  // amount of time item wheel takes to contract
var float WheelSpinTime;      // amount of time item wheel takes to rotate to next item

// loot
var int BaseLoot;             // player's loot amount prior to the most recent change
var int DeltaLoot;            // difference between current loot and base loot
var int LastLoot;             // last amount of loot
var float LastLootHoverTime;  // timestamp when player last hovered over loot
var float LastLootTime;       // timestamp when loot last changed
var bool bLastShowLoot;       // track changes to loot text visibility
var float LootAlpha;          // for moving and fading loot text
var float ShowLootTime;       // timestamp when loot started being shown
var float HideLootTime;       // timestamp when loot started being hidden

// compass
var float LastYawTime;        // timestamp when player last rotated view
var int LastYaw;              // last player yaw rotation
var bool bLastShowCompass;    // track changes to compass visibility
var float CompassAlpha;       // for moving and fading compass
var float ShowCompassTime;    // timestamp when compass started being shown
var float HideCompassTime;    // timestamp when compass started being hidden
var float CompassWidth;       // scaled compass width
var float CompassHeight;      // scaled compass height
var float LastShowMapTime;    // timestamp when player last checked map

// valid font sizes
var int SansFontSize[16], CleanFontSize[16], SerifFontSize[16];

struct MeshInfo // mesh info for drawing various meshes
{
	var mesh Mesh;
	var float Scale;
	var vector Offset;
	var rotator Rotation;
	var texture Skin[4];
	var float Glow;
};

//=============================================================================
// see ThPlusPawn for the other show/hide screen changes

exec function ShowServerInfo()
{
	if (!bShowInfo && ThPlusPawn(tpp) != None)
	{
		ThPlusPawn(tpp).UpdateVisibleHUDScreens("ShowServerInfo");
	}
	bShowInfo = !bShowInfo;
}

simulated function bool ProcessKeyEvent(int Key, int Action, float Delta)
{
	if (tpp == None)
	{
		return false;
	}

	if (Key == EInputKey.IK_Escape)
	{
		if (tpp.bShowMapScreen)
		{
			tpp.bShowMapScreen = false;
			return true;
		}
		else if (tpp.bShowObjectives != 0 && tpp.GetStateName() != 'PlayerWaiting')
		{
			tpp.bShowObjectives = 0;
			return true;
		}
		else if (ThProjectileScoutingOrbD(tpp.ViewTarget) != None || tpp.GetStateName() == 'PlayerScouting')
		{
			tpp.StopScouting();
			return true;
		}
		else if (tpp.CurrentReadBook != None || tpp.GetStateName() == 'PlayerReadingBook')
		{
			tpp.GotoState('PlayerWalking');
			tpp.StopReadingBook();
			return true;
		}
	}
	return Super.ProcessKeyEvent(Key, Action, Delta);
}

//=============================================================================
// trim text

static function string TrimText(canvas C, string Text, float TrimWidth, optional int MaxChars)
{
	local float TextWidth, TextHeight, EllipsisWidth;
	local int i, TextLength;

	if (MaxChars == 0)
	{
		MaxChars = 120;
	}

	C.TextSize(Text, TextWidth, TextHeight);
	if (TextWidth > TrimWidth)
	{
		TextLength = Min(MaxChars, Len(Text));
		C.TextSize("...", EllipsisWidth, TextHeight);
		for (i = 0; i < TextLength; i++)
		{
			Text = Left(Text, TextLength - i);
			C.TextSize(Text, TextWidth, TextHeight);
			if (TrimWidth > TextWidth + EllipsisWidth)
			{
				Text = Text$"...";
				break;
			}
		}
	}
	return Text;
}

//=============================================================================
// fonts
//
// hand-tuned under 720 res height, otherwise scaled using original 1024x768 or
// 1280x960 appearance as reference

simulated function FindSomeFonts(canvas C)
{
	if (C.ClipY < 600) // 0 to 599
	{
		SansFontTiny    = Font(DynamicLoadObject("LadderFonts.UTLadder10", class'Font'));
		SansFontSmall   = Font(DynamicLoadObject("LadderFonts.UTLadder12", class'Font'));
		SansFontMedium  = Font(DynamicLoadObject("LadderFonts.UTLadder12", class'Font'));
		SansFontLarge   = Font(DynamicLoadObject("LadderFonts.UTLadder16", class'Font'));
		MapFont         = Font'Engine.SmallFont';
		CleanFontSmall  = Font'Engine.SmallFont';
		CleanFontMedium = Font(DynamicLoadObject("LadderFonts.UTLadder10", class'Font'));
		MyFontSmall     = Font(DynamicLoadObject("ThPlusFonts.ThSerif14", class'Font'));
		MyFontMedium    = Font(DynamicLoadObject("ThPlusFonts.ThSerif18", class'Font'));
		MyFontLarge     = Font(DynamicLoadObject("ThPlusFonts.ThSerif20", class'Font'));
		SmallChatFont   = Font(DynamicLoadObject("LadderFonts.UTLadder12", class'Font'));
		LargeChatFont   = Font(DynamicLoadObject("LadderFonts.UTLadder16", class'Font'));
		HotbarFont      = Font(DynamicLoadObject("LadderFonts.UTLadder10", class'Font'));
	}
	else if (C.ClipY < 720) // 600 to 719
	{
		SansFontTiny    = Font(DynamicLoadObject("LadderFonts.UTLadder12", class'Font'));
		SansFontSmall   = Font(DynamicLoadObject("LadderFonts.UTLadder12", class'Font'));
		SansFontMedium  = Font(DynamicLoadObject("LadderFonts.UTLadder14", class'Font'));
		SansFontLarge   = Font(DynamicLoadObject("LadderFonts.UTLadder20", class'Font'));
		MapFont         = Font(DynamicLoadObject("LadderFonts.UTLadder12", class'Font'));
		CleanFontSmall  = Font(DynamicLoadObject("LadderFonts.UTLadder12", class'Font'));
		CleanFontMedium = Font(DynamicLoadObject("LadderFonts.UTLadder12", class'Font'));
		MyFontSmall     = Font(DynamicLoadObject("ThPlusFonts.ThSerif14", class'Font'));
		MyFontMedium    = Font(DynamicLoadObject("ThPlusFonts.ThSerif18", class'Font'));
		MyFontLarge     = Font(DynamicLoadObject("ThPlusFonts.ThSerif20", class'Font'));
		SmallChatFont   = Font(DynamicLoadObject("LadderFonts.UTLadder14", class'Font'));
		LargeChatFont   = Font(DynamicLoadObject("LadderFonts.UTLadder20", class'Font'));
		HotbarFont      = Font(DynamicLoadObject("LadderFonts.UTLadder12", class'Font'));
	}
	else // 720 and up
	{
		SansFontTiny    = GetScaledFont(C, "ThSans", 12);
		SansFontSmall   = GetScaledFont(C, "ThSans", 14);
		SansFontMedium  = GetScaledFont(C, "ThSans", 16);
		SansFontLarge   = GetScaledFont(C, "ThSans", 24);
		MapFont         = GetScaledFont(C, "UTLadder", 11);
		CleanFontSmall  = GetScaledFont(C, "ThClean", 11);
		CleanFontMedium = GetScaledFont(C, "ThClean", 12);
		MyFontSmall     = GetScaledFont(C, "ThSerif", 16);
		MyFontMedium    = GetScaledFont(C, "ThSerif", 22);
		MyFontLarge     = GetScaledFont(C, "ThSerif", 28);
		SmallChatFont   = GetScaledFont(C, "ThClean", 16);
		LargeChatFont   = GetScaledFont(C, "ThClean", 22);
		HotbarFont      = GetScaledFont(C, "ThSans", 13);
	}
	LargeChatFontName = string(LargeChatFont);
}

static function font GetScaledFont(canvas C, string FontFamily, int FontSize)
{
	FontSize = float(FontSize) * C.ClipY / 768.0;
	FontSize += FontSize % 2;
	if (FontFamily ~= "ThSans")
	{
		FontSize = GetClosestFontSize(FontSize, Default.SansFontSize);
	}
	else if (FontFamily ~= "ThClean")
	{
		FontSize = GetClosestFontSize(FontSize, Default.CleanFontSize);
	}
	else if (FontFamily ~= "ThSerif")
	{
		FontSize = GetClosestFontSize(FontSize, Default.SerifFontSize);
	}
	else // UTLadder
	{
		return GetLadderFont(FontSize);
	}
	return Font(DynamicLoadObject("ThPlusFonts."$FontFamily$FontSize, class'Font'));
}

static function int GetClosestFontSize(int FontSize, int FontSizeArray[16])
{
	local int i, Low, High, Mid;

	for (i = 0; i < ArrayCount(FontSizeArray); i++)
	{
		if (FontSizeArray[i] > 0)
		{
			High++;
		}
	}
	High--;

	// binary search
	while (High - Low > 1)
	{
		Mid = (High + Low) / 2;
		if (FontSizeArray[Mid] < FontSize)
		{
			Low = Mid;
		}
		else
		{
			High = Mid;
		}
	}

	if (FontSize - FontSizeArray[Low] <= FontSizeArray[High] - FontSize)
	{
		return FontSizeArray[Low];
	}
	else
	{
		return FontSizeArray[High];
	}
}

static function font GetLadderFont(int FontSize)
{
	if (FontSize < 27)
	{
		FontSize = Clamp(FontSize, 10, 24);
	}
	else
	{
		FontSize = 30;
	}
	return Font(DynamicLoadObject("LadderFonts.UTLadder"$FontSize, class'Font'));
}

//=============================================================================
// colors

static final operator(34) color *= (out color A, float B)
{
	A = A * B;
	return A;
}

//=============================================================================
// easing functions
//
// A: initial value, B: final value, X: alpha (0.0 to 1.0), P: power (exponent)

// slow --> fast
static function float EaseIn(float A, float B, float X, optional float P)
{
	if (P == 0.0)
	{
		P = 2.0;
	}
	return A + (B - A) * (X ** P);
}

// fast --> slow
static function float EaseOut(float A, float B, float X, optional float P)
{
	if (P == 0.0)
	{
		P = 2.0;
	}
	return B + (A - B) * (1.0 - X) ** P;
}

// slow --> fast --> slow
static function float EaseInOut(float A, float B, float X, optional float P)
{
	if (P == 0.0)
	{
		P = 2.0;
	}
	return A + (B - A) * (X ** P) / (X ** P + (1.0 - X) ** P);
}

//=============================================================================
// alpha for moving and fading hud elements

simulated function GetAlpha(bool bShow, bool bLastShow, out float Alpha,
							out float ShowTime, out float HideTime)
{
	if (bShow != bLastShow)
	{
		if (bShow)
		{
			ShowTime = Level.TimeSeconds;
			if (Alpha > 0.0)
			{
				ShowTime -= FadeTime * Alpha;
			}
			HideTime = 0.0;
		}
		else
		{
			ShowTime = 0.0;
			HideTime = Level.TimeSeconds;
		}
	}

	if (ShowTime > 0.0)
	{
		if (Level.TimeSeconds - ShowTime >= FadeTime)
		{
			Alpha = 1.0;
			ShowTime = 0.0;
			HideTime = 0.0;
		}
		else
		{
			Alpha = (Level.TimeSeconds - ShowTime) / FadeTime;
			Alpha = FClamp(Alpha, 0.0, 1.0);
		}
	}
	else if (HideTime > 0.0)
	{
		if (Level.TimeSeconds - HideTime >= FadeTime)
		{
			Alpha = 0.0;
			ShowTime = 0.0;
			HideTime = 0.0;
		}
		else
		{
			Alpha = 1.0 - (Level.TimeSeconds - HideTime) / FadeTime;
			Alpha = FClamp(Alpha, 0.0, 1.0);
		}
	}
}

//=============================================================================
// meshes
//
// draw meshes for weapon hotbar, weapon icon, selected item, item wheel and
// loadout screens

simulated function DrawHUDMesh(canvas C, MeshInfo DispMesh, float PosX, float PosY, float Size)
{
	local vector Projected;
	local rotator Tilt;
	local float OldClipX, OldClipY, OldFOVAngle, BaseScale, BaseAspectRatio;
	local int DrawWidth, DrawHeight, DrawLeft, DrawTop;

	if (DispMesh.Mesh == None)
	{
		return;
	}

	if (HUDMesh == None)
	{
		HUDMesh = Spawn(class'Effects', tpp);
		HUDMesh.DrawType = DT_Mesh;
		HUDMesh.RemoteRole = ROLE_None;
		HUDMesh.SetPhysics(PHYS_Rotating);
		HUDMesh.SetCollision(false, false, false);
		HUDMesh.bCollideWorld = false;
		HUDMesh.bStasis = false;
		HUDMesh.bUnlit = true;
		HUDMesh.AmbientGlow = 0;
		HUDMesh.bCarriedItem = true;
		HUDMesh.bHidden = true;
	}
	HUDMesh.Mesh = DispMesh.Mesh;
	HUDMesh.DrawScale = DispMesh.Scale;
	HUDMesh.MultiSkins[0] = DispMesh.Skin[0];
	HUDMesh.MultiSkins[1] = DispMesh.Skin[1];
	HUDMesh.MultiSkins[2] = DispMesh.Skin[2];
	HUDMesh.MultiSkins[3] = DispMesh.Skin[3];
	HUDMesh.ScaleGlow = DispMesh.Glow;

	SaveCanvasState(C);
	OldClipX = C.ClipX;
	OldClipY = C.ClipY;
	OldFOVAngle = tpp.FOVAngle;

	DrawWidth = Size + 0.5;
	DrawHeight = DrawWidth;
	DrawLeft = (PosX + 0.5) - (DrawWidth / 2);
	DrawTop = (PosY + 0.5) - (DrawHeight / 2);

	C.Reset();
	C.SetOrigin(DrawLeft, DrawTop);
	C.SetClip(DrawWidth, DrawHeight);
	C.SetPos(DrawWidth / 2, DrawHeight / 2);

	BaseScale = 768.0 / 64.0;
	BaseAspectRatio = 4.0 / 3.0;
	HUDMesh.DrawScale *= BaseScale * BaseAspectRatio;

	tpp.FOVAngle = 1.0;
	Projected.X = 5.0 / tan(tpp.FOVAngle * Pi / 180.0 * 0.5);
	HUDMesh.SetLocation(Projected + DispMesh.Offset);

	DispMesh.Rotation = class'TInfo'.static.ConcatRotation(DispMesh.Rotation, SpinMesh());
	Tilt.Pitch = 3969; // atan(0.4) * 32768 / pi
	DispMesh.Rotation = class'TInfo'.static.ConcatRotation(DispMesh.Rotation, Tilt);
	HUDMesh.SetRotation(DispMesh.Rotation);

	HUDMesh.bHidden = false;
	C.DrawClippedActor(HUDMesh, false, DrawWidth, DrawHeight, DrawLeft, DrawTop, true);
	HUDMesh.bHidden = true;

	tpp.FOVAngle = OldFOVAngle;
	C.ClipX = OldClipX;
	C.ClipY = OldClipY;
	RestoreCanvasState(C);
}

simulated function rotator SpinMesh()
{
	return rot(0, 1, 0) * (65535 * (Level.TimeSeconds % 5.0) / 5.0);
}

static function MeshInfo GetHotbarMesh(ThieveryWeapon SlotWeapon,
									   class<ThieveryProjectile> SlotProjectileClass)
{
	local MeshInfo DispMesh;

	if (SlotWeapon != None)
	{
		if (SlotWeapon.bMeleeWeapon)
		{
			DispMesh = GetMeleeMesh(SlotWeapon.Class);
			DispMesh.Glow *= 1.25;
		}
		else if (SlotProjectileClass != None)
		{
			DispMesh = GetRangedMesh(SlotProjectileClass);
			DispMesh.Glow *= 1.25;
		}
	}
	return DispMesh;
}

static function MeshInfo GetWeaponIconMesh(ThieveryWeapon Weap)
{
	local class<ThieveryProjectile> ProjectileClass;
	local MeshInfo DispMesh;

	if (Weap != None)
	{
		if (Weap.bMeleeWeapon)
		{
			DispMesh = GetMeleeMesh(Weap.Class);
		}
		else if (ThieveryAmmo(Weap.AmmoType) != None)
		{
			ProjectileClass = ThieveryAmmo(Weap.AmmoType).Default.ProjectileClass;
			if (ProjectileClass != None)
			{
				DispMesh = GetRangedMesh(ProjectileClass);
			}
		}
	}
	return DispMesh;
}

static function MeshInfo GetMeleeMesh(class<ThieveryWeapon> WeaponClass)
{
	local MeshInfo DispMesh;

	if (WeaponClass != None)
	{
		DispMesh.Mesh = WeaponClass.Default.LoadoutMesh;
		DispMesh.Scale = WeaponClass.Default.LoadoutScale;
		DispMesh.Offset = WeaponClass.Default.LoadoutOffset;
		DispMesh.Rotation = WeaponClass.Default.LoadoutRotation;
		DispMesh.Glow = 1.0;
		ApplyMeleeMeshCorrections(WeaponClass, DispMesh);
	}
	return DispMesh;
}

static function MeshInfo GetRangedMesh(class<ThieveryProjectile> ProjectileClass)
{
	local MeshInfo DispMesh;

	if (ProjectileClass != None)
	{
		DispMesh.Mesh = ProjectileClass.Default.Mesh;
		DispMesh.Scale = ProjectileClass.Default.LoadoutScale;
		DispMesh.Offset = ProjectileClass.Default.LoadoutOffset;
		DispMesh.Rotation = ProjectileClass.Default.LoadoutRotation;
		DispMesh.Skin[0] = ProjectileClass.Default.MultiSkins[0];
		DispMesh.Skin[1] = ProjectileClass.Default.MultiSkins[1];
		DispMesh.Skin[2] = ProjectileClass.Default.MultiSkins[2];
		DispMesh.Skin[3] = ProjectileClass.Default.MultiSkins[3];
		DispMesh.Glow = 1.0;
		ApplyRangedMeshCorrections(ProjectileClass, DispMesh);
	}
	return DispMesh;
}

static function MeshInfo GetItemMesh(ThieveryPickup Item)
{
	local MeshInfo DispMesh;

	if (Item != None)
	{
		DispMesh.Mesh = Item.PlayerViewMesh;
		if (DispMesh.Mesh == None)
		{
			DispMesh.Mesh = Item.PickupViewMesh;
		}
		DispMesh.Scale = Item.DrawScale * Default.WheelItemScale * 0.5;
		DispMesh.Offset = Item.LoadoutOffset;
		DispMesh.Rotation = Item.LoadoutRotation;
		DispMesh.Skin[0] = Item.MultiSkins[0];
		DispMesh.Skin[1] = Item.MultiSkins[1];
		DispMesh.Skin[2] = Item.MultiSkins[2];
		DispMesh.Skin[3] = Item.MultiSkins[3];
		DispMesh.Glow = 1.0;
		ApplyItemMeshCorrections(Item.Class, DispMesh);
	}
	return DispMesh;
}

simulated function DrawLoadoutMesh(canvas C, float X, float Y, float Size,
								   mesh DisplayMesh, float DisplayScale,
								   vector DisplayOffset, rotator DisplayRotation,
								   texture DisplaySkin0, texture DisplaySkin1,
								   texture DisplaySkin2, texture DisplaySkin3,
								   float Glow)
{
	local MeshInfo DispMesh;

	DispMesh.Mesh = DisplayMesh;
	DispMesh.Scale = DisplayScale;
	DispMesh.Offset = DisplayOffset;
	DispMesh.Rotation = DisplayRotation;
	DispMesh.Skin[0] = DisplaySkin0;
	DispMesh.Skin[1] = DisplaySkin1;
	DispMesh.Skin[2] = DisplaySkin2;
	DispMesh.Skin[3] = DisplaySkin3;
	DispMesh.Glow = Glow;
	DrawHUDMesh(C, DispMesh, X, Y, Size);
}

static function ApplyLoadoutMeshCorrections(class<ThieveryWeapon> WeaponClass,
											class<ThieveryProjectile> ProjectileClass,
											class<ThieveryPickup> ItemClass,
											out mesh DisplayMesh, out float DisplayScale,
											out vector DisplayOffset, out rotator DisplayRotation,
											out texture DisplaySkin0, out texture DisplaySkin1,
											out texture DisplaySkin2, out texture DisplaySkin3,
											out float Glow)
{
	local MeshInfo DispMesh;

	DispMesh.Mesh = DisplayMesh;
	DispMesh.Scale = DisplayScale;
	DispMesh.Offset = DisplayOffset;
	DispMesh.Rotation = DisplayRotation;
	DispMesh.Skin[0] = DisplaySkin0;
	DispMesh.Skin[1] = DisplaySkin1;
	DispMesh.Skin[2] = DisplaySkin2;
	DispMesh.Skin[3] = DisplaySkin3;
	DispMesh.Glow = 1.0;

	if (WeaponClass != None)
	{
		ApplyMeleeMeshCorrections(WeaponClass, DispMesh);
	}
	else if (ProjectileClass != None)
	{
		ApplyRangedMeshCorrections(ProjectileClass, DispMesh);
	}
	else if (ItemClass != None)
	{
		ApplyLoadoutItemMeshCorrections(ItemClass, DispMesh);
	}

	DisplayMesh = DispMesh.Mesh;
	DisplayScale = DispMesh.Scale;
	DisplayOffset = DispMesh.Offset;
	DisplayRotation = DispMesh.Rotation;
	DisplaySkin0 = DispMesh.Skin[0];
	DisplaySkin1 = DispMesh.Skin[1];
	DisplaySkin2 = DispMesh.Skin[2];
	DisplaySkin3 = DispMesh.Skin[3];
	Glow = DispMesh.Glow;
}

static function ApplyMeleeMeshCorrections(class<ThieveryWeapon> WeaponClass,
										  out MeshInfo DispMesh)
{
	DispMesh.Rotation = rot(0, 0, 0);
	DispMesh.Glow = FMax(1.0, WeaponClass.Default.ScaleGlow);
	switch (WeaponClass)
	{
		case class'ThWeaponBlackJack':
			DispMesh.Mesh = WeaponClass.Default.SpinnyHudMesh;
			DispMesh.Scale *= 1.1;
			DispMesh.Offset = vect(0, 0, -2.7);
			break;
		case class'ThWeaponMace':
			DispMesh.Scale *= 1.1;
			DispMesh.Offset = vect(0, 0, -2.1);
			break;
		case class'ThWeaponSword':
			DispMesh.Mesh = WeaponClass.Default.SpinnyHudMesh;
			DispMesh.Scale *= 1.1;
			DispMesh.Offset = vect(0, 0, -2.7);
			break;
		default:
			break;
	}
}

static function ApplyRangedMeshCorrections(class<ThieveryProjectile> ProjectileClass,
										   out MeshInfo DispMesh)
{
	DispMesh.Rotation = rot(0, 0, 0);
	DispMesh.Glow = FMax(1.0, ProjectileClass.Default.ScaleGlow);
	switch (ProjectileClass)
	{
		case class'ThProjectileBroadheadArrow':
		case class'ThProjectileExplosiveArrow':
		case class'ThProjectileFlareArrow':
		case class'ThProjectileRopeArrow':
		case class'ThProjectileSmokeArrow':
		case class'ThProjectileVineArrow':
			DispMesh.Scale *= 0.7;
			DispMesh.Glow = 1.6;
			break;
		case class'ThProjectileCrackArrow':
		case class'ThProjectileMossArrow':
			DispMesh.Scale *= 0.95;
			break;
		case class'ThProjectileFootstepArrow':
		case class'ThProProjectileNoiseArrow':
			DispMesh.Scale *= 0.9;
			break;
		case class'ThProjectileWaterArrow':
			DispMesh.Scale *= 0.8;
			DispMesh.Glow = 1.2;
			break;
		case class'ThProFireBolt':
		case class'ThProjectileFireBolt':
		case class'ThProjectileParalyseBolt':
		case class'ThProjectileStandardBolt':
		case class'ThProjectileTagBolt':
			DispMesh.Scale *= 1.6;
			DispMesh.Glow = 1.2;
			break;
		default:
			break;
	}
}

static function ApplyItemMeshCorrections(class<ThieveryPickup> ItemClass,
										 out MeshInfo DispMesh)
{
	DispMesh.Rotation = rot(0, 0, 0);
	DispMesh.Glow = FMax(1.0, ItemClass.Default.ScaleGlow);
	switch (ItemClass)
	{
		case class'ThPickupMagnesiumFlash':
			DispMesh.Scale *= 1.5;
			break;
		case class'ThPickupScoutingOrb':
			DispMesh.Scale *= 1.25;
			break;
		case class'ThPickupCarrot':
			DispMesh.Scale *= 1.4;
			break;
		case class'ThPickupChicken':
			DispMesh.Scale *= 0.9;
			break;
		case class'ThPickupCookie':
			DispMesh.Scale *= 1.1;
			break;
		case class'ThPickupDeerLeg':
			DispMesh.Scale *= 0.5;
			break;
		case class'ThPickupFish':
			DispMesh.Scale *= 0.9;
			DispMesh.Rotation = rot(0, 0, 16384);
			break;
		case class'ThPickupGrapplingHook':
			DispMesh.Offset = vect(0, 0, -0.8);
			break;
		case class'ThPickupLockpicks':
			DispMesh.Scale *= 0.95;
			break;
		case class'ThPickupNormalDoorKey':
		case class'ThPickupSilverKey':
			DispMesh.Scale *= 0.8;
			DispMesh.Rotation = rot(-16384, 0, 0);
			break;
		case class'ThPickupRepairTool':
			DispMesh.Scale *= 0.8;
			break;
		case class'ThPickupSupplyChest':
			DispMesh.Scale *= 1.2;
			break;
		case class'ThPickupTripwire':
			DispMesh.Scale *= 2.5;
			DispMesh.Rotation = rot(0, 0, 16384);
			DispMesh.Glow = 1.3;
			break;
		case class'ThPickupWhistler':
			DispMesh.Scale *= 1.6;
			DispMesh.Offset = vect(0, 0, 1.1);
			break;
		default:
			break;
	}
}

static function ApplyLoadoutItemMeshCorrections(class<ThieveryPickup> ItemClass,
												out MeshInfo DispMesh)
{
	DispMesh.Rotation = rot(0, 0, 0);
	DispMesh.Glow = FMax(1.0, ItemClass.Default.ScaleGlow);
	switch (ItemClass)
	{
		case class'ThPickupCaltrop':
			DispMesh.Scale *= 1.1;
			DispMesh.Offset = vect(0, 0, -0.2);
			DispMesh.Glow = 1.5;
			break;
		case class'ThPickupFlare':
			DispMesh.Scale *= 1.3;
			break;
		case class'ThPickupFlashbomb':
		case class'ThPickupMagnesiumFlash':
		case class'ThPickupScoutingOrb':
			DispMesh.Scale *= 0.8;
			break;
		case class'ThPickupGrapplingHook':
			DispMesh.Scale *= 1.05;
			DispMesh.Offset = vect(0, 0, -1.7);
			DispMesh.Glow = 1.4;
			break;
		case class'ThPickupHelmet':
			DispMesh.Scale *= 0.95;
			break;
		case class'ThPickupLockpicks':
			DispMesh.Scale *= 0.9;
			break;
		case class'ThPickupMarkingDye':
			DispMesh.Offset = vect(0, 0, 0.4);
			break;
		case class'ThPickupMine':
			DispMesh.Glow = 1.2;
			break;
		case class'ThPickupPotionBreath':
		case class'ThPickupPotionCatfall':
		case class'ThPickupPotionHealth':
		case class'ThPickupPotionInvisibility':
		case class'ThPickupPotionSpeed':
			DispMesh.Scale *= 0.95;
			break;
		case class'ThPickupRations':
			DispMesh.Scale *= 1.25;
			break;
		case class'ThPickupRepairTool':
			DispMesh.Offset = vect(0, 0, 0.3);
			break;
		case class'ThPickupSensingDevice':
			DispMesh.Offset = vect(0, 0, -0.3);
			break;
		case class'ThPickupShadowStep':
			DispMesh.Scale *= 1.65;
			DispMesh.Offset = vect(0, 0, 0.4);
			DispMesh.Glow = 1.4;
			break;
		case class'ThPickupSupplyChest':
			DispMesh.Scale *= 1.05;
			break;
		case class'ThPickupTelescope':
			DispMesh.Scale *= 1.2;
			break;
		case class'ThPickupTripwire':
			DispMesh.Scale *= 3.5;
			DispMesh.Rotation = rot(0, 0, 16384);
			DispMesh.Glow = 1.5;
			break;
		case class'ThPickupWhistler':
			DispMesh.Scale *= 0.7;
			DispMesh.Glow = 1.2;
			break;
		default:
			break;
	}
}

//=============================================================================

simulated function PreBeginPlay()
{
	local ThPlusMutatorHUD NewHUD;

	LargeChatFont = Font(DynamicLoadObject(LargeChatFontName, class'Font'));

	// lightgem and contextual hud info fixes
	NewHUD = Spawn(class'ThPlusMutatorHUD', Self);
	if (Pawn(Owner) != None && !GotAThieveryHud())
	{
		NewHUD.Player = Pawn(Owner);
		NewHUD.NextHUDMutator = HUDMutator;
		HUDMutator = NewHUD;
		NewHUD.PrepareThievery();
	}
}

simulated function Tick(float DeltaTime)
{
	if (tpp == None || tpp.PlayerReplicationInfo == None || ThPlusPawn(tpp) == None)
	{
		return;
	}

	if (tpp.Weapon == None || tpp.Weapon.bMeleeWeapon)
	{
		CurrentCrossHairBrightness += DeltaTime * CrossHairBrightness * 2.0;
	}
	else
	{
		CurrentCrossHairBrightness -= DeltaTime * CrossHairBrightness * 2.0;
	}
	CurrentCrossHairBrightness = FClamp(CurrentCrossHairBrightness, 0.0, CrossHairBrightness);

	// merged ProMod's flash calculation
	if (tpp.Blindness > 0.0)
	{
		if (tpp.Blindness < 200.0 || ThPlusPawn(tpp).bUseNewFlashCalculation)
		{
			tpp.Blindness -= 40.0 * Deltatime;
		}
		else
		{
			tpp.Blindness -= 10.0 * Deltatime;
		}
		tpp.Blindness = FMax(0.0, tpp.Blindness);
	}
}

simulated function PostRender(canvas C)
{
	if (ThPlusPawn(Owner) == None || C == None)
	{
		return;
	}

	if (C.ClipX != MyClipX || C.ClipY != MyClipY)
	{
		MyClipX = C.ClipX;
		MyClipY = C.ClipY;
		FindSomeFonts(C);
	}
	Super.PostRender(C);
}

simulated function DrawHUD(canvas C)
{
	tppGRI = ThieveryGameReplicationInfo(tpp.GameReplicationInfo);
	tppPRI = ThieveryPlayerReplicationInfo(tpp.PlayerReplicationInfo);
	if (tppPRI == None || tppGRI == None)
	{
		return;
	}
	TrackHUDChanges();
	UpdateHUDAutoHide(C);
	C.Reset();
	Super.DrawHUD(C);
	DrawWeaponIcon(C);
}

//=============================================================================
// update loadout window

simulated function UpdateLoadoutWindow()
{
	local WindowConsole Con;
	local UWindowWindow Win;

	Con = WindowConsole(tpp.Player.Console);
	if (Con == None)
	{
		return;
	}

	if (!Con.bNoDrawWorld && tpp.GetStateName() == 'PlayerWaiting' && tpp.bPickedTeam
		&& tpp.PlayerReplicationInfo != None && tpp.PlayerReplicationInfo.Team != 255)
	{
		if (!Con.bCreatedRoot || Con.Root == None)
		{
			Con.CreateRootWindow(None);
			Con.bQuickKeyEnable = true;
			Con.LaunchUWindow();
			return;
		}

		Con.bQuickKeyEnable = true;
		if (!Con.Root.bWindowVisible || Con.GetStateName() == 'ThConsole')
		{
			Con.LaunchUWindow();
		}
		if (loadoutWindow == None)
		{
			Win = Con.Root.CreateWindow(class'ThPlusLoadoutWindow', 0, 0, 0, 0);
			loadoutWindow = ThLoadoutClientWindow(Win);
			loadoutWindow.OnShown();
		}
		loadoutWindow.bLeaveOnScreen = true;

		if (!loadoutWindow.bWindowVisible)
		{
			if (Con.bShowConsole)
			{
				Con.HideConsole();
			}
			loadoutWindow.ShowWindow();
			loadoutWindow.OnShown();
		}
		bShowingLoadoutWindow = true;

		if (ThConsole(Con) != None && Con.GetStateName() == 'UWindow')
		{
			ThConsole(Con).LoadoutWindow = loadoutWindow;
		}
	}
	else
	{
		if (bShowingLoadoutWindow)
		{
			if (loadoutWindow != None && loadoutWindow.bWindowVisible)
			{
				loadoutWindow.Close();
				loadoutWindow.GotoLoadoutState(
						class'ThPlusLoadoutWindow'.Default.LS_SelectLoadout);
			}
			bShowingLoadoutWindow = false;
		}
	}
}

//=============================================================================
// loadout window details

simulated function PaintCost(canvas C, int ItemCost, int ItemGemCost, float PosX, float PosY,
							 bool bRightAlign, bool bHide, bool bShowZero)
{
	local float TextW, TextH, CoinIconSize, GemIconSize;

	if (bHide)
	{
		return;
	}

	C.DrawColor = WhiteColor;
	C.Font = MyFontSmall;

	CoinIconSize = FMax(14.0, 16.0 * scaleY);
	GemIconSize = FMax(14.0, 15.0 * scaleY);

	if (bRightAlign)
	{
		if (ItemCost > 0 || bShowZero)
		{
			C.Style = 3;
			C.TextSize(""$ItemCost, TextW, TextH);
			C.SetPos(PosX - TextW, PosY);
			C.DrawText(""$ItemCost);

			C.Style = 2;
			C.SetPos(PosX - TextW - 3.0 * scaleY - CoinIconSize, PosY + 0.5 * (TextH - CoinIconSize));
			C.DrawIcon(texture'CoinIcon', CoinIconSize / 64.0);

			PosX -= (TextW + 3.0 * scaleY + CoinIconSize + 7.0 * scaleY);
		}

		if (ItemGemCost > 0 || bShowZero)
		{
			C.Style = 3;
			C.TextSize(""$ItemGemCost, TextW, TextH);
			C.SetPos(PosX - TextW, PosY);
			C.DrawText(""$ItemGemCost);

			C.Style = 2;
			C.SetPos(PosX - TextW - 3.0 * scaleY - GemIconSize, PosY + 0.5 * (TextH - GemIconSize));
			C.DrawIcon(texture'DiamondIcon', GemIconSize / 64.0);
		}
	}
	else
	{
		if (ItemGemCost > 0 || bShowZero)
		{
			C.Style = 3;
			C.TextSize(""$ItemGemCost, TextW, TextH);
			C.SetPos(PosX + GemIconSize + 3.0 * scaleY, PosY);
			C.DrawText(""$ItemGemCost);

			C.Style = 2;
			C.SetPos(PosX, PosY + 0.5 * (TextH - GemIconSize));
			C.DrawIcon(texture'DiamondIcon', GemIconSize / 64.0);

			PosX += GemIconSize + 3.0 * scaleY + TextW + 7.0 * scaleY;
		}

		if (ItemCost > 0 || bShowZero)
		{
			C.Style = 3;
			C.TextSize(""$ItemCost, TextW, TextH);
			C.SetPos(PosX + CoinIconSize + 3.0 * scaleY, PosY);
			C.DrawText(""$ItemCost);

			C.Style = 2;
			C.SetPos(PosX, PosY + 0.5 * (TextH - CoinIconSize));
			C.DrawIcon(texture'CoinIcon', CoinIconSize / 64.0);
		}
	}
}

simulated function PaintTooltip(canvas C, float PosX, float PosY, string ItemName, string ItemDesc,
								optional bool bPurchase, optional int ItemCost, optional int ItemGemCost)
{
	local float ContentsW, ContentsH, FillW, FillH, Pad;

	// draw invisible to measure size
	PaintTooltipContents(C, 0.0, 0.0, true, ContentsW, ContentsH,
						 ItemName, ItemDesc, bPurchase, ItemCost, ItemGemCost);

	Pad = 6.0 * scaleY;
	FillW = ContentsW + 2.0 * Pad;
	FillH = ContentsH + 2.0 * Pad;
	PosX = FMin(PosX, float(C.SizeX) - FillW);
	PosY = FMin(PosY, float(C.SizeY) - FillH);

	// draw black background
	C.Style = 1;
	C.DrawColor = WhiteColor;
	C.SetPos(PosX, PosY);
	C.DrawTile(texture'BlackTexture', FillW, FillH, 0.0, 0.0, 32.0, 32.0);

	PaintTooltipContents(C, PosX + Pad, PosY + Pad, false, ContentsW, ContentsH,
						 ItemName, ItemDesc, bPurchase, ItemCost, ItemGemCost);
}

simulated function PaintTooltipContents(canvas C, float PosX, float PosY, bool bHide,
										out float Width, out float Height, string ItemName,
										string ItemDesc, optional bool bPurchase,
										optional int ItemCost, optional int ItemGemCost)
{
	local float OldPosY, TextW, TextH, SerifTextW, SerifTextH, WrappedTextH;
	local byte TextStyle, IconStyle;
	local string MouseActionText;

	OldPosY = PosY;
	if (!bHide)
	{
		TextStyle = 3;
		IconStyle = 2;
	}

	// draw item name
	C.Style = TextStyle;
	C.DrawColor = WhiteColor;
	C.Font = MyFontMedium;
	C.SetPos(PosX, PosY);
	C.TextSize(ItemName, TextW, TextH);
	C.DrawText(ItemName);
	Width = FMax(200.0 * scaleY, TextW);
	PosY += TextH;

	// draw item description
	C.DrawColor = TrueSilverColor;
	C.Font = SansFontTiny;
	PaintWrappedText(C, PosX, PosY, ItemDesc, Width, WrappedTextH);
	PosY += TextH + WrappedTextH;

	// draw mouse icon
	C.Style = IconStyle;
	C.DrawColor = WhiteColor;
	C.Font = MyFontSmall;
	C.TextSize(" ", SerifTextW, SerifTextH);
	C.SetPos(PosX, PosY);
	C.DrawTile(texture'LeftMouseIcon', SerifTextH, SerifTextH, 0.0, 0.0, 64.0, 64.0);

	// draw mouse action text
	if (bPurchase)
	{
		MouseActionText = "to purchase";
	}
	else
	{
		MouseActionText = "to sell item";
	}
	C.Style = TextStyle;
	C.DrawColor = TrueSilverColor;
	C.Font = SansFontTiny;
	C.TextSize(MouseActionText, TextW, TextH);
	C.SetPos(PosX + SerifTextH + 3.0 * scaleY, PosY + 0.5 * (SerifTextH - TextH));
	C.DrawText(MouseActionText);
	Width = FMax(Width, TextW);

	// draw cost
	if (bPurchase)
	{
		PosX += Width - 5.0 * scaleY;
		PaintCost(C, ItemCost, ItemGemCost, PosX, PosY, true, bHide, false);
	}

	PosY += SerifTextH;
	Height = PosY - OldPosY;
}

//=============================================================================
// track changes to health, weapon, selected item, loot, and view rotation

simulated function TrackHUDChanges()
{
	local bool bWeaponChanged, bPickupChanged;
	local float ProjectedHealth;
	local int CurrentHealthIcons, CurrentSmallHealthIcons, CurrentLoot;
	local ThieveryWeapon CurrentWeapon;
	local ThieveryAmmo CurrentAmmo;
	local class<ThieveryProjectile> CurrentProjectileClass;
	local class<ThieveryPickup> CurrentPickupClass;

	// check health
	CurrentHealthIcons = int(float(tpp.Health) / tpp.MaxHealth * 22.0);
	CurrentHealthIcons = Clamp(CurrentHealthIcons, int(tpp.Health > 0), 22);
	ProjectedHealth = FMin(tpp.nWaitingForHealth + tpp.Health, tpp.MaxHealth);
	CurrentSmallHealthIcons = int(ProjectedHealth / tpp.MaxHealth * 22.0);
	bHealthChanged = (CurrentHealthIcons != LastHealthIcons
					  || CurrentHealthIcons != CurrentSmallHealthIcons);
	if (bHealthChanged)
	{
		LastHealthIcons = CurrentHealthIcons;
		LastSmallHealthIcons = CurrentSmallHealthIcons;
		LastHealthTime = Level.TimeSeconds;
	}

	// check weapon
	if (tpp.Weapon != None)
	{
		CurrentWeapon = ThieveryWeapon(tpp.Weapon);
	}
	if (CurrentWeapon != None && ThieveryAmmo(CurrentWeapon.AmmoType) != None)
	{
		CurrentAmmo = ThieveryAmmo(CurrentWeapon.AmmoType);
		CurrentProjectileClass = CurrentAmmo.Default.ProjectileClass;
	}
	bWeaponChanged = (CurrentWeapon != lastWeapon
					  || CurrentProjectileClass != lastProjectileClass);
	if (bWeaponChanged)
	{
		lastWeapon = CurrentWeapon;
		lastProjectileClass = CurrentProjectileClass;
		lastWeaponSwitchTime = Level.TimeSeconds;
	}

	// check selected item
	if (tpp.ClientSelectedItem != None)
	{
		CurrentPickupClass = ThieveryPickup(tpp.ClientSelectedItem).Class;
	}
	bPickupChanged = (CurrentPickupClass != LastPickupClass);
	if (bPickupChanged)
	{
		LastPickupClass = CurrentPickupClass;
		LastPickupTime = Level.TimeSeconds;
	}

	// did health, weapon, or selected item change?
	if (bHealthChanged || bWeaponChanged || bPickupChanged)
	{
		LastImportantChangeTime = Level.TimeSeconds;
	}

	// check loot
	if (tppPRI.Team == 0)
	{
		CurrentLoot = tpp.Loot;
	}
	else
	{
		CurrentLoot = tpp.ReturnedLoot;
	}
	if (CurrentLoot != LastLoot)
	{
		LastLootTime = Level.TimeSeconds;
		LastLoot = CurrentLoot;
	}
	else if (frobTargetVerb == "Loot")
	{
		LastLootHoverTime = Level.TimeSeconds;
	}

	// check view rotation and if showing map screen
	if (tpp.ViewRotation.Yaw != LastYaw)
	{
		LastYaw = tpp.ViewRotation.Yaw;
		LastYawTime = Level.TimeSeconds;
	}
	else if (tpp.bShowMapScreen)
	{
		LastShowMapTime = Level.TimeSeconds;
	}
}

//=============================================================================
// show or hide hotbar, health, loot text, and compass based on tracked changes

simulated function UpdateHUDAutoHide(canvas C)
{
	local bool bShowBar, bShowHealth, bShowLoot, bShowCompass;

	// update weapon hotbar visibility
	if (class'ThieveryConfigClient'.Default.bShowWeaponHotbar && tppGRI.bClassicInventory)
	{
		if (lastWeapon == None || lastWeapon.IsA('ThWeaponNone'))
		{
			bShowBar = (Level.TimeSeconds - lastWeaponSwitchTime < ShortShowTime);
		}
		else
		{
			bShowBar = (Level.TimeSeconds - lastWeaponSwitchTime < LongShowTime);
		}
		GetAlpha(bShowBar, bLastShowBar, BarAlpha, ShowBarTime, HideBarTime);
		bLastShowBar = bShowBar;
	}
	else
	{
		bHotbarVisible = false;
		bLastShowBar = false;
		BarAlpha = 0.0;
		ShowBarTime = 0.0;
		HideBarTime = 0.0;
		HotbarY = C.ClipY;
	}

	// update health visibility
	if (class'ThPlusConfig'.Default.AutoHideHealth > 0)
	{
		if (class'ThPlusConfig'.Default.AutoHideHealth == 2 && LastHealthIcons < 22)
		{
			bShowHealth = true; // show health when below max instead of auto-hiding
		}
		else if ((LastHealthIcons < 22 || LastHealthIcons != LastSmallHealthIcons)
				 && Level.TimeSeconds - LastHealthTime < LongShowTime)
		{
			bShowHealth = true; // show health longer when taking damage or healing
		}
		else if (!bHealthChanged && LastPickupClass == None
				 && (lastWeapon == None || lastWeapon.IsA('ThWeaponNone')))
		{
			bShowHealth = (Level.TimeSeconds - LastImportantChangeTime < ShortShowTime);
		}
		else
		{
			bShowHealth = (Level.TimeSeconds - LastImportantChangeTime < LongShowTime);
		}
		GetAlpha(bShowHealth, bLastShowHealth, HealthAlpha, ShowHealthTime, HideHealthTime);
		bLastShowHealth = bShowHealth;
	}
	else
	{
		bLastShowHealth = true;
		HealthAlpha = 1.0;
		ShowHealthTime = 0.0;
		HideHealthTime = 0.0;
	}

	// update loot text visibility
	if (class'ThPlusConfig'.Default.bAutoHideLoot)
	{
		if (Level.TimeSeconds - LastLootHoverTime < ShortShowTime
			|| Level.TimeSeconds - LastLootTime < LongShowTime
			|| tpp.bShowObjectives != 0)
		{
			bShowLoot = true;
		}
		else if (LastPickupClass == None
				 && (lastWeapon == None || lastWeapon.IsA('ThWeaponNone')))
		{
			bShowLoot = (Level.TimeSeconds - FMax(lastWeaponSwitchTime, LastPickupTime) < ShortShowTime);
		}
		else
		{
			bShowLoot = (Level.TimeSeconds - FMax(lastWeaponSwitchTime, LastPickupTime) < LongShowTime);
		}
		GetAlpha(bShowLoot, bLastShowLoot, LootAlpha, ShowLootTime, HideLootTime);
		bLastShowLoot = bShowLoot;
	}
	else
	{
		bLastShowLoot = true;
		LootAlpha = 1.0;
		ShowLootTime = 0.0;
		HideLootTime = 0.0;
	}

	// update compass visibility
	if (class'ThPlusConfig'.Default.bAutoHideCompass)
	{
		if (Level.TimeSeconds - LastYawTime < ShortShowTime
			|| Level.TimeSeconds - LastShowMapTime < ShortShowTime)
		{
			bShowCompass = true;
		}
		else if (LastPickupClass == None
				 && (lastWeapon == None || lastWeapon.IsA('ThWeaponNone')))
		{
			bShowCompass = (Level.TimeSeconds - FMax(lastWeaponSwitchTime, LastPickupTime) < ShortShowTime);
		}
		else
		{
			bShowCompass = (Level.TimeSeconds - FMax(lastWeaponSwitchTime, LastPickupTime) < LongShowTime);
		}
		GetAlpha(bShowCompass, bLastShowCompass, CompassAlpha, ShowCompassTime, HideCompassTime);
		bLastShowCompass = bShowCompass;
	}
	else
	{
		bLastShowCompass = true;
		CompassAlpha = 1.0;
		ShowCompassTime = 0.0;
		HideCompassTime = 0.0;
	}
}

//=============================================================================
// map screen
//
// 1. icons and text scale correctly
// 2. option to show bots names on map
// 3. rats use a rat icon

simulated function DrawPlayerPosition(canvas C)
{
	local float PosX, PosY, SelfSize, RectX, RectY, BrightTex;
	local string Text;
	local texture Tex, LocTex;
	local int i;
	local bool bDrawText;
	local ThProjectileScoutingOrbD Orb;

	if (SketchMapInfo == None || !SketchMapInfo.bShowPlayerLocation)
	{
		return;
	}

	if (tppPRI.Team == 0)
	{
		LocTex = texture'ThiefLocationIcon';
	}
	else if (tppPRI.Team == 1)
	{
		LocTex = texture'GuardLocationIcon';
	}
	else
	{
		LocTex = texture'RatIcon';
	}

	if (SketchMapInfo.bShowTeamMates)
	{
		// show any scouting orbs
		NumScoutingOrbs = 0;
		if (tppPRI.Team == 0)
		{
			foreach AllActors(class'ThProjectileScoutingOrbD', Orb)
			{
				if (Orb.bTempDoorSpyOrb)
				{
					continue;
				}
				ScoutingOrbs[NumScoutingOrbs] = Orb;
				NumScoutingOrbs++;
				if (SketchMapInfo.LocationToPixel(Orb.Location, C, PosX, PosY))
				{
					Tex = texture'ScoutingOrbMapIcon';
					Text = "Orb #"$NumScoutingOrbs;
					DrawOnMap(C, PosX, PosY, 16.0, Tex, true, 8.0, Text);
				}
				if (NumScoutingOrbs >= 10)
				{
					break;
				}
			}
		}

		// render bots first, so players are on top
		if (class'ThieveryProModSettings'.Default.showAIOnMap)
		{
			for (i = 0; i < 16; i++)
			{
				if (tpp.TeamMate[i] != None && tpp.TeamMate[i].bIsABot
					&& SketchMapInfo.LocationToPixel(tpp.TeamMateLocation[i], C, PosX, PosY))
				{
					Text = tpp.TeamMate[i].PlayerName;
					bDrawText = class'ThPlusConfig'.Default.bShowBotNamesOnMap;
					DrawOnMap(C, PosX, PosY, 32.0, LocTex, bDrawText, 16.0, Text);
				}
			}
		}

		// render players
		for (i = 0; i < 16; i++)
		{
			if (tpp.TeamMate[i] != None && !tpp.TeamMate[i].bIsABot
				&& SketchMapInfo.LocationToPixel(tpp.TeamMateLocation[i], C, PosX, PosY))
			{
				Text = tpp.TeamMate[i].PlayerName;
				DrawOnMap(C, PosX, PosY, 32.0, LocTex, true, 16.0, Text);
			}
		}
	}

	// render local player
	if (SketchMapInfo.LocationToPixel(tpp.Location, C, PosX, PosY))
	{
		SelfSize = 50.0 - 7.0 * Abs(Sin(Level.TimeSeconds * 4.0));
		Text = tppPRI.PlayerName;
		DrawOnMap(C, PosX, PosY, SelfSize, LocTex, true, 20.0, Text);
	}

	// render supply chest
	if (tppPRI.Team == 1 && tpp.ChestLocation.X != -1)
	{
		if (SketchMapInfo.LocationToPixel(tpp.ChestLocation, C, PosX, PosY))
		{
			Tex = texture'LootSpawner';
			Text = SecondsToTimeString(tpp.ChestResupplyCountdown);
			bDrawText = (tpp.ChestResupplyCountdown > 0);
			DrawOnMap(C, PosX, PosY, 30.0, Tex, bDrawText, 12.0, Text, !bDrawText);
		}
	}
}

simulated function DrawOnMap(canvas C, float PosX, float PosY, float TexSize,
							 texture Tex, bool bDrawText, float TextOffset,
							 string Text, optional bool bBright)
{
	AdjustScreenPositionToCenteredWidescreen(C, PosX, PosY);
	PosX -= 16.0 * (0.8 * scaleY);
	PosY -= 16.0 * (0.8 * scaleY);
	C.Reset();
	if (bBright)
	{
		C.DrawColor = WhiteColor;
	}
	C.CurX = PosX - (0.5 * TexSize) * (0.8 * scaleY);
	C.CurY = PosY - (0.5 * TexSize) * (0.8 * scaleY);
	C.DrawRect(Tex, TexSize * (0.8 * scaleY), TexSize * (0.8 * scaleY));
	if (bDrawText)
	{
		C.Font = MapFont;
		DrawNamePlate(C, PosX, PosY + TextOffset * (0.8 * scaleY), 0, 0, 0, Text);
	}
}

simulated function DrawNamePlate(canvas C, float PosX, float PosY,
								 int R, int G, int B, string Text)
{
	local float TextW, TextH, PlateScale, TrimWidth, RectX, RectY;

	C.TextSize(Text, TextW, TextH);
	PlateScale = TextH / plateFontBaseSize;
	Text = TrimText(C, Text, 1.1 * plateLettersWidth * PlateScale);
	C.TextSize(Text, TextW, TextH);

	C.DrawColor = WhiteColor;
	C.CurX = PosX - 0.5 * plateWidth * PlateScale;
	C.CurY = PosY + plateHeight * PlateScale * (0.8 * plateYOffset);
	RectX = plateWidth * PlateScale;
	RectY = plateHeight * PlateScale;
	C.DrawRect(texture'NameBanner', RectX, RectY);

	C.DrawColor = class'TInfo'.static.GetColor(R, G, B);
	C.CurX = PosX - 0.5 * TextW;
	C.CurY = PosY;
	C.DrawText(Text);
}

//=============================================================================
// objectives screen
//
// 1. icons and text scale correctly (retains 4:3 layout for legibility)
// 2. merged ThieveryThiefMatchHUD changes

simulated function DisplayObjectives(canvas C)
{
	local TObjectiveBase TBase;
	local float TextW, WrappedTextH, SingleTextH, YPosition, Offset43X, OldClipX;
	local int i, j, NumObjectives;
	local byte StatusNum[32], TargetTeam;
	local string Text[32], IconName;
	local texture IconTex;
	local font MyFont[3];
	local bool bDrawObjectives;

	MyFont[0] = MyFontLarge;
	MyFont[1] = MyFontMedium;
	MyFont[2] = MyFontSmall;

	C.Reset();
	DrawWidescreenImage(C, "ThMenu.NoiseVignette", 0.0);
	C.Style = 3;
	C.DrawColor = WhiteColor;
	C.Font = MyFontLarge;

	// draw objectives header
	if (tppGRI.bThiefmatch)
	{
		TargetTeam = 0;
		DrawTextCentred(C, Level.Title, 70.0);
	}
	else
	{
		if (tppPRI.Team == 255)
		{
			TargetTeam = byte(tpp.bShowObjectives != 1);
			DrawTextCentred(C, TeamName[TargetTeam]$"' Objectives", 70.0);
		}
		else
		{
			TargetTeam = tppPRI.Team;
			if (tpp.bShowObjectives == 1)
			{
				DrawYouAreOnTeamText(C);
				DrawTextCentred(C, "Location: "$Level.Title, 100.0);
			}
			else
			{
				TargetTeam = 1 - TargetTeam;
				C.DrawColor = C.Default.DrawColor;
				DrawTextCentred(C, TeamName[TargetTeam]$"' Objectives", 70.0);
			}
		}
	}

	// find objectives
	foreach AllActors(class'TObjectiveBase', TBase)
	{
		if (tppGRI.bThiefmatch)
		{
			if (TBase.IsA('TObjectiveBaseThiefMatch') && tppPRI.Team != 255
				&& TObjectiveBaseThiefMatch(TBase).PlayerID == tppPRI.PlayerID)
			{
				break;
			}
		}
		else
		{
			if (!TBase.IsA('TObjectiveBaseThiefMatch') && TBase.TeamNo == TargetTeam)
			{
				break;
			}
		}
	}
	if (TBase != None)
	{
		for (i = 0; i < 32; i++)
		{
			if ((TBase.Get_bInUse(i)) && (!TBase.Get_bHidden(i)))
			{
				StatusNum[NumObjectives] = TBase.Get_Status(i);
				Text[NumObjectives] = TBase.Get_FullDescription(i);
				NumObjectives++;
			}
		}
	}

	// no objectives found, draw a default one
	if (NumObjectives == 0)
	{
		C.DrawColor = class'TInfo'.static.GetColor(C.DrawColor.R, 0, 0);
		if (!tppGRI.bThiefmatch)
		{
			if (tppPRI.Team == 255)
			{
				TargetTeam = 1 - byte(tpp.bShowObjectives != 1);
			}
			else
			{
				TargetTeam = 1 - tppPRI.Team;
				if (tpp.bShowObjectives != 1)
				{
					TargetTeam = 1 - TargetTeam;
				}
			}
		}
		DrawTextCentred(C, "Kill or KO all "$TeamName[TargetTeam]$".", 340.0);
		return;
	}

	// check font sizes, then draw objectives
	Offset43X = (C.ClipX - C.ClipY * 4.0 / 3.0) * 0.5; // centered 4:3
	C.OrgX = 160.0 * scaleY + Offset43X;
	OldClipX = C.ClipX;
	C.ClipX = 784.0 * scaleY;
	for (i = 0; i < ArrayCount(MyFont); i++)
	{
		if (i + 1 == ArrayCount(MyFont))
		{
			bDrawObjectives = true; // give up and use smallest font
		}
		C.Font = MyFont[i];
		YPosition = 166.4 * scaleY;
		for (j = 0; j < NumObjectives; j++)
		{
			if (bDrawObjectives)
			{
				C.SetPos(0.0 - 48.0 * scaleY, YPosition);
				IconName = "ThieveryMod.ObjectiveIcon"$StatusNum[j];
				IconTex = texture(DynamicLoadObject(IconName, class'Texture'));
				C.DrawIcon(IconTex, 1.6 * scaleY);
				C.SetPos(0.0, YPosition - 6.4 * scaleY);
				C.DrawText(Text[j]);
			}
			C.StrLen(Text[j], TextW, WrappedTextH);
			C.TextSize(" ", TextW, SingleTextH);
			YPosition += WrappedTextH + SingleTextH;
		}
		if (bDrawObjectives)
		{
			break; // finished drawing
		}
		if (YPosition - SingleTextH <= C.ClipY - 275.0 * scaleY)
		{
			bDrawObjectives = true; // text size is good, go back and draw it
			i--;
		}
	}
	C.OrgX = C.Default.OrgX;
	C.ClipX = OldClipX;
	C.Font = MyFontMedium; // stay consistent with DrawHUD()
}

simulated function DrawTextCentred(canvas C, string Text, float Y)
{
	local float TextW, TextH;

	C.TextSize(Text, TextW, TextH);
	C.SetPos(0.5 * (C.ClipX - TextW), Y * 0.8 * scaleY);
	C.DrawText(Text);
}

//=============================================================================
// crosshair
//
// 1. scales correctly
// 2. hidden if frob item offset is centered or player is ordering a bot

simulated function DrawCrossHair(canvas C, int X, int Y)
{
	local float IconScale, XL, YL;
	local texture Tex;

	if (IsFrobItemAtTargetAndCentered() || tpp.OrderingBot != None)
	{
		return;
	}

	C.Reset();
	C.Style = 3;

	if (frobTargetIcon != None)
	{
		C.DrawColor = frobTargetIconColor;
		Tex = frobTargetIcon;
		IconScale = frobTargetIconScale * scaleY;
	}
	else
	{
		C.DrawColor = UnitColor * CurrentCrossHairBrightness;
		Tex = texture'CytheCrosshair7';
		IconScale = FMax(1.0, scaleY);
	}

	if (tpp.bFrobTargetIsImportant)
	{
		C.DrawColor = class'TInfo'.static.GetColor(255, 32, 32);
		IconScale *= 1.3;
	}

	XL = IconScale * Tex.USize;
	YL = IconScale * Tex.VSize;
	C.SetPos(0.5 * (C.ClipX - XL), 0.5 * (C.ClipY - YL));
	C.DrawRect(Tex, XL, YL);
}

simulated function bool IsFrobItemAtTargetAndCentered()
{
	return (class'ThPlusConfig'.Default.FrobItemOffset == 1 // at crosshair
			&& tpp.SelectedItemOffsetX == -1000.0
			&& tpp.SelectedItemOffsetY == -750.0);
}

//=============================================================================
// frob tooltip
//
// 1. no longer overlaps potion effects text
// 2. hidden if player is ordering a bot

simulated function DrawInteractionTooltip(canvas C)
{
	local float TooltipW, TooltipH, Pad, XL, YL, XMax, X, Y;

	if (tpp.FrobTarget == None || tpp.OrderingBot != None
		|| !class'ThieveryConfigClient'.Default.bShowInteractionTooltip)
	{
		return;
	}

	C.Reset();

	// get tooltip width and height
	C.Style = 0;
	DrawInteractionTooltipText(C, 0.0, 0.0, frobTargetName, frobTargetVerb, TooltipW, TooltipH);

	Pad = 5.0 * scaleY;
	XL = TooltipW + 2.0 * Pad;
	YL = TooltipH + 2.0 * Pad;
	X = 0.5 * C.ClipX + 280.0 * scaleY;
	Y = 0.5 * C.ClipY - 100.0 * scaleY;

	// leave room for potion effects text and some padding
	if (bShowingEffects)
	{
		XMax = C.ClipX - 140.0 * scaleY - 24.0 * scaleY - XL;
		X = FMin(X, XMax);
	}

	C.Style = 4;
	C.DrawColor = WhiteColor;
	C.SetPos(X - Pad, Y - Pad);
	C.DrawRect(texture'GreyBackground', XL, YL);

	C.Style = 3;
	DrawInteractionTooltipText(C, X, Y, frobTargetName, frobTargetVerb, TooltipW, TooltipH);
}

//=============================================================================
// misc text for scoreboards
//
// 1. merged ThProHud changes
// 2. corrected scoreboard alignment
// 3. uses DrawLabelAndValue() to draw text

simulated function DisplayTeamSizes(canvas C)
{
	local int i;
	local float PosX, PosY, Pad, TeamPosX[2], TeamOffsetX;
	local float PlayersTextW, LivesTextW, PlayersNumW, LivesNumW, TotalW, TextH;
	local string Waves, Players[2], Lives[2];
	local ThProGRI tppProGRI;
	local bool bPro;

	tppProGRI = ThProGRI(tppGRI);
	bPro = (tppProGRI != None && tppProGRI.usingWaves);

	Pad = 12.0 * scaleY;
	PosY = C.ClipY - 65.0 * scaleY;
	C.Font = SansFontSmall;
	C.TextSize("Players: ", PlayersTextW, TextH);
	C.TextSize("Lives: ", LivesTextW, TextH);
	C.Font = SansFontMedium;

	if (tpp.GetStateName() == 'PlayerWaiting')
	{
		TeamOffsetX = 210.0 * scaleY;
	}
	else
	{
		TeamOffsetX = 256.0 * scaleY;
	}

	// thieves
	if (bPro)
	{
		PosX = 0.5 * C.ClipX - TeamOffsetX;
		Waves = (tppProGRI.wave + 1)$" of "$(tppProGRI.totalWaves + 1);
		DrawLabelAndValue(C, PosX, PosY, "Wave: ", Waves, true);
	}
	else
	{
		Players[0] = string(tppGRI.CurrentThiefCount);
		Lives[0] = string(tppGRI.MaxThiefCount);
		TeamPosX[0] = 0.5 * C.ClipX - TeamOffsetX;
	}

	// guards
	Players[1] = string(tppGRI.CurrentGuardCount);
	Lives[1] = string(tppGRI.MaxGuardCount);
	TeamPosX[1] = 0.5 * C.ClipX + TeamOffsetX;

	// draw text
	for (i = int(bPro); i < 2; i++)
	{
		C.TextSize(Players[i], PlayersNumW, TextH);
		C.TextSize(Lives[i], LivesNumW, TextH);
		TotalW = PlayersTextW + PlayersNumW + Pad + LivesTextW + LivesNumW;
		PosX = TeamPosX[i] - 0.5 * TotalW;
		DrawLabelAndValue(C, PosX, PosY, "Players: ", Players[i], false);
		PosX += PlayersTextW + PlayersNumW + Pad;
		DrawLabelAndValue(C, PosX, PosY, "Lives: ", Lives[i], false);
	}
}

simulated function DrawLabelAndValue(canvas C, float PosX, float PosY,
									 string Label, string Value, bool bCenter)
{
	local float SmallTextW, SmallTextH, MediumTextW, MediumTextH;

	C.Font = SansFontSmall;
	C.TextSize(Label, SmallTextW, SmallTextH);
	C.Font = SansFontMedium;
	C.TextSize(Value, MediumTextW, MediumTextH);

	if (bCenter)
	{
		PosX -= 0.5 * (SmallTextW + MediumTextW);
	}

	// draw label
	C.DrawColor = class'TInfo'.static.GetColor(169, 169, 157);
	C.Font = SansFontSmall;
	C.SetPos(PosX, PosY);
	C.DrawText(Label);

	// draw value
	C.DrawColor = class'TInfo'.static.GetColor(255, 255, 233);
	C.Font = SansFontMedium;
	C.SetPos(PosX + SmallTextW, PosY + 0.5 * (SmallTextH - MediumTextH));
	C.DrawText(Value);
}

//=============================================================================
// weapon hotbar
//
// 1. works for client players
// 2. no longer overlaps lightgem and compass
// 3. different widths for thieves and guards
// 4. slim hotbar option
// 5. shows correct weapon in inventory group "2"
// 6. visuals adjusted for better legibility
// 7. uses scaled fonts

simulated function DrawClassicInventoryHotBar(canvas C)
{
	local float TextW, TextH, HotbarW, HotbarH, TileScale, PosX, PosY;
	local int i;
	local texture Tex;

	if (tpp.HeldItem != None || tpp.bUsingScope || tpp.Health <= 0 || !tppGRI.bClassicInventory)
	{
		return;
	}

	C.Reset();
	C.DrawColor = WeaponHotbarColor * (0.6 + 0.4 * BarAlpha);
	C.Font = HotbarFont;
	C.TextSize(" ", TextW, TextH);

	// limit hotbar scale to avoid overlapping lightgem and compass
	HotbarW = HotbarWidth[tppPRI.Team] * 0.5 * scaleY;
	HotbarAutoScale = FMin(HealthFullW / HotbarW, WeaponHotbarScale);
	if (HotbarAutoScale == 0.0)
	{
		return;
	}

	TileScale = 0.5 * scaleY * HotbarAutoScale;
	if (class'ThPlusConfig'.Default.bUseSlimHotbar)
	{
		Tex = SlimBarTex[tppPRI.Team];
		HotbarH = (117.0 * TileScale) + (1.2 * TextH);
	}
	else
	{
		Tex = HotbarTex[tppPRI.Team];
		HotbarH = (164.0 * TileScale) + (1.2 * TextH);
	}
	HotbarY = C.ClipY - EaseOut(0.0, HotbarH, BarAlpha);

	bHotbarVisible = (bLastShowBar || BarAlpha > 0.0 || ShowBarTime > 0.0
					  || HideBarTime > 0.0 || HotbarY < C.ClipY);

	if (BarAlpha > 0.0)
	{
		PosY = C.ClipY - EaseOut(0.0, 167.0 * TileScale, BarAlpha);
		DrawStretchedTexture(C, 0.0, PosY, 1024.0 * TileScale, 256.0 * TileScale, Tex);

		PosX = 20.0 * TileScale;
		PosY += 67.0 * TileScale;
		for (i = 0; i < TotalHotkeys[tppPRI.Team]; i++)
		{
			DrawHotbarSlot(C, PosX, PosY, i + 1);
		}
	}
}

// draw one slot for the weapon hotbar
simulated function DrawHotbarSlot(canvas C, float X, float Y, byte Hotkey)
{
	local float dT, SelectAlpha, TileScale, SlotSize, Fill, PosX, PosY, Size, TextW, TextH;
	local bool bIsSelected;
	local MeshInfo DispMesh;
	local ThieveryWeapon SlotWeapon;
	local class<ThieveryProjectile> SlotProjectileClass;
	local int SlotAmmoAmount;
	local string SlotName;

	GetSlotInfo(Hotkey, SlotWeapon, SlotProjectileClass, SlotAmmoAmount, SlotName);

	dT = Level.TimeSeconds - lastWeaponSwitchTime;
	SelectAlpha = FMin(1.0, dT / 0.1);
	TileScale = 0.5 * scaleY * HotbarAutoScale;
	SlotSize = 100.0 * TileScale;
	X += float(Hotkey - 1) * SlotSize;

	C.Reset();
	C.Style = 3;
	C.Font = HotbarFont;

	// is the weapon in this slot the currently selected one?
	bIsSelected = (SlotWeapon != None && SlotWeapon == tpp.Weapon
				   && (SlotWeapon.bMeleeWeapon
					   || (SlotProjectileClass != None
						   && SlotProjectileClass == lastProjectileClass)));

	// draw effects
	if (bIsSelected)
	{
		Fill = 16.0 + 16.0 * (1.0 - SelectAlpha);
		PosX = X + 4.0 * TileScale * (1.0 - SelectAlpha);
		PosY = Y + 4.0 * TileScale * (1.0 - SelectAlpha);
		Size = SlotSize - 8.0 * TileScale * (1.0 - SelectAlpha);

		// yellow fill
		C.DrawColor = UnitColor * (Fill * BarAlpha);
		DrawStretchedTexture(C, PosX, PosY, Size, Size, texture'BarSlotFill');

		// outline
		C.DrawColor = WhiteColor * BarAlpha;
		DrawStretchedTexture(C, PosX, PosY, Size, Size, texture'sPocket_0');

		if (dT < 0.3)
		{
			// highlight
			C.DrawColor = WhiteColor * (1.0 - dT / 0.3);
			DrawStretchedTexture(C, PosX, PosY, Size, Size, texture'sPocket_1');
		}
	}

	// draw mesh
	if (SlotWeapon != None && (SlotWeapon.bMeleeWeapon || SlotAmmoAmount > 0))
	{
		DispMesh = GetHotbarMesh(SlotWeapon, SlotProjectileClass);
		DispMesh.Glow *= 0.5 + 0.5 * BarAlpha;
		PosX = X + 0.5 * SlotSize;
		PosY = Y + 0.5 * SlotSize;
		if (bIsSelected)
		{
			DispMesh.Glow = 2.0;
			PosY -= 6.0 * TileScale * SelectAlpha;
		}
		DrawHUDMesh(C, DispMesh, PosX, PosY, SlotSize);
	}

	// draw hotkey
	if (bIsSelected)
	{
		C.DrawColor = LootColor * BarAlpha;
	}
	else
	{
		C.DrawColor = TrueSilverColor * BarAlpha;
	}
	C.TextSize(string(Hotkey), TextW, TextH);
	C.SetPos(X + 12.0 * TileScale, Y + SlotSize - 7.0 * TileScale - TextH);
	C.DrawText(string(Hotkey));

	// draw ammo
	if (SlotAmmoAmount > 0)
	{
		C.DrawColor = TrueSilverColor * BarAlpha;
		C.TextSize("x"$SlotAmmoAmount, TextW, TextH);
		C.SetPos(X + SlotSize - 17.0 * TileScale - TextW, Y + 13.0 * TileScale);
		C.DrawText("x"$SlotAmmoAmount);
	}

	// draw name
	if (bIsSelected && SlotName != "")
	{
		C.DrawColor = TrueSilverColor * (BarAlpha * SelectAlpha);
		C.TextSize(SlotName, TextW, TextH);
		C.CurX = FMax(8.0 * TileScale, X + 0.5 * (SlotSize - TextW));
		if (class'ThPlusConfig'.Default.bUseSlimHotbar)
		{
			C.CurY = Y - 17.0 * TileScale - 1.1 * TextH;
		}
		else
		{
			C.CurY = Y - 64.0 * TileScale - 1.1 * TextH;
		}
		C.CurY += 4.0 * TileScale * (1.0 - SelectAlpha);
		C.DrawText(SlotName);
	}
}

simulated function GetSlotInfo(byte Hotkey, out ThieveryWeapon SlotWeapon,
							   out class<ThieveryProjectile> SlotProjectileClass,
							   out int SlotAmmoAmount, out string SlotName)
{
	local Inventory Inv;
	local ThieveryWeapon Weap;
	local ThieveryAmmo WeapAmmo;
	local int i;

	for (Inv = tpp.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		if (Inv.IsA('ThieveryWeapon'))
		{
			Weap = ThieveryWeapon(Inv);
			if (Weap.bMeleeWeapon && Weap.InventoryGroup == Hotkey)
			{
				if (Hotkey == 2)
				{
					TrackSharedGroup(Inv, Weap);
				}
				SlotWeapon = Weap;
				SlotName = Weap.GetLoadoutTitle();
				return;
			}

			for (i = 0; i < 16; i++)
			{
				if (Weap.ProjectileInventoryGroup[i] == Hotkey)
				{
					WeapAmmo = GetInventoryAmmo(Weap.AmmoClasses[i]);
					if (WeapAmmo != None && WeapAmmo.AmmoAmount > 0)
					{
						SlotWeapon = Weap;
						SlotProjectileClass = WeapAmmo.Default.ProjectileClass;
						SlotAmmoAmount = WeapAmmo.AmmoAmount;
						SlotName = SlotProjectileClass.Default.ItemName;
					}
					return;
				}
			}
		}
	}
}

// get correct weapon when inventory group "2" is shared by two weapons. weapon
// switching is handled by ThPlusPawn.TrackSharedGroup()
simulated function TrackSharedGroup(Inventory Inv, out ThieveryWeapon WeaponA)
{
	local ThieveryWeapon WeaponB;

	for (Inv = Inv.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		if (Inv.IsA('ThieveryWeapon') && ThieveryWeapon(Inv).InventoryGroup == 2)
		{
			WeaponB = ThieveryWeapon(Inv);
			if (tpp.Weapon.InventoryGroup == 2)
			{
				SharedGroupWeapon = ThieveryWeapon(tpp.Weapon);
				if (ThieveryWeapon(tpp.Weapon) == WeaponB)
				{
					WeaponA = WeaponB;
				}
			}
			else
			{
				if (SharedGroupWeapon != WeaponA && SharedGroupWeapon != WeaponB)
				{
					SharedGroupWeapon = WeaponA;
				}
				WeaponA = SharedGroupWeapon;
			}
			return;
		}
	}
}

simulated function ThieveryAmmo GetInventoryAmmo(class<Ammo> AmmoClass)
{
	local Inventory Inv;

	for (Inv = tpp.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		if (Inv.Class == AmmoClass)
		{
			return ThieveryAmmo(Inv);
		}
	}
	return None;
}

//=============================================================================
// compass
//
// 1. scales correctly
// 2. textures no longer disappear at certain angles
// 3. auto-hide option

simulated function Compass(canvas C)
{
	local float OldClipX, OldClipY, X, XL, YL, PosY;
	local int i;

	OldClipX = C.ClipX;
	OldClipY = C.ClipY;

	C.Reset();
	C.Style = 3;

	CompassWidth = 102.4 * scaleY;
	CompassHeight = 25.6 * scaleY;
	C.SetOrigin(0.5 * (C.ClipX - CompassWidth), C.ClipY - CompassHeight);
	C.SetClip(CompassWidth, CompassHeight);

	X = 204.8 * (1.0 - ((tpp.ViewRotation.Yaw + 4808) & 65535) / 65535.0);
	XL = 204.8 * scaleY;
	YL = 25.6 * scaleY;

	if (class'ThPlusConfig'.Default.bAutoHideCompass)
	{
		C.DrawColor *= CompassAlpha;
		PosY = EaseOut(CompassHeight, 0.0, CompassAlpha);
	}

	if (CompassAlpha > 0.0)
	{
		for (i = 0; i < 2; i++)
		{
			C.SetPos((X - i * 204.8) * scaleY, PosY);
			C.DrawTileClipped(texture'CompassPlain', XL, YL, 0.0, 0.0, 256.0, 32.0);
		}
	}

	C.Reset();
	C.SetClip(OldClipX, OldClipY);
}

//=============================================================================
// telescope and scouting orb overlay
//
// recreated as a single large texture to avoid texture seams

simulated function DrawScopeOverlay(canvas C)
{
	C.Reset();
	C.DrawRect(texture'BlackTexture', 0.5 * C.ClipX - 512.0 * scaleY, C.ClipY);
	C.SetPos(0.5 * C.ClipX + 512.0 * scaleY, 0.0);
	C.DrawRect(texture'BlackTexture', 0.5 * C.ClipX - 512.0 * scaleY, C.ClipY);
	C.Style = 4;
	C.SetPos(0.5 * C.ClipX - 512.0 * scaleY, 0.5 * C.ClipY - 512.0 * scaleY);
	C.DrawTileClipped(texture'ScopeOverlay', 1024.0 * scaleY, 1024.0 * scaleY,
					  0.0, 0.0, 1024.0, 1024.0);
}

//=============================================================================
// health
//
// 1. scales correctly
// 2. smaller icons are now aligned properly
// 3. auto-hide option

simulated function DrawThieveryStatus(canvas C)
{
	local float PosX, PosY, HealthIconScale, HealthIconW, HealthIconSpacing;
	local float SmallHealthIconScale, SmallHealthIconW, SmallHealthIconH;
	local float SmallHealthInsetX, SmallHealthInsetY;
	local int i, j;

	if (tpp.Health <= 0)
	{
		return;
	}

	Compass(C);

	C.Reset();
	C.DrawColor = C.Default.DrawColor * (0.6 + 0.4 * HealthAlpha);

	HealthIconScale = 0.25 * scaleY;
	HealthIconW = 64.0 * HealthIconScale;
	HealthIconH = 128.0 * HealthIconScale;
	HealthFullW = (0.5 * C.ClipX) - (0.5 * CompassWidth) - (4.0 * scaleY);
	HealthIconSpacing = (HealthFullW - HealthIconW) / (0.5 + 21.0 + 0.5);
	HealthInsetX = 0.5 * HealthIconSpacing;
	HealthPaddingY = 8.0 * scaleY;
	if (class'ThieveryConfigClient'.Default.bShowWeaponHotbar
		&& tpp.HeldItem == None && !tpp.bUsingScope)
	{
		HealthInsetY = HealthIconH + EaseOut(HealthPaddingY, 0.0, BarAlpha);
	}
	else
	{
		HealthInsetY = HealthIconH + HealthPaddingY;
	}
	SmallHealthIconScale = 0.5 * HealthIconScale;
	SmallHealthIconW = 0.5 * HealthIconW;
	SmallHealthIconH = 0.5 * HealthIconH;
	SmallHealthInsetX = (0.5 * HealthIconW) - (0.5 * SmallHealthIconW);
	SmallHealthInsetY = (0.5 * HealthIconH) - (0.5 * SmallHealthIconH);

	if (class'ThieveryConfigClient'.Default.bShowWeaponHotbar
		&& tpp.HeldItem == None && !tpp.bUsingScope)
	{
		HealthY = HotbarY;
	}
	else
	{
		HealthY = C.ClipY;
	}

	if (class'ThPlusConfig'.Default.AutoHideHealth > 0)
	{
		HealthY -= EaseOut(0.0, HealthInsetY, HealthAlpha);
	}
	else
	{
		HealthY -= HealthInsetY;
	}

	if (HealthAlpha > 0.0)
	{
		// draw health icons
		PosY = HealthY;
		for (i = 0; i < LastHealthIcons; i++)
		{
			PosX = float(i) * HealthIconSpacing + HealthInsetX;
			C.SetPos(PosX, PosY);
			C.DrawIcon(texture'HealthShield2', HealthIconScale);
		}

		// draw small health icons
		PosY += SmallHealthInsetY;
		for (j = i; j < LastSmallHealthIcons; j++)
		{
			PosX = float(j) * HealthIconSpacing + HealthInsetX + SmallHealthInsetX;
			C.SetPos(PosX, PosY);
			C.DrawIcon(texture'HealthShield2', SmallHealthIconScale);
		}
	}
}

//=============================================================================
// loot text
//
// 1. scales correctly
// 2. brightness increases briefly when grabbing loot
// 3. value animates briefly
// 4. auto-hide option

simulated function DrawLoot(canvas C)
{
	local float dT, TextX, TextY, TextW, TextH, CompassOffsetX;
	local string Text;
	local color BrightColor;
	local int CurrentLoot, ChangingLoot;

	if (tpp.Health <= 0 || tpp.GetStateName() == 'PlayerWaiting')
	{
		return;
	}

	C.Reset();
	C.Style = 3;
	C.Font = MyFontSmall;

	if (tppPRI.Team == 0)
	{
		C.DrawColor = class'TInfo'.static.GetColor(182, 182, 0);
		BrightColor = class'TInfo'.static.GetColor(255, 250, 192);
		CurrentLoot = tpp.Loot;
	}
	else
	{
		C.DrawColor = class'TInfo'.static.GetColor(176, 176, 176);
		BrightColor = class'TInfo'.static.GetColor(248, 248, 248);
		CurrentLoot = tpp.ReturnedLoot;
	}

	dT = Level.TimeSeconds - LastLootTime;
	if (dT > FadeTime || LastLootTime == 0.0)
	{
		BaseLoot = CurrentLoot;
		Text = "Loot: "$CurrentLoot;
	}
	else
	{
		// increase text brightness
		C.DrawColor = C.DrawColor + ((BrightColor - C.DrawColor) * FMin(1.0, dT / 0.1));

		// animate the change in value
		if (BaseLoot != CurrentLoot)
		{
			DeltaLoot = CurrentLoot - BaseLoot;
			BaseLoot = CurrentLoot;
		}
		ChangingLoot = CurrentLoot - DeltaLoot * (1.0 - FMin(1.0, dT / FadeTime));
		Text = "Loot: "$ChangingLoot;
	}

	C.TextSize(Text, TextW, TextH);
	CompassOffsetX = 0.5 * CompassWidth + 4.0 * scaleY;
	TextX = 0.5 * C.ClipX + CompassOffsetX + 32.0 * scaleY;
	TextY = C.ClipY - HealthPaddingY - 0.5 * HealthIconH - 0.5 * TextH;

	if (class'ThPlusConfig'.Default.bAutoHideLoot)
	{
		C.DrawColor *= LootAlpha;
		TextY += EaseOut(C.ClipY - TextY, 0.0, LootAlpha);
	}

	if (LootAlpha > 0.0)
	{
		C.SetPos(TextX, TextY);
		C.DrawText(Text);
	}
}

//=============================================================================
// selected item / item wheel (lower right corner), plus extra overlay
//
// 1. item wheel rewritten to be more responsive
// 2. item wheel no longer wraps text to left side of screen
// 3. visuals adjusted for better legibility
// 4. basic selected item uses scaled font and shows hotkey if defined
// 5. frob item offset option
// 6. progress bar overlays adjusted for better legibility

simulated function DrawSelectedItem(canvas C)
{
	local Inventory Item;

	if (!tppGRI.bClassicInventory)
	{
		return;
	}

	if (tpp.ClientSelectedItem != None)
	{
		Item = tpp.ClientSelectedItem;
		if (Item.bDeleteMe || tpp.HeldItem != None)
		{
			tpp.ClientSelectedItem = None;
			Item = None;
		}
	}

	if (tpp.HeldItem != None || tpp.bUsingScope)
	{
		return;
	}

	if (class'ThieveryConfigClient'.Default.bShowItemWheel)
	{
		DrawItemWheel(C);
		if (ThieveryPickup(Item) != None)
		{
			DrawItemExtraOverlay(C, ThieveryPickup(Item));
		}
	}
	else if (ThieveryPickup(Item) != None)
	{
		DrawSelectedItemOverlay(C, ThieveryPickup(Item));
		DrawItemExtraOverlay(C, ThieveryPickup(Item));
	}
}

simulated function DrawSelectedItemOverlay(canvas C, ThieveryPickup SelectedItem)
{
	local float PosX, PosY, TextW, TextH, TextX, TextY, HotkeySize;
	local string Text, Hotkey;
	local MeshInfo DispMesh;

	C.Reset();
	C.Style = 3;
	C.DrawColor = TrueSilverColor;
	C.Font = SansFontSmall;

	// draw mesh
	PosX = C.ClipX - 90.0 * scaleY;
	PosY = C.ClipY - 90.0 * scaleY;
	ApplySelectedItemOffset(C, PosX, PosY);
	SelectedItem.ClientBecomeItem();
	DispMesh = GetItemMesh(SelectedItem);
	DrawHUDMesh(C, DispMesh, PosX, PosY, 144.0 * scaleY);

	// get hotkey
	Hotkey = GetKeyBoundTo("ThUsePickup "$SelectedItem.Class);
	HotkeySize = GetItemHotkeySize(C, Hotkey);

	// draw name
	Text = SelectedItem.HUDName;
	C.TextSize(Text, TextW, TextH);
	TextX = PosX - 0.5 * (TextW + HotkeySize);
	TextY = PosY + 42.0 * scaleY;
	C.SetPos(TextX + HotkeySize, TextY);
	C.DrawText(Text);

	// draw hotkey
	DrawItemHotkey(C, TextX, TextY, Hotkey, 1.0);

	// draw quantity
	if (SelectedItem.NumCopies > 0)
	{
		C.Style = 3;
		C.DrawColor = TrueSilverColor;
		Text = "x"$(SelectedItem.NumCopies + 1);
		C.TextSize(Text, TextW, TextH);
		C.SetPos(PosX + 48.0 * scaleY - TextW, PosY - 42.0 * scaleY);
		C.DrawText(Text);
	}
}

simulated function DrawItemWheel(canvas C)
{
	local ThieveryPickup Items[32];
	local int i, k, TotalItems, SelectedItem, WheelStart, WheelEnd;
	local float PosX, PosY, TextX, TextY, TextW, TextH;
	local float dT, TimeSinceActive, ListOffset, ItemScale, HotkeySize;
	local float ScaleAlpha, ExtraScaleAlpha, TextAlpha, GlowAlpha;
	local string Text, Hotkey;
	local bool bExpandWheel;
	local Inventory Inv;
	local MeshInfo DispMesh;

	// get usable items
	TotalItems = 1;
	for (Inv = tpp.Inventory; Inv != None; Inv = Inv.Inventory)
	{
		if (Inv == tpp.ClientSelectedItem)
		{
			SelectedItem = TotalItems;
		}
		if (Inv.IsA('ThieveryPickup') && Inv.bActivatable)
		{
			Items[TotalItems] = ThieveryPickup(Inv);
			TotalItems++;
		}
	}

	TimeSinceActive = Level.TimeSeconds - LastSelectedItemChange;
	bExpandWheel = (TimeSinceActive < WheelContractDelay && tpp.SelectedItemOffsetX == 0.0);

	// reduce offset
	if (WheelOffset != 0.0)
	{
		dT = FMin(TimeSinceActive, WheelSpinTime);
		WheelOffset = EaseOut(WheelLastOffset, 0.0, dT / WheelSpinTime);
	}

	// expand or contract item wheel
	if (bExpandWheel && WheelExtraScale < 1.5)
	{
		dT = FMin(TimeSinceActive, WheelExpandTime);
		WheelExtraScale = EaseOut(WheelLastScale, 1.5, dT / WheelExpandTime);
	}
	else if (!bExpandWheel && WheelExtraScale > 1.0)
	{
		dT = TimeSinceActive - WheelContractDelay;
		dT = FClamp(dT, 0.0, WheelContractTime);
		WheelExtraScale = EaseIn(1.5, 1.0, dT / WheelContractTime);
	}

	if (!bExpandWheel && WheelExtraScale < 1.2)
	{
		// only draw the selected item
		WheelStart = 1;
		WheelEnd = 2;
	}
	else
	{
		// draw the complete item wheel
		WheelStart = 0;
		WheelEnd = 5;
	}

	// draw item wheel
	C.Reset();
	C.Font = SansFontSmall;
	for (k = WheelStart; k < WheelEnd; k++)
	{
		i = SelectedItem + k - 1;
		while (i < 0)
		{
			i += TotalItems;
		}
		i = i % TotalItems;

		ListOffset = WheelOffset - 64.0 + float(k) * 64.0;
		ItemScale = WheelExtraScale - Abs(ListOffset) / 160.0;
		if (ItemScale > 0.2 && Items[i] != None)
		{
			ScaleAlpha = ItemScale / WheelExtraScale;
			ExtraScaleAlpha = FMax(float(k == 1), (WheelExtraScale - 1.0) / 0.5);
			GlowAlpha = FMax(float(k == 1), 0.75 * ScaleAlpha * ExtraScaleAlpha);

			// draw mesh
			PosX = C.ClipX - (30.0 + 60.0 * ItemScale) * scaleY;
			PosY = C.ClipY - (30.0 * ItemScale + 60.0 * WheelExtraScale
							  + 1.15 * ListOffset + 0.75 * ListOffset * ItemScale) * scaleY;
			if (k == 1)
			{
				ApplySelectedItemOffset(C, PosX, PosY);
			}
			Items[i].ClientBecomeItem();
			DispMesh = GetItemMesh(Items[i]);
			DispMesh.Glow *= GlowAlpha;
			DrawHUDMesh(C, DispMesh, PosX, PosY, 144.0 * scaleY * ScaleAlpha);

			if (ItemScale > 0.4)
			{
				TextAlpha = FMax(float(k == 1), 0.75 * ScaleAlpha) * ExtraScaleAlpha;

				// get hotkey
				Hotkey = GetKeyBoundTo("ThUsePickup "$Items[i].Class);
				HotkeySize = GetItemHotkeySize(C, Hotkey);

				// draw name
				C.Style = 3;
				C.DrawColor = TrueSilverColor * TextAlpha;
				Text = Items[i].getOverlayText();
				C.TextSize(Text, TextW, TextH);
				TextX = PosX - 0.5 * (TextW + HotkeySize);
				TextY = PosY + 42.0 * scaleY * ScaleAlpha;
				C.SetPos(TextX + HotkeySize, TextY);
				C.DrawTextClipped(Text);

				// draw hotkey
				DrawItemHotkey(C, TextX, TextY, Hotkey, TextAlpha);
			}
		}
	}
}

simulated function ApplySelectedItemOffset(canvas C, out float PosX, out float PosY)
{
	local float Pos;

	switch (class'ThPlusConfig'.Default.FrobItemOffset)
	{
		case 0: // above crosshair
			Pos = 0.4;
			break;
		case 2: // below crosshair
			Pos = 0.6;
			break;
		default: // at crosshair
			Pos = 0.5;
			break;
	}
	PosX -= (PosX - 0.5 * C.ClipX) * tpp.SelectedItemOffsetX / (-1000.0);
	PosY -= (PosY - Pos * C.ClipY) * tpp.SelectedItemOffsetY / (-750.0);
}

simulated function float GetItemHotkeySize(canvas C, string Hotkey)
{
	local float TextW, TextH;

	if (Hotkey == "")
	{
		return 0.0;
	}
	else if (Hotkey ~= "LeftMouse" || Hotkey ~= "MiddleMouse" || Hotkey ~= "RightMouse")
	{
		C.TextSize(" ", TextW, TextH);
		TextW = TextH * 1.4;
	}
	else
	{
		Hotkey = "["$Hotkey$"]";
		C.TextSize(Hotkey, TextW, TextH);
	}
	return (TextW + 8.0 * scaleY);
}

simulated function DrawItemHotkey(canvas C, float X, float Y, string Hotkey,
								  float Alpha, optional bool bAlignRight)
{
	local float TextW, TextH;
	local texture Tex;

	if (Hotkey == "")
	{
		return;
	}
	else if (Hotkey ~= "LeftMouse")
	{
		Tex = texture'LeftMouseIcon';
	}
	else if (Hotkey ~= "MiddleMouse")
	{
		Tex = texture'MiddleMouseIcon';
	}
	else if (Hotkey ~= "RightMouse")
	{
		Tex = texture'RightMouseIcon';
	}

	if (Tex == None)
	{
		Hotkey = "["$Hotkey$"]";
		C.TextSize(Hotkey, TextW, TextH);
	}
	else
	{
		C.TextSize(" ", TextW, TextH);
		TextH *= 1.4;
		TextW = TextH;
	}

	if (bAlignRight)
	{
		X -= TextW + 4.0 * scaleY;
	}
	Y -= 2.0 * scaleY;

	// draw background
	C.Style = 4;
	C.SetPos(X, Y);
	C.DrawRect(texture'GreyBackground', TextW + 4.0 * scaleY, TextH + 4.0 * scaleY);

	// draw hotkey
	X += 2.0 * scaleY;
	Y += 2.0 * scaleY;
	if (Tex == None)
	{
		C.Style = 3;
		C.DrawColor = LootColor * Alpha;
		C.SetPos(X, Y);
		C.DrawText(Hotkey);
	}
	else
	{
		C.Style = 2;
		C.DrawColor = WhiteColor * Alpha;
		DrawStretchedTexture(C, X, Y, TextH, TextH, Tex);
	}
}

simulated function DrawItemExtraOverlay(canvas C, ThieveryPickup SelectedItem)
{
	local float Fraction;
	local ThPickupMarkingDye Dye;
	local ThPickupTripwire Wire;

	if (SelectedItem.IsA('ThPickupMarkingDye'))
	{
		Dye = ThPickupMarkingDye(SelectedItem);
		Dye.UpdateMarkingPos(C, tpp);
		if (Level.TimeSeconds - Dye.lastHoldingTimeSeconds < 1.0)
		{
			if (!Dye.bWireComplete)
			{
				Fraction = (Dye.completedPickTimes + Dye.lastPickTime);
				Fraction /= float(Dye.SecondsToDeploy);
				Fraction = FMin(1.0, Fraction);
				DrawItemProgressBar(C, Fraction);
			}
		}
		else
		{
			Dye.DrawProgressBar(C);
		}
	}
	else if (SelectedItem.IsA('ThPickupTripwire'))
	{
		Wire = ThPickupTripwire(SelectedItem);
		Wire.UpdateTripwireModels(C, tpp);
		if (Level.TimeSeconds - Wire.lastHoldingTimeSeconds < 1.0)
		{
			if (!Wire.bWireComplete)
			{
				Fraction = (Wire.completedPickTimes + Wire.lastPickTime);
				Fraction /= float(Wire.SecondsToDeploy);
				Fraction = FMin(1.0, Fraction);
				DrawItemProgressBar(C, Fraction);
			}
		}
		else
		{
			Wire.DrawTripWireProgressBar(C);
		}
	}
}

simulated function DrawItemProgressBar(canvas C, float Fraction)
{
	local int Line, BarWidth, BarHeight, ProgressBar, EmptyBar, PosX, PosY;

	Line = Max(1, int(1.0 * scaleY + 0.5));
	BarWidth = (100.0 * scaleY + 0.5);
	BarHeight = (10.0 * scaleY + 0.5);
	ProgressBar = (BarWidth * Fraction + 0.5);
	EmptyBar = BarWidth - ProgressBar;

	PosX = (0.5 * C.ClipX - 0.5 * BarWidth + 0.5);
	switch (class'ThPlusConfig'.Default.FrobItemOffset)
	{
		case 0: // above crosshair
			PosY = (0.53 * C.ClipY + 0.5);
			break;
		case 2: // below crosshair
			PosY = (0.7 * C.ClipY + 0.5);
			break;
		default: // at crosshair
			PosY = (0.6 * C.ClipY + 0.5);
			break;
	}

	C.Reset();

	// empty part of progress bar
	C.Style = 4;
	C.SetPos(PosX + ProgressBar, PosY + Line);
	C.DrawRect(texture'GreyBackground', EmptyBar, BarHeight);

	// progress bar
	C.Style = 3;
	C.DrawColor = TrueSilverColor;
	C.SetPos(PosX, PosY + Line);
	C.DrawRect(texture'WhiteTexture', ProgressBar, BarHeight);

	// outline
	C.DrawColor = C.Default.DrawColor;
	C.SetPos(PosX - Line, PosY);
	C.DrawRect(texture'WhiteTexture', BarWidth + 2 * Line, Line);
	C.SetPos(PosX - Line, PosY + Line + BarHeight);
	C.DrawRect(texture'WhiteTexture', BarWidth + 2 * Line, Line);
	C.SetPos(PosX - Line, PosY + Line);
	C.DrawRect(texture'WhiteTexture', Line, BarHeight);
	C.SetPos(PosX + BarWidth, PosY + Line);
	C.DrawRect(texture'WhiteTexture', Line, BarHeight);
}

//=============================================================================
// held object (lower center part of screen)
//
// 1. scales correctly
// 2. fov correction
// 3. alignment fixes
// 4. uses scaled font

simulated function DrawHeldItem(canvas C)
{
	if (tpp.HeldItem != None && !tpp.bUsingScope && !tpp.bOnCrack)
	{
		if (tpp.HeldItem.IsA('ThieveryObject'))
		{
			if (tpp.HeldItem.bHidden && !tpp.bBehindView)
			{
				DrawHeldObjectOverlay(C, ThieveryObject(tpp.HeldItem));
			}
		}
		else if (tpp.HeldItem.IsA('ThieveryPickup'))
		{
			DrawSelectedItemOverlay(C, ThieveryPickup(tpp.HeldItem));
		}
	}
}

simulated function DrawHeldObjectOverlay(canvas C, ThieveryObject HeldObject)
{
	local vector Loc, PVO;
	local rotator CameraRotation, TempRot;
	local float TextW, TextH, IconScale, IconW, IconH;

	C.Reset();
	C.Style = 3;

	if (HeldObject.IsA('ThObjectCarcass'))
	{
		// draw icon
		IconScale = 0.8 * scaleY;
		IconW = 128.0 * IconScale;
		IconH = 127.0 * IconScale;
		C.SetPos(0.5 * C.ClipX - 0.5 * IconW, C.ClipY - 105.6 * scaleY - IconH);
		C.DrawTile(BodyIcon[tppPRI.Team], IconW, IconH, 0.0, 1.0, 128.0, 127.0);
	}
	else
	{
		// location
		Loc = tpp.Location + tpp.WalkBob + tpp.ForwardLean * vector(tpp.ViewRotation);
		Loc.Z += tpp.EyeHeight;
		PVO = HeldObject.PlayerViewOffset;
		if (PVO.Y == 950.0 && HeldObject.Default.PlayerViewOffset.Y == 950.0)
		{
			PVO.Y = 900.0; // center objects that default to slightly right
		}
		PVO.Y += tpp.SelectedItemOffsetX;
		PVO.Z -= tpp.SelectedItemOffsetY;
		CameraRotation = tpp.ViewRotation + tpp.GetLeanRotator();
		Loc += (0.01 * tpp.DefaultFOV / tpp.FOVAngle * PVO) >> CameraRotation;
		HeldObject.SetLocation(Loc);

		// rotation
		TempRot.Yaw = tpp.ViewRotation.Yaw + SpinMesh().Yaw;
		HeldObject.SetRotation(TempRot);

		// draw mesh
		HeldObject.DrawScale *= 0.1;
		C.DrawActor(HeldObject, false, true);
		HeldObject.DrawScale *= 10.0;
	}

	// draw name
	C.DrawColor = TrueSilverColor;
	C.Font = SansFontSmall;
	C.TextSize(HeldObject.HUDName, TextW, TextH);
	C.SetPos(0.5 * C.ClipX - 0.5 * TextW, C.ClipY - 102.4 * scaleY);
	C.DrawText(HeldObject.HUDName);
}

//=============================================================================
// weapon icon (lower left corner)
//
// matches spinning selected item (or item wheel) appearance

simulated function bool IsWeaponHotbarVisible()
{
	return true; // hack to bypass weapon's RenderHUDIcon() and DrawSpinnyHUDItem()
}

simulated function DrawWeaponIcon(canvas C)
{
	local ThieveryWeapon Weap;
	local MeshInfo DispMesh;
	local float PosX, PosY, TextW, TextH, InsetX, InsetY, LowInsetY, HighInsetY, OffsetY;
	local string Text, AmmoText;

	if (!tppGRI.bClassicInventory || tpp.Weapon == None || tpp.Weapon.IsA('ThWeaponNone')
		|| bHotbarVisible || tpp.HeldItem != None || tpp.bUsingScope || tpp.Health <= 0
		|| tpp.bShowScores || tpp.bShowObjectives != 0 || tpp.bShowMapScreen
		|| ThProjectileScoutingOrbD(tpp.ViewTarget) != None || tpp.GetStateName() == 'PlayerScouting'
		|| tpp.CurrentReadBook != None || tpp.GetStateName() == 'PlayerReadingBook'
		|| tppPRI.bIsSpectator || tppPRI.Team == 255 || tpp.GetStateName() == 'PlayerWaiting'
		|| tpp.GetStateName() == 'GameEnded' || bShowInfo || bForceScores || bHideHUD)
	{
		return;
	}

	C.Reset();
	C.Style = 3;
	C.DrawColor = TrueSilverColor;
	C.Font = SansFontSmall;
	C.TextSize(" ", TextW, TextH);

	InsetX = 90.0 * scaleY;
	LowInsetY = 90.0 * scaleY;
	HighInsetY = HealthPaddingY + TextH + 42.0 * scaleY;
	if (class'ThPlusConfig'.Default.AutoHideHealth > 0)
	{
		InsetY = EaseOut(LowInsetY, HighInsetY, HealthAlpha);
	}
	else
	{
		InsetY = HighInsetY;
	}

	// draw mesh
	Weap = ThieveryWeapon(tpp.Weapon);
	DispMesh = GetWeaponIconMesh(Weap);
	PosX = InsetX;
	PosY = HealthY - InsetY;
	if (Weap.bMeleeWeapon)
	{
		OffsetY = -22.0 * scaleY;
	}
	DrawHUDMesh(C, DispMesh, PosX, PosY + OffsetY, 144.0 * scaleY);

	// draw name
	if (Weap.bMeleeWeapon)
	{
		Text = Weap.ItemName;
	}
	else if (ThieveryAmmo(Weap.AmmoType) != None)
	{
		Text = ThieveryAmmo(Weap.AmmoType).Default.HUDName;
		if (Weap.AmmoType.AmmoAmount > 0)
		{
			if (class'ThieveryConfigClient'.Default.bShowItemWheel)
			{
				Text = Text$" ("$Weap.AmmoType.AmmoAmount$")";
			}
			else
			{
				AmmoText = "x"$Weap.AmmoType.AmmoAmount;
				C.TextSize(AmmoText, TextW, TextH);
				C.SetPos(PosX + 48.0 * scaleY - TextW, PosY - 42.0 * scaleY);
				C.DrawText(AmmoText);
			}
		}
	}
	if (Text != "")
	{
		C.TextSize(Text, TextW, TextH);
		C.SetPos(PosX - 0.5 * TextW, PosY + 42.0 * scaleY);
		C.DrawText(Text);
	}
}

//=============================================================================
// potion effects text and "BJ Arc" text (middle right part of screen)
//
// 1. uses scaled font
// 2. moved to middle right part of screen to avoid overlapping item wheel
// 3. "BJ Arc" text only shown when using ProMod's new blackjack
// 4. "BJ Arc" text uses an integer value, no more trailing zeros

simulated function DrawPotionEffects(canvas C)
{
	local int i, j;
	local float TextW, TextH;
	local string Text[6];

	if (class'ThieveryProModSettings'.Default.bUseNewBJ
		&& tpp.Weapon != None && tpp.Weapon.IsA('ThWeaponBlackjack'))
	{
		Text[i] = "BJ Arc: "$int(ThWeaponBlackjack(tpp.Weapon).CalcArc(tpp));
		i++;
	}
	if (tpp.bOnInvisibility)
	{
		Text[i] = "Invisible: "$int(tpp.InvisibilityPotionDuration);
		i++;
	}
	if (tpp.bOnSpeed)
	{
		Text[i] = "Speed: "$int(tpp.SpeedPotionDuration);
		i++;
	}
	if (tpp.bOnCatfall)
	{
		Text[i] = "Catfall: "$int(tpp.CatfallPotionDuration);
		i++;
	}
	if (tpp.bOnParalysed)
	{
		Text[i] = "Paralysed: "$int(tpp.ParalysedDuration);
		i++;
	}
	if (tpp.bOnCrackImmune)
	{
		Text[i] = "Holding Breath: "$int(tpp.breathPotionDuration);
		i++;
	}
	if (i > 0)
	{
		C.Reset();
		C.Style = 3;
		C.DrawColor = TrueSilverColor;
		C.Font = SansFontSmall;
		for (j = 0; j < i; j++)
		{
			C.TextSize(Text[j], TextW, TextH);
			C.CurX = C.ClipX - TextW - 24.0 * scaleY;
			C.CurY = 0.5 * C.ClipY - TextH * 0.75 - TextH * 1.5 * j;
			C.DrawText(Text[j]);
		}
	}
	bShowingEffects = (i > 0); // see DrawInteractionTooltip()
}

//=============================================================================
// thievery messages
//
// 1. scales correctly
// 2. fixed fonts replaced with scaled fonts

simulated function DrawThieveryMessages(canvas C)
{
	local ThieveryMessage M;

	M = tpp.MessageQueue;
	while (M != None)
	{
		if (!M.bIsSetup)
		{
			// override Scale in ThieveryMessage.Setup()
			M.MessageY *= (C.ClipY / 960.0) / Scale;
			M.ScrollingYTime *= Scale / (C.ClipY / 960.0);

			// replace fixed font with scaled font
			ConvertToScaledFont(C, M.MessageFont);
		}
		M.PostRender(C);
		M = M.Next;
	}
}

simulated function ConvertToScaledFont(canvas C, out font NewFont)
{
	local int i, FontSize;
	local string FontString;

	FontString = GetItemName(string(NewFont));
	for (i = 0; i < Len(FontString); i++)
	{
		FontSize = int(Right(FontString, Len(FontString) - i));
		if (FontSize > 0)
		{
			FontString = Left(FontString, i);
			if (FontString ~= "Carleton")
			{
				NewFont = GetScaledFont(C, "ThSerif", FontSize);
			}
			else if (FontString ~= "UTLadder")
			{
				NewFont = GetScaledFont(C, "ThClean", FontSize);
			}
			else if (FontString ~= "Sans")
			{
				NewFont = GetScaledFont(C, "ThSans", FontSize);
			}
			break;
		}
	}
}

//=============================================================================
// chat/message text
//
// same as parent but with scaled fonts and team colors (see ThPlusShoutMessage
// and its children)

simulated function DrawTypingPrompt(canvas C, console Con)
{
	local float TextW, TextH, MyOldClipX, OldClipY, OldOrgX, OldOrgY;
	local string TypingPrompt;

	MyOldClipX = C.ClipX;
	OldClipY = C.ClipY;
	OldOrgX = C.OrgX;
	OldOrgY = C.OrgY;

	C.Style = 3;
	C.DrawColor = GreenColor;
	if (class'ThieveryConfigClient'.Default.bLargeChatFont)
	{
		C.Font = LargeChatFont;
	}
	else
	{
		C.Font = SmallChatFont;
	}
	TypingPrompt = "(>"@Con.TypedStr$"_";
	C.TextSize(" ", TextW, TextH);
	C.SetOrigin(0.0, FMax(0.0, TextH * 4.0 + 8.0 + 7.0 * Scale));
	C.SetClip(760.0 * Scale, C.ClipY);
	C.SetPos(0.0, 0.0);
	C.DrawText(TypingPrompt, false);

	C.SetOrigin(OldOrgX, OldOrgY);
	C.SetClip(MyOldClipX, OldClipY);
}

simulated function DrawShortMessageQueue(canvas C)
{
	local int i, k;
	local float TextW, TextH, NumLines, OldOriginX;
	local string Text;

	bDrawFaceArea = false;
	OldOriginX = C.OrgX;
	C.Style = 3;
	if (class'ThieveryConfigClient'.Default.bLargeChatFont)
	{
		C.Font = LargeChatFont;
	}
	else
	{
		C.Font = SmallChatFont;
	}
	C.TextSize(" ", TextW, TextH);
	C.SetClip(1024.0 * Scale - 10.0, C.ClipY);

	for (i = 0; i < 4; i++)
	{
		if (ShortMessageQueue[i].Message != None)
		{
			if (ShortMessageQueue[i].Message.Default.bComplexString)
			{
				Text = ShortMessageQueue[i].Message.Static.AssembleString(
								Self,
								ShortMessageQueue[i].Switch,
								ShortMessageQueue[i].RelatedPRI,
								ShortMessageQueue[i].StringMessage);
				C.StrLen(Text, ShortMessageQueue[i].XL, ShortMessageQueue[i].YL);
			}
			else
			{
				C.StrLen(ShortMessageQueue[i].StringMessage,
						 ShortMessageQueue[i].XL, ShortMessageQueue[i].YL);
			}
			ShortMessageQueue[i].numLines = 1;
			if (ShortMessageQueue[i].YL > TextH)
			{
				ShortMessageQueue[i].numLines++;
				for (k = 2; k < 4 - i; k++)
				{
					if (ShortMessageQueue[i].YL > TextH * k)
					{
						ShortMessageQueue[i].numLines++;
					}
				}
			}

			C.SetPos(6.0, 2.0 + TextH * NumLines);
			NumLines += ShortMessageQueue[i].numLines;
			if (NumLines > 4)
			{
				break;
			}

			if (ShortMessageQueue[i].Message.Default.bComplexString)
			{
				ShortMessageQueue[i].Message.Static.RenderComplexMessage(
						C,
						ShortMessageQueue[i].XL,
						TextH,
						ShortMessageQueue[i].StringMessage,
						ShortMessageQueue[i].Switch,
						ShortMessageQueue[i].RelatedPRI,
						None,
						ShortMessageQueue[i].OptionalObject);
			}
			else
			{
				C.DrawColor = ShortMessageQueue[i].Message.Default.DrawColor;
				C.DrawText(ShortMessageQueue[i].StringMessage, false);
			}
		}
	}

	C.DrawColor = WhiteColor;
	C.SetClip(OldClipX, C.ClipY);
	C.SetOrigin(OldOriginX, C.OrgY);
}

simulated function Message(PlayerReplicationInfo PRI, coerce string Msg, name MsgType)
{
	local int i;
	local Class<LocalMessage> MessageClass;

	switch (MsgType)
	{
		case 'Say':
		case 'Shout':
			MessageClass = class'ThPlusMessageShout';
			break;
		case 'TeamSay':
		case 'Whisper':
			MessageClass = class'ThPlusMessageWhisper';
			break;
		case 'Whistle':
			MessageClass = class'ThPlusMessageWhistle';
			break;
		case 'Dead':
			MessageClass = class'ThPlusMessageDead';
			break;
		case 'TeamDead':
			MessageClass = class'ThPlusMessageTeamDead';
			break;
		case 'CriticalEvent':
			MessageClass = class'CriticalStringPlus';
			LocalizedMessage(MessageClass, 0, None, None, None, Msg);
			return;
		default:
			MessageClass = class'StringMessagePlus';
			break;
	}
	if (ClassIsChildOf(MessageClass, class'SayMessagePlus') && Msg == "")
	{
		return;
	}

	for (i = 0; i < 4; i++)
	{
		if (ShortMessageQueue[i].Message == None)
		{
			ShortMessageQueue[i].Message = MessageClass;
			ShortMessageQueue[i].Switch = 0;
			ShortMessageQueue[i].RelatedPRI = PRI;
			ShortMessageQueue[i].OptionalObject = None;
			ShortMessageQueue[i].EndOfLife = MessageClass.Default.Lifetime + Level.TimeSeconds;
			if (MessageClass.Default.bComplexString)
			{
				ShortMessageQueue[i].StringMessage = Msg;
			}
			else
			{
				ShortMessageQueue[i].StringMessage = MessageClass.Static.AssembleString(Self, 0, PRI, Msg);
			}
			return;
		}
	}

	for (i = 0; i < 3; i++)
	{
		CopyMessage(ShortMessageQueue[i], ShortMessageQueue[i + 1]);
	}
	ShortMessageQueue[3].Message = MessageClass;
	ShortMessageQueue[3].Switch = 0;
	ShortMessageQueue[3].RelatedPRI = PRI;
	ShortMessageQueue[3].OptionalObject = None;
	ShortMessageQueue[3].EndOfLife = MessageClass.Default.Lifetime + Level.TimeSeconds;
	if (MessageClass.Default.bComplexString)
	{
		ShortMessageQueue[3].StringMessage = Msg;
	}
	else
	{
		ShortMessageQueue[3].StringMessage = MessageClass.Static.AssembleString(Self, 0, PRI, Msg);
	}
}

simulated function DrawCameraFollowText(canvas C)
{
	if (PawnOwner != Owner && PawnOwner.bIsPlayer)
	{
		if (class'ThieveryConfigClient'.Default.bLargeChatFont)
		{
			C.Font = LargeChatFont;
		}
		else
		{
			C.Font = SmallChatFont;
		}
		C.bCenter = true;
		C.Style = 3;
		C.DrawColor = TrueSilverColor;
		C.SetPos(0.0, C.ClipY - 76.8 * scaleY);
		C.DrawText(LiveFeed$PawnOwner.PlayerReplicationInfo.PlayerName, true);
		C.bCenter = false;
		C.DrawColor = WhiteColor;
		C.Style = Style;
	}
}

//=============================================================================

defaultproperties
{
	TrueSilverColor=(R=192,G=192,B=192)
	LongShowTime=4.5
	ShortShowTime=2.0
	FadeTime=0.2
	WheelExpandTime=0.2
	WheelContractTime=0.4
	WheelSpinTime=0.2
	BodyIcon(0)=texture'BodyThief'
	BodyIcon(1)=texture'BodyGuard'
	TeamName(0)="Thieves"
	TeamName(1)="Guards"
	HotbarWidth(0)=834.0
	HotbarWidth(1)=635.0
	HotbarTex(0)=texture'ThiefBar'
	HotbarTex(1)=texture'GuardBar'
	SlimBarTex(0)=texture'ThiefSlimBar'
	SlimBarTex(1)=texture'GuardSlimBar'
	TotalHotkeys(0)=8
	TotalHotkeys(1)=6
	LargeChatFontName="ThPlusFonts.ThClean22"
	ServerInfoClass=class'ThPlusServerInfo'
	SansFontSize(0)=12
	SansFontSize(1)=14
	SansFontSize(2)=16
	SansFontSize(3)=18
	SansFontSize(4)=20
	SansFontSize(5)=22
	SansFontSize(6)=24
	SansFontSize(7)=30
	SansFontSize(8)=36
	SansFontSize(9)=42
	SansFontSize(10)=48
	SansFontSize(11)=64
	CleanFontSize(0)=10
	CleanFontSize(1)=12
	CleanFontSize(2)=14
	CleanFontSize(3)=16
	CleanFontSize(4)=18
	CleanFontSize(5)=20
	CleanFontSize(6)=22
	CleanFontSize(7)=24
	CleanFontSize(8)=30
	CleanFontSize(9)=36
	CleanFontSize(10)=42
	CleanFontSize(11)=48
	CleanFontSize(12)=64
	SerifFontSize(0)=12
	SerifFontSize(1)=14
	SerifFontSize(2)=16
	SerifFontSize(3)=18
	SerifFontSize(4)=20
	SerifFontSize(5)=22
	SerifFontSize(6)=24
	SerifFontSize(7)=30
	SerifFontSize(8)=36
	SerifFontSize(9)=42
	SerifFontSize(10)=48
	SerifFontSize(11)=64
	SerifFontSize(12)=80
}
