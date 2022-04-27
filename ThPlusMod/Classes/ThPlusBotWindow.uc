//=============================================================================
// ThPlusBotWindow.
//=============================================================================

class ThPlusBotWindow extends UWindowDialogClientWindow;

#exec TEXTURE IMPORT NAME=BotWindowModulated FILE=Textures\BotWindowModulated.pcx GROUP=HUD MIPS=ON
#exec TEXTURE IMPORT NAME=BotWindowTransparent FILE=Textures\BotWindowTransparent.pcx GROUP=HUD MIPS=ON

var ThPlusPawn tpp;
var ThieveryGameReplicationInfo GRI;
var ThPlusBotButton OrderButton[6], PatrolButton[12];
var string OrderText[6];
var int NumOrders, NumPatrols;
var bool bPatrolsVisible, bInitialized;
var float ScaleY, BgWidth, BgHeight, BgLeft, BgTop, BgPad;
var float InsetLeft, InsetRight, InsetTop, InsetBottom;
const DE_Escape = 16;

function Created()
{
	bLeaveOnScreen = true;
	ShowWindow();
	Resized();
	CreateButtons();
}

function Resized()
{
	WinWidth = Root.WinWidth;
	WinHeight = Root.WinHeight;
	WinLeft = 0.0;
	WinTop = 0.0;

	ScaleY = class'ThHUD'.static.GetScaleY(Root.WinWidth, Root.WinHeight);

	// background image
	BgWidth = 512.0 * ScaleY;
	BgHeight = 512.0 * ScaleY;
	BgLeft = 0.5 * Root.WinWidth - 0.5 * BgWidth;
	BgTop = 0.5 * Root.WinHeight - 0.5 * BgHeight;
	BgPad = 14.0 * ScaleY;

	// usuable area within background image for buttons
	InsetLeft = 15.0 * ScaleY + 45.0 * ScaleY;
	InsetRight = 16.0 * ScaleY + BgPad;
	InsetTop = 185.0 * ScaleY + BgPad;
	InsetBottom = 17.0 * ScaleY + BgPad;

	if (class'ThPlusConfig'.Default.bShowBotWindowHelp)
	{
		InsetBottom += 20.0 * ScaleY + BgPad;
	}
}

function CreateButtons()
{
	local int i;

	// order buttons
	NumOrders = ArrayCount(OrderButton);
	for (i = 0; i < NumOrders; i++)
	{
		OrderButton[i] = ThPlusBotButton(CreateControl(class'ThPlusBotButton', 0, 0, 0, 0));
		OrderButton[i].Text = OrderText[i];
	}

	// patrol buttons
	for (i = 0; i < ArrayCount(PatrolButton); i++)
	{
		PatrolButton[i] = ThPlusBotButton(CreateControl(class'ThPlusBotButton', 0, 0, 0, 0));
	}
}

function UpdateButtons()
{
	local int i;
	local float Pad;

	// order buttons
	Pad = (BgHeight - InsetTop - InsetBottom) / (4.0 * FMax(6.0, NumOrders));
	for (i = 0; i < NumOrders; i++)
	{
		SetButtonDimensions(i, Pad, OrderButton[i]);
	}

	// patrol buttons
	NumPatrols = Min(ArrayCount(PatrolButton), GRI.numPatrolRoutes);
	if (NumPatrols > 0)
	{
		Pad = (BgHeight - InsetTop - InsetBottom) / (4.0 * FMax(6.0, NumPatrols));
		for (i = 0; i < NumPatrols; i++)
		{
			SetButtonDimensions(i, Pad, PatrolButton[i]);
			if (GRI.PatrolRouteName[i] != "")
			{
				PatrolButton[i].Text = GRI.PatrolRouteName[i];
			}
			else
			{
				PatrolButton[i].Text = "Unknown route";
			}
		}
	}
}

function SetButtonDimensions(int i, float Pad, out ThPlusBotButton B)
{
	B.WinWidth = BgWidth - (InsetLeft - Pad) - InsetRight;
	B.WinHeight = 4.0 * Pad;
	B.WinLeft = BgLeft + (InsetLeft - Pad);
	B.WinTop = BgTop + InsetTop + float(i) * 4.0 * Pad;
	B.Pad = Pad;
}

