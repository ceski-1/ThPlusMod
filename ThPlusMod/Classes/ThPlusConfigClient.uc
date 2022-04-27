//=============================================================================
// ThPlusConfigClient.
//=============================================================================

class ThPlusConfigClient extends UWindowDialogClientWindow;

var UWindowCheckbox FOVCorrectionCheck;
var localized string FOVCorrectionText;

var UWindowComboControl MouseSmoothingCombo;
var localized string MouseSmoothingText;
var localized string MouseSmoothingDetails[3];

var UWindowHSliderControl ViewBobSlider;
var localized string ViewBobText;

var UWindowCheckbox RaiseBehindViewCheck;
var localized string RaiseBehindViewText;

var UWindowComboControl AutoHideHealthCombo;
var localized string AutoHideHealthText;
var localized string AutoHideHealthDetails[3];

var UWindowCheckbox AutoHideLootCheck;
var localized string AutoHideLootText;

var UWindowCheckbox AutoHideCompassCheck;
var localized string AutoHideCompassText;

var UWindowCheckbox SlimHotbarCheck;
var localized string SlimHotbarText;

var UWindowComboControl FrobItemOffsetCombo;
var localized string FrobItemOffsetText;
var localized string FrobItemOffsetDetails[3];

var UWindowCheckbox BotWindowHelpCheck;
var localized string BotWindowHelpText;

var UWindowCheckbox BotNamesOnMapCheck;
var localized string BotNamesOnMapText;

var UWindowCheckbox ModernThemeCheck;
var localized string ModernThemeText;

var int ControlOffset;

