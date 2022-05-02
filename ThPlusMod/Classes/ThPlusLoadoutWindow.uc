//=============================================================================
// ThPlusLoadoutWindow.
//=============================================================================

class ThPlusLoadoutWindow extends ThLoadoutClientWindow;

function WindowButtonNoKeyboard AddWideChunkyButton(string Text)
{
	local WindowButtonNoKeyboard B;

	B = AddChunkyButton(Text);
	B.UpTexture = texture'ChunkyButton512';
	B.DownTexture = B.UpTexture;
	B.OverTexture = B.UpTexture;
	return B;
}

function WindowButtonNoKeyboard AddChunkyButton(string Text)
{
	local WindowButtonNoKeyboard B;

	B = WindowButtonNoKeyboard(CreateControl(class'ThPlusLoadoutButton', 0, 0, 0, 0));
	B.Text = Text;
	return B;
}

function Created()
{
	local int i;

	Root.Console.bQuickKeyEnable = true;
	Root.Console.LaunchUWindow();

	for (i = 0; i < 6; i++)
	{
		SelectLoadoutButton[i] = AddWideChunkyButton("loadout "$i);
	}
	WeaponsTab = AddChunkyButton("Weapons");
	ItemsTab = AddChunkyButton("Items");
	StartButton = AddChunkyButton("START");
	BackButton = AddChunkyButton("BACK");
	RenameButton = AddChunkyButton("RENAME");
	ClearLoadoutButton = AddChunkyButton("CLEAR");
	SaveLoadoutButton = AddChunkyButton("SAVE");
	NameEdit = ThEditBox(CreateWindow(class'ThPlusLoadoutEditBox', 0, 0, 0, 0));
	for (i = 0; i < 25; i++)
	{
		InventorySlot[i] = ThInventorySlotButton(CreateControl(class'ThPlusLoadoutInventoryButton', 0, 0, 0, 0));
		if (i < 10)
		{
			InventorySlot[i].InitButton(Self, i, i, true);
		}
		else
		{
			InventorySlot[i].InitButton(Self, i, i - 10, false);
		}
	}
	UpdateShopPageVisibility();

	Resized();
}

function UpdateShopPageVisibility()
{
	Super.UpdateShopPageVisibility();
	if (ShopPage == 0)
	{
		ThPlusLoadoutButton(WeaponsTab).ButtonColor = class'ThHUD'.Default.WhiteColor;
		ThPlusLoadoutButton(ItemsTab).ButtonColor = class'TInfo'.static.GetColor(127, 127, 127);
	}
	else if (ShopPage == 1)
	{
		ThPlusLoadoutButton(WeaponsTab).ButtonColor = class'TInfo'.static.GetColor(127, 127, 127);
		ThPlusLoadoutButton(ItemsTab).ButtonColor = class'ThHUD'.Default.WhiteColor;
	}
}