function ShowOrders()
{
	local int i;

	bPatrolsVisible = false;
	for (i = 0; i < NumPatrols; i++)
	{
		PatrolButton[i].HideWindow();
	}
	for (i = 0; i < NumOrders; i++)
	{
		OrderButton[i].ShowWindow();
	}

	// disable "Patrols" button if there are no patrol routes
	OrderButton[NumOrders - 1].bDisabled = (NumPatrols == 0);
}

function ShowPatrols()
{
	local int i;

	bPatrolsVisible = true;
	for (i = 0; i < NumOrders; i++)
	{
		OrderButton[i].HideWindow();
	}
	for (i = 0; i < NumPatrols; i++)
	{
		PatrolButton[i].ShowWindow();
	}
}

function Paint(canvas C, float X, float Y)
{
	local int i, HealthIcons;
	local float PosX, PosY, TextW, TextH, TrimWidth;
	local float IconSpacing, IconW, IconH, IconScale, IconInsetX;
	local string Text;
	local WindowConsole Con;

	Con = WindowConsole(GetPlayerOwner().Player.Console);
	if (Con != None && Con.bShowConsole)
	{
		Close();
		return;
	}

	tpp = ThPlusPawn(GetPlayerOwner());
	if (tpp == None || tpp.GameReplicationInfo == None || ThHUD(tpp.myHUD) == None
		|| tpp.OrderingBot == None || tpp.OrderingBot.Health <= 0)
	{
		Close();
		return;
	}

	GRI = ThieveryGameReplicationInfo(tpp.GameReplicationInfo);
	if (GRI == None)
	{
		Close();
		return;
	}

	if (!bInitialized)
	{
		UpdateButtons();
		ShowOrders();
		bInitialized = true;
	}

	if (Root.WinWidth != WinWidth || Root.WinHeight != WinHeight)
	{
		Resized();
		UpdateButtons();
	}

	C.bNoSmooth = false;

	// bot portrait
	C.Style = 1;
	if (class'ThPlusConfig'.Default.bUseModernTheme)
	{
		C.DrawColor = class'TInfo'.static.GetColor(176, 176, 176);
		C.SetPos(BgLeft + 38.0 * ScaleY, BgTop + 22.0 * ScaleY);
		C.DrawIcon(texture'GuardTile', 142.0 / 256.0 * ScaleY);
	}
	else
	{
		C.DrawColor = class'ThHUD'.Default.WhiteColor;
		C.SetPos(BgLeft + 38.0 * ScaleY, BgTop + 22.0 * ScaleY);
		C.DrawIcon(texture'BlackTexture', 142.0 / 32.0 * ScaleY);
		C.SetPos(BgLeft + 60.0 * ScaleY, BgTop + 45.0 * ScaleY);
		C.DrawIcon(texture'OtherGuardIcon', 96.0 / 64.0 * ScaleY);
	}

	// background (modulated layer)
	C.Style = 4;
	C.SetPos(BgLeft, BgTop);
	C.DrawIcon(texture'BotWindowModulated', ScaleY);

	// background (transparent layer)
	C.Style = 3;
	C.DrawColor = class'ThHUD'.Default.WhiteColor;
	C.SetPos(BgLeft, BgTop);
	C.DrawIcon(texture'BotWindowTransparent', ScaleY);

	// bot name
	C.DrawColor = class'TInfo'.static.GetColor(255, 250, 192);
	C.Font = ThHUD(tpp.myHUD).MyFontMedium;
	PosX = BgLeft + 201.0 * ScaleY + BgPad;
	PosY = BgTop + 73.0 * ScaleY + BgPad;
	TrimWidth = BgLeft + BgWidth - PosX - InsetRight;
	Text = tpp.OrderingBot.PlayerReplicationInfo.PlayerName;
	Text = class'ThPlusHUD'.static.TrimText(C, Text, TrimWidth);
	C.SetPos(PosX, PosY);
	C.DrawText(Text);

	// bot health icons
	C.Style = 2;
	C.DrawColor = C.Default.DrawColor;
	HealthIcons = int(float(tpp.OrderingBot.Health) / 125.0 * 22.0);
	HealthIcons = Clamp(HealthIcons, int(tpp.OrderingBot.Health > 0), 22);
	IconSpacing = (295.0 * ScaleY - 2.0 * BgPad) / 22.0;
	IconW = 0.8 * IconSpacing;
	IconScale = IconW / 64.0;
	IconH = 128.0 * IconScale;
	IconInsetX = (0.2 * IconSpacing) * 0.5;
	PosY = BgTop + 185.0 * ScaleY - IconH - 0.5 * BgPad;
	for (i = 0; i < HealthIcons; i++)
	{
		C.SetPos(PosX + i * IconSpacing + IconInsetX, PosY);
		C.DrawIcon(texture'HealthShield2', IconScale);
	}

	// bot health text
	C.Style = 3;
	C.DrawColor = class'ThPlusHUD'.Default.TrueSilverColor;
	C.Font = ThHUD(tpp.myHUD).MyFontSmall;
	C.TextSize(" ", TextW, TextH);
	PosY -= (0.5 * BgPad + TextH);
	C.SetPos(PosX, PosY);
	C.DrawText("Health:");

	if (class'ThPlusConfig'.Default.bShowBotWindowHelp)
	{
		// right mouse text
		if (bPatrolsVisible)
		{
			Text = "Back";
		}
		else
		{
			Text = "Close";
		}
		C.TextSize(Text, TextW, TextH);
		PosX = BgLeft + BgWidth - InsetRight - TextW;
		PosY = BgTop + BgHeight - InsetBottom + BgPad + 0.5 * (20.0 * ScaleY - TextH);
		C.SetPos(PosX, PosY);
		C.DrawText(Text);

		// right mouse icon
		C.Style = 2;
		PosX -= (TextH + 10.0 * ScaleY);
		DrawStretchedTexture(C, PosX, PosY, TextH, TextH, texture'RightMouseIcon');

		// left mouse text
		C.Style = 3;
		Text = "Select";
		C.TextSize(Text, TextW, TextH);
		PosX -= (TextW + 1.5 * BgPad);
		C.SetPos(PosX, PosY);
		C.DrawText(Text);

		// left mouse icon
		C.Style = 2;
		PosX -= (TextH + 10.0 * ScaleY);
		DrawStretchedTexture(C, PosX, PosY, TextH, TextH, texture'LeftMouseIcon');
	}

	C.bNoSmooth = true;
}