function Created()
{
	local int CenterWidth, CenterPos, ControlSpacing, ControlPadding;

	Super.Created();

	CenterWidth = WinWidth - 40;
	CenterPos = (WinWidth - CenterWidth) / 2;
	ControlSpacing = 24;
	ControlPadding = 8;

	FOVCorrectionCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', CenterPos, ControlOffset, CenterWidth, 1));
	FOVCorrectionCheck.bChecked = class'ThPlusConfig'.Default.bUseFOVCorrection;
	FOVCorrectionCheck.SetText(FOVCorrectionText);
	FOVCorrectionCheck.SetFont(F_Normal);
	FOVCorrectionCheck.Align = TA_Left;
	ControlOffset += ControlSpacing;

	MouseSmoothingCombo = UWindowComboControl(CreateControl(class'UWindowComboControl', CenterPos, ControlOffset, CenterWidth, 1));
	MouseSmoothingCombo.SetText(MouseSmoothingText);
	MouseSmoothingCombo.SetFont(F_Normal);
	MouseSmoothingCombo.SetEditable(false);
	MouseSmoothingCombo.AddItem(MouseSmoothingDetails[0]);
	MouseSmoothingCombo.AddItem(MouseSmoothingDetails[1]);
	MouseSmoothingCombo.AddItem(MouseSmoothingDetails[2]);
	MouseSmoothingCombo.SetSelectedIndex(GetMouseSmoothing());
	ControlOffset += ControlSpacing + 2;

	ViewBobSlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', CenterPos, ControlOffset, CenterWidth, 1));
	ViewBobSlider.SetRange(0.0, 100.0, 25.0);
	ViewBobSlider.SetValue(100.0 * GetViewBob());
	ViewBobSlider.SetText(ViewBobText);
	ViewBobSlider.SetFont(F_Normal);
	ControlOffset += ControlSpacing - 2;

	RaiseBehindViewCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', CenterPos, ControlOffset, CenterWidth, 1));
	RaiseBehindViewCheck.bChecked = class'ThPlusConfig'.Default.bRaiseBehindView;
	RaiseBehindViewCheck.SetText(RaiseBehindViewText);
	RaiseBehindViewCheck.SetFont(F_Normal);
	RaiseBehindViewCheck.Align = TA_Left;
	ControlOffset += ControlSpacing + ControlPadding;

	AutoHideHealthCombo = UWindowComboControl(CreateControl(class'UWindowComboControl', CenterPos, ControlOffset, CenterWidth, 1));
	AutoHideHealthCombo.SetText(AutoHideHealthText);
	AutoHideHealthCombo.SetFont(F_Normal);
	AutoHideHealthCombo.SetEditable(false);
	AutoHideHealthCombo.AddItem(AutoHideHealthDetails[0]);
	AutoHideHealthCombo.AddItem(AutoHideHealthDetails[1]);
	AutoHideHealthCombo.AddItem(AutoHideHealthDetails[2]);
	AutoHideHealthCombo.SetSelectedIndex(GetAutoHideHealth());
	ControlOffset += ControlSpacing;

	AutoHideLootCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', CenterPos, ControlOffset, CenterWidth, 1));
	AutoHideLootCheck.bChecked = class'ThPlusConfig'.Default.bAutoHideLoot;
	AutoHideLootCheck.SetText(AutoHideLootText);
	AutoHideLootCheck.SetFont(F_Normal);
	AutoHideLootCheck.Align = TA_Left;
	ControlOffset += ControlSpacing;

	AutoHideCompassCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', CenterPos, ControlOffset, CenterWidth, 1));
	AutoHideCompassCheck.bChecked = class'ThPlusConfig'.Default.bAutoHideCompass;
	AutoHideCompassCheck.SetText(AutoHideCompassText);
	AutoHideCompassCheck.SetFont(F_Normal);
	AutoHideCompassCheck.Align = TA_Left;
	ControlOffset += ControlSpacing + ControlPadding;

	SlimHotbarCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', CenterPos, ControlOffset, CenterWidth, 1));
	SlimHotbarCheck.bChecked = class'ThPlusConfig'.Default.bUseSlimHotbar;
	SlimHotbarCheck.SetText(SlimHotbarText);
	SlimHotbarCheck.SetFont(F_Normal);
	SlimHotbarCheck.Align = TA_Left;
	ControlOffset += ControlSpacing + ControlPadding;

	FrobItemOffsetCombo = UWindowComboControl(CreateControl(class'UWindowComboControl', CenterPos, ControlOffset, CenterWidth, 1));
	FrobItemOffsetCombo.SetText(FrobItemOffsetText);
	FrobItemOffsetCombo.SetFont(F_Normal);
	FrobItemOffsetCombo.SetEditable(false);
	FrobItemOffsetCombo.AddItem(FrobItemOffsetDetails[0]);
	FrobItemOffsetCombo.AddItem(FrobItemOffsetDetails[1]);
	FrobItemOffsetCombo.AddItem(FrobItemOffsetDetails[2]);
	FrobItemOffsetCombo.SetSelectedIndex(GetFrobItemOffset());
	ControlOffset += ControlSpacing + ControlPadding;

	BotWindowHelpCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', CenterPos, ControlOffset, CenterWidth, 1));
	BotWindowHelpCheck.bChecked = class'ThPlusConfig'.Default.bShowBotWindowHelp;
	BotWindowHelpCheck.SetText(BotWindowHelpText);
	BotWindowHelpCheck.SetFont(F_Normal);
	BotWindowHelpCheck.Align = TA_Left;
	ControlOffset += ControlSpacing;

	BotNamesOnMapCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', CenterPos, ControlOffset, CenterWidth, 1));
	BotNamesOnMapCheck.bChecked = class'ThPlusConfig'.Default.bShowBotNamesOnMap;
	BotNamesOnMapCheck.SetText(BotNamesOnMapText);
	BotNamesOnMapCheck.SetFont(F_Normal);
	BotNamesOnMapCheck.Align = TA_Left;
	ControlOffset += ControlSpacing + ControlPadding;

	ModernThemeCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', CenterPos, ControlOffset, CenterWidth, 1));
	ModernThemeCheck.bChecked = class'ThPlusConfig'.Default.bUseModernTheme;
	ModernThemeCheck.SetText(ModernThemeText);
	ModernThemeCheck.SetFont(F_Normal);
	ModernThemeCheck.Align = TA_Left;
	ControlOffset += Default.ControlOffset;
}