function Resized()
{
	local int i;
	local float Pad, InventoryWidth, InventoryHeight;
	local float SelectLoadoutButtonWidth, SelectLoadoutButtonX, LoadoutButtonHeight, LoadoutButtonY;

	WinWidth = Root.WinWidth;
	WinHeight = Root.WinHeight;
	WinLeft = 0.0;
	WinTop = 0.0;

	scaleY = class'ThHUD'.static.GetScaleY(Root.WinWidth, Root.WinHeight);

	SelectLoadoutButtonWidth = 256.0 * scaleY;
	SelectLoadoutButtonX = 0.5 * (WinWidth - SelectLoadoutButtonWidth);
	LoadoutButtonY = 0.7 * Root.WinHeight;
	LoadoutButtonHeight = 34.0 * scaleY;

	for (i = 0; i < 6; i++)
	{
		if (SelectLoadoutButton[i] != None)
		{
			SelectLoadoutButton[i].WinLeft = SelectLoadoutButtonX;
			SelectLoadoutButton[i].WinTop = LoadoutButtonY + i * (LoadoutButtonHeight + 1.0 * scaleY);
			SelectLoadoutButton[i].WinWidth = SelectLoadoutButtonWidth;
			SelectLoadoutButton[i].WinHeight = LoadoutButtonHeight;
			UpdateButtonFont(SelectLoadoutButton[i], 14.0 / 34.0);
		}
	}
	for (i = 0; i < class'ThieveryProModSettings'.default.numInventorySlots; i++)
	{
		InventorySlot[i].Resized();
	}
	for (i = 0; i < 64; i++)
	{
		if (ShopButton[i] != None)
		{
			ShopButton[i].Resized();
		}
	}

	Pad = 10.0 * scaleY;
	InventoryWidth = 5.0 * InventorySlot[0].WinWidth;
	InventoryHeight = 5.0 * InventorySlot[0].WinHeight;

	WeaponsTab.WinWidth = 150.0 * scaleY;
	WeaponsTab.WinHeight = 40.0 * scaleY;
	WeaponsTab.WinLeft = 0.5 * Root.WinWidth - 64.0 * scaleY;
	WeaponsTab.WinTop = 144.0 * scaleY - Pad - WeaponsTab.WinHeight;

	ItemsTab.WinWidth = WeaponsTab.WinWidth;
	ItemsTab.WinHeight = WeaponsTab.WinHeight;
	ItemsTab.WinLeft = WeaponsTab.WinLeft + WeaponsTab.WinWidth + Pad;
	ItemsTab.WinTop = WeaponsTab.WinTop;

	BackButton.WinWidth = 150.0 * scaleY;
	BackButton.WinHeight = 40.0 * scaleY;
	BackButton.WinLeft = 0.5 * (Root.WinWidth - BackButton.WinWidth);
	BackButton.WinTop = Root.WinHeight - Pad - BackButton.WinHeight;

	StartButton.WinWidth = 200.0 * scaleY;
	StartButton.WinHeight = 60.0 * scaleY;
	StartButton.WinLeft = 0.5 * (Root.WinWidth - StartButton.WinWidth);
	StartButton.WinTop = BackButton.WinTop - Pad - StartButton.WinHeight;

	RenameButton.WinWidth = 120.0 * scaleY;
	RenameButton.WinHeight = 32.0 * scaleY;
	RenameButton.WinLeft = InventorySlot[0].WinLeft + InventoryWidth - RenameButton.WinWidth;
	RenameButton.WinTop = InventorySlot[0].WinTop - Pad - RenameButton.WinHeight;

	NameEdit.WinWidth = InventoryWidth - Pad - RenameButton.WinWidth;
	NameEdit.WinHeight = RenameButton.WinHeight;
	NameEdit.WinLeft = InventorySlot[0].WinLeft;
	NameEdit.WinTop = InventorySlot[0].WinTop - Pad - NameEdit.WinHeight;

	ClearLoadoutButton.WinWidth = 120.0 * scaleY;
	ClearLoadoutButton.WinHeight = 32.0 * scaleY;
	ClearLoadoutButton.WinLeft = InventorySlot[0].WinLeft;
	ClearLoadoutButton.WinTop = InventorySlot[0].WinTop + InventoryHeight + Pad;

	SaveLoadoutButton.WinWidth = ClearLoadoutButton.WinWidth;
	SaveLoadoutButton.WinHeight = ClearLoadoutButton.WinHeight;
	SaveLoadoutButton.WinLeft = ClearLoadoutButton.WinLeft + ClearLoadoutButton.WinWidth + Pad;
	SaveLoadoutButton.WinTop = ClearLoadoutButton.WinTop;

	UpdateButtonFont(WeaponsTab);
	UpdateButtonFont(ItemsTab);
	UpdateButtonFont(BackButton);
	UpdateButtonFont(StartButton);
	UpdateButtonFont(RenameButton);
	UpdateButtonFont(ClearLoadoutButton);
	UpdateButtonFont(SaveLoadoutButton);

	LastRootWidth = Root.WinWidth;
	LastRootHeight = Root.WinHeight;
}

function UpdateButtonFont(WindowButtonNoKeyboard Button, optional float TextScale)
{
	ThPlusLoadoutButton(Button).ScaledFont = GetFont(Button.WinHeight, TextScale);
}

static function font GetFont(float NewWinHeight, optional float TextScale)
{
	local int FontSize;
	local float TextHeight;

	if (TextScale == 0.0)
	{
		TextScale = 12.0 / 32.0;
	}
	TextHeight = TextScale * NewWinHeight;
	if (TextHeight < 10.0)
	{
		return Font'Engine.SmallFont';
	}
	else
	{
		FontSize = int(TextHeight) + int(TextHeight) % 2;
		FontSize = class'ThPlusHUD'.static.GetClosestFontSize(FontSize, class'ThPlusHUD'.Default.SerifFontSize);
		return Font(DynamicLoadObject("ThPlusFonts.ThSerif"$FontSize, class'Font'));
	}
}