function Notify(UWindowDialogControl Control, byte E)
{
	local int i;

	if (tpp == None)
	{
		Close();
		return;
	}

	if (E == DE_RClick || E == DE_Escape)
	{
		tpp.ClientPlayASound(sound'TC_PickSnd', SLOT_Interact);
		if (E == DE_RClick && bPatrolsVisible)
		{
			ShowOrders();
		}
		else
		{
			Close();
		}
	}
	else if (E == DE_Click)
	{
		if (bPatrolsVisible)
		{
			for (i = 0; i < NumPatrols; i++)
			{
				if (Control == PatrolButton[i])
				{
					tpp.BotPatrolOrderOption(i);
					Close();
					return;
				}
			}
		}
		else
		{
			if (Control == OrderButton[NumOrders - 1]) // patrol button
			{
				ShowPatrols();
			}
			else
			{
				for (i = 0; i < NumOrders - 1; i++) // orders excluding patrol
				{
					if (Control == OrderButton[i])
					{
						tpp.BotOrderOption(i);
						Close();
						return;
					}
				}
			}
		}
	}
}

function RClick(float X, float Y)
{
	Notify(None, DE_RClick);
}

function EscClose()
{
	Notify(None, DE_Escape);
}

function NotifyBeforeLevelChange()
{
	Close();
	Super.NotifyBeforeLevelChange();
}

function Close(optional bool bByParent)
{
	if (tpp != None)
	{
		tpp.ClearOrderingBot();
	}
	Super.Close(bByParent);
}

defaultproperties
{
	OrderText(0)="Guard Here"
	OrderText(1)="Investigate"
	OrderText(2)="Roam"
	OrderText(3)="Stand Down"
	OrderText(4)="Follow Me"
	OrderText(5)="Patrol"
}