function int GetMouseSmoothing()
{
	if (!class'ThPlusConfig'.Default.bUseMouseSmoothing && !GetPlayerOwner().bMaxMouseSmoothing)
	{
		return 0;
	}
	else if (class'ThPlusConfig'.Default.bUseMouseSmoothing && !GetPlayerOwner().bMaxMouseSmoothing)
	{
		return 1;
	}
	else if (class'ThPlusConfig'.Default.bUseMouseSmoothing && GetPlayerOwner().bMaxMouseSmoothing)
	{
		return 2;
	}
	else
	{
		class'ThPlusConfig'.Default.bUseMouseSmoothing = false;
		GetPlayerOwner().bMaxMouseSmoothing = false;
		return 0;
	}
}

static function float GetViewBob()
{
	if (class'ThPlusConfig'.Default.ViewBob < 0.0 || class'ThPlusConfig'.Default.ViewBob > 1.0)
	{
		class'ThPlusConfig'.Default.ViewBob = 0.5;
	}
	return class'ThPlusConfig'.Default.ViewBob;
}

static function int GetAutoHideHealth()
{
	if (class'ThPlusConfig'.Default.AutoHideHealth < 0 || class'ThPlusConfig'.Default.AutoHideHealth > 2)
	{
		class'ThPlusConfig'.Default.AutoHideHealth = 1;
	}
	return class'ThPlusConfig'.Default.AutoHideHealth;
}

static function int GetFrobItemOffset()
{
	if (class'ThPlusConfig'.Default.FrobItemOffset < 0 || class'ThPlusConfig'.Default.FrobItemOffset > 2)
	{
		class'ThPlusConfig'.Default.FrobItemOffset = 1;
	}
	return class'ThPlusConfig'.Default.FrobItemOffset;
}

function AfterCreate()
{
	Super.AfterCreate();
	DesiredWidth = 256;
	DesiredHeight = ControlOffset;
}

function BeforePaint(canvas C, float X, float Y)
{
	local int CenterWidth, CenterPos, CheckSize, SliderSize, ComboSize;

	Super.BeforePaint(C, X, Y);

	CenterWidth = WinWidth - 40;
	CenterPos = (WinWidth - CenterWidth) / 2;
	CheckSize = CenterWidth - 104 + 16;
	SliderSize = 104;
	ComboSize = 104;

	FOVCorrectionCheck.SetSize(CheckSize, 1);
	FOVCorrectionCheck.WinLeft = CenterPos;

	MouseSmoothingCombo.SetSize(CenterWidth, 1);
	MouseSmoothingCombo.WinLeft = CenterPos;
	MouseSmoothingCombo.EditBoxWidth = ComboSize;

	ViewBobSlider.SetSize(CenterWidth, 1);
	ViewBobSlider.SliderWidth = SliderSize;
	ViewBobSlider.WinLeft = CenterPos;

	RaiseBehindViewCheck.SetSize(CheckSize, 1);
	RaiseBehindViewCheck.WinLeft = CenterPos;

	AutoHideHealthCombo.SetSize(CenterWidth, 1);
	AutoHideHealthCombo.WinLeft = CenterPos;
	AutoHideHealthCombo.EditBoxWidth = ComboSize;

	AutoHideLootCheck.SetSize(CheckSize, 1);
	AutoHideLootCheck.WinLeft = CenterPos;

	AutoHideCompassCheck.SetSize(CheckSize, 1);
	AutoHideCompassCheck.WinLeft = CenterPos;

	SlimHotbarCheck.SetSize(CheckSize, 1);
	SlimHotbarCheck.WinLeft = CenterPos;

	FrobItemOffsetCombo.SetSize(CenterWidth, 1);
	FrobItemOffsetCombo.WinLeft = CenterPos;
	FrobItemOffsetCombo.EditBoxWidth = ComboSize;

	BotWindowHelpCheck.SetSize(CheckSize, 1);
	BotWindowHelpCheck.WinLeft = CenterPos;

	BotNamesOnMapCheck.SetSize(CheckSize, 1);
	BotNamesOnMapCheck.WinLeft = CenterPos;

	ModernThemeCheck.SetSize(CheckSize, 1);
	ModernThemeCheck.WinLeft = CenterPos;
}