function Paint(canvas C, float X, float Y)
{
	local ThieveryPPawn tpp;
	local ThieveryShop NewShop;
	local float TextW, TextH, PosX, PosY, Pad, ShopWidth;
	local ThPlayerLoadout Loadout;
	local int i;

	tpp = ThieveryPPawn(GetPlayerOwner());
	if (tpp == None || tpp.PlayerReplicationInfo == None || ThHUD(tpp.myHUD) == None)
	{
		return;
	}

	if (LastRootWidth != Root.WinWidth || LastRootHeight != Root.WinHeight)
	{
		Resized();
	}

	C.Reset();
	C.Style = 3;
	C.DrawColor = class'ThHUD'.Default.WhiteColor;

	if (loadoutState == LS_Shop)
	{
		NewShop = tpp.FindShopForTeam(tpp.PlayerReplicationInfo.Team);
		if (NewShop != Shop)
		{
			SetShop(NewShop);
		}

		Pad = 10.0 * scaleY;
		ShopWidth = 8.0 * 64.0 * scaleY + 32.0 * scaleY;

		C.Font = ThHUD(tpp.myHUD).MyFontMedium;
		C.TextSize("AVAILABLE", TextW, TextH);
		C.CurX = WeaponsTab.WinLeft + 0.5 * ShopWidth - 0.5 * TextW;
		C.CurY = WeaponsTab.WinTop - 32.0 * scaleY - TextH;
		C.DrawText("AVAILABLE");

		C.TextSize("LOADOUT", TextW, TextH);
		C.CurX = InventorySlot[0].WinLeft;
		C.CurY = NameEdit.WinTop - 32.0 * scaleY - TextH;
		C.DrawText("LOADOUT");

		C.Font = ThHUD(tpp.myHUD).MyFontSmall;
		PosX = InventorySlot[0].WinLeft;
		PosY = ClearLoadoutButton.WinTop + ClearLoadoutButton.WinHeight + 2.0 * Pad;
		C.SetPos(PosX, PosY);
		C.DrawText("remaining funds:");
		C.TextSize(" ", TextW, TextH);
		PosY += TextH + 1.0 * scaleY;
		ThHUD(tpp.myHUD).PaintCost(C, tpp.BankedLoot, tpp.BankedGems, PosX, PosY, false, false, true);
	}
	else if (loadoutState == LS_SelectLoadout)
	{
		C.Font = ThHUD(tpp.myHUD).MyFontSmall;
		C.TextSize("SELECT LOADOUT", TextW, TextH);
		C.SetPos(0.5 * (Root.WinWidth - TextW), 0.7 * Root.WinHeight - (10.0 * scaleY + TextH));
		C.DrawText("SELECT LOADOUT");

		tpp.MakeLoudout();
		if (tpp.PlayerReplicationInfo.Team == 0)
		{
			Loadout = tpp.MyThiefLoadout;
		}
		else if (tpp.PlayerReplicationInfo.Team == 1)
		{
			Loadout = tpp.MyGuardLoadout;
		}
		if (Loadout != None)
		{
			for (i = 0; i < 6; i++)
			{
				if (SelectLoadoutButton[i].Text != Loadout.LoadoutNames[i])
				{
					SelectLoadoutButton[i].Text = Loadout.LoadoutNames[i];
				}
			}
		}
	}
}

function SetShop(ThieveryShop NewShop)
{
	local int i, Slot, UISlot;

	RemoveShopButtons();
	Shop = NewShop;
	if (Shop == None)
	{
		return;
	}

	for (i = 0; i < 20 && Slot < 64; i++)
	{
		if (Shop.Melee[i].Item != None)
		{
			if (ShopButton[Slot] == None)
			{
				ShopButton[Slot] = ThShopItemButton(CreateControl(class'ThPlusLoadoutShopButton', 0, 0, 0, 0));
			}
			ShopButton[Slot].InitButton(Self, Slot, i, true, false, false, Shop);
			Slot++;
		}
	}

	if ((Slot % 2) == 1)
	{
		Slot++;
	}

	for (i = 0; i < 20 && Slot < 64; i++)
	{
		if (Shop.Ranged[i].Item != None)
		{
			if (ShopButton[Slot] == None)
			{
				ShopButton[Slot] = ThShopItemButton(CreateControl(class'ThPlusLoadoutShopButton', 0, 0, 0, 0));
			}
			ShopButton[Slot].InitButton(Self, Slot, i, false, true, false, Shop);
			Slot++;
		}
	}

	for (i = 0; i < 20 && Slot < 64; i++)
	{
		if (Shop.Items[i].Item != None)
		{
			if (ShopButton[Slot] == None)
			{
				ShopButton[Slot] = ThShopItemButton(CreateControl(class'ThPlusLoadoutShopButton', 0, 0, 0, 0));
			}
			ShopButton[Slot].InitButton(Self, UISlot, i, false, false, true, Shop);
			Slot++;
			UISlot++;
		}
	}

	UpdateShopPageVisibility();
}

defaultproperties
{
}