function Notify(UWindowDialogControl C, byte E)
{
	Super.Notify(C, E);

	if (E == DE_Change)
	{
		switch (C)
		{
			case FOVCorrectionCheck:
				class'ThPlusConfig'.Default.bUseFOVCorrection = FOVCorrectionCheck.bChecked;
				break;
			case MouseSmoothingCombo:
				MouseSmoothingChanged();
				break;
			case ViewBobSlider:
				class'ThPlusConfig'.Default.ViewBob = 0.01 * ViewBobSlider.Value;
				break;
			case RaiseBehindViewCheck:
				class'ThPlusConfig'.Default.bRaiseBehindView = RaiseBehindViewCheck.bChecked;
				break;
			case AutoHideHealthCombo:
				class'ThPlusConfig'.Default.AutoHideHealth = AutoHideHealthCombo.GetSelectedIndex();
				break;
			case AutoHideLootCheck:
				class'ThPlusConfig'.Default.bAutoHideLoot = AutoHideLootCheck.bChecked;
				break;
			case AutoHideCompassCheck:
				class'ThPlusConfig'.Default.bAutoHideCompass = AutoHideCompassCheck.bChecked;
				break;
			case SlimHotbarCheck:
				class'ThPlusConfig'.Default.bUseSlimHotbar = SlimHotbarCheck.bChecked;
				break;
			case FrobItemOffsetCombo:
				class'ThPlusConfig'.Default.FrobItemOffset = FrobItemOffsetCombo.GetSelectedIndex();
				break;
			case BotWindowHelpCheck:
				class'ThPlusConfig'.Default.bShowBotWindowHelp = BotWindowHelpCheck.bChecked;
				break;
			case BotNamesOnMapCheck:
				class'ThPlusConfig'.Default.bShowBotNamesOnMap = BotNamesOnMapCheck.bChecked;
				break;
			case ModernThemeCheck:
				class'ThPlusConfig'.Default.bUseModernTheme = ModernThemeCheck.bChecked;
				break;
			default:
				break;
		}
	}
}

function MouseSmoothingChanged()
{
	switch (MouseSmoothingCombo.GetSelectedIndex())
	{
		case 0:
			class'ThPlusConfig'.Default.bUseMouseSmoothing = false;
			GetPlayerOwner().bMaxMouseSmoothing = false;
			break;
		case 1:
			class'ThPlusConfig'.Default.bUseMouseSmoothing = true;
			GetPlayerOwner().bMaxMouseSmoothing = false;
			break;
		case 2:
			class'ThPlusConfig'.Default.bUseMouseSmoothing = true;
			GetPlayerOwner().bMaxMouseSmoothing = true;
			break;
		default:
			break;
	}
}

function SaveConfigs()
{
	GetPlayerOwner().SaveConfig();
	class'ThPlusConfig'.static.StaticSaveConfig();
	Super.SaveConfigs();
}

defaultproperties
{
	FOVCorrectionText="FOV Correction"
	MouseSmoothingText="Mouse Smoothing"
	MouseSmoothingDetails(0)="Disabled"
	MouseSmoothingDetails(1)="Normal"
	MouseSmoothingDetails(2)="Full"
	ViewBobText="View Bob"
	RaiseBehindViewText="Raise Behind View"
	AutoHideHealthText="Auto-Hide Health"
	AutoHideHealthDetails(0)="Disabled"
	AutoHideHealthDetails(1)="Enabled"
	AutoHideHealthDetails(2)="Full Health Only"
	AutoHideLootText="Auto-Hide Loot"
	AutoHideCompassText="Auto-Hide Compass"
	SlimHotbarText="Slim Weapon Hotbar"
	FrobItemOffsetText="Frob Item Offset"
	FrobItemOffsetDetails(0)="Above Crosshair"
	FrobItemOffsetDetails(1)="At Crosshair"
	FrobItemOffsetDetails(2)="Below Crosshair"
	BotWindowHelpText="Bot Window Help"
	BotNamesOnMapText="Bot Names on Map"
	ModernThemeText="Modern Theme"
	ControlOffset=16
}