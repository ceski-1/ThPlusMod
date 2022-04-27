//=============================================================================
// ThPlusLoadoutShopButton.
//=============================================================================

class ThPlusLoadoutShopButton extends ThShopItemButton;

#exec TEXTURE IMPORT NAME=LoadoutShopBG FILE=Textures\LoadoutShopBG.pcx GROUP=HUD MIPS=ON

var float Glow;

function Paint(canvas C, float X, float Y)
{
	local float TextW, TextH, PosX, PosY, TileSize, Pad, NewGlow;
	local int Quantity;
	local Inventory NewItem;
	local ThieveryPPawn tpp;

	tpp = ThieveryPPawn(GetPlayerOwner());
	if (tpp == None || ThPlusHUD(tpp.myHUD) == None)
	{
		return;
	}

	scaleY = class'ThHUD'.static.GetScaleY(Root.WinWidth, Root.WinHeight);
	Pad = 6.0 * scaleY;

	// draw background
	C.Style = 1;
	C.DrawColor = C.Default.DrawColor;
	C.SetPos(0.0, 0.0);
	C.DrawTile(texture'LoadoutShopBG', WinWidth, WinHeight, 0.0, 0.0, 1024.0, 256.0);
	if (displayMesh != None && MouseIsReallyOver())
	{
		// draw highlighted background behind mesh
		C.DrawColor = class'ThPlusHUD'.Default.TrueSilverColor;
		C.SetPos(1.0 * scaleY, 1.0 * scaleY);
		TileSize = WinHeight - 2.0 * scaleY;
		C.DrawTile(texture'LoadoutShopBG', TileSize, TileSize, 4.0, 4.0, 248.0, 248.0);
	}

	// draw mesh
	if (displayMesh == None)
	{
		return;
	}
	NewGlow = Glow;
	if (MouseIsReallyOver())
	{
		NewGlow = 2.0;
	}
	PosX = WinLeft + 0.5 * WinHeight;
	PosY = WinTop + 0.5 * WinHeight;
	ThPlusHUD(tpp.myHUD).DrawLoadoutMesh(C, PosX, PosY, WinHeight,
										 displayMesh, displayScale, displayOffset, displayRotation,
										 displaySkin0, displaySkin1, displaySkin2, displaySkin3,
										 NewGlow);
	// draw item name
	C.Style = 3;
	C.Font = ThPlusHUD(tpp.myHUD).SansFontTiny;
	C.DrawColor = class'ThHUD'.Default.WhiteColor;
	C.SetPos(WinHeight + Pad, Pad);
	C.DrawText(itemName);

	// draw item cost
	C.Font = ThHUD(tpp.myHUD).MyFontSmall;
	C.TextSize(" ", TextW, TextH);
	PosX = WinWidth - Pad;
	PosY = WinHeight - TextH - 0.4 * Pad;
	ThPlusHUD(tpp.myHUD).PaintCost(C, itemCost, itemGemCost, PosX, PosY, true, false, false);

	// draw item stock
	if (itemLimit > 0 && itemClass != None)
	{
		Quantity = 0;
		NewItem = tpp.FindInventoryType(itemClass);
		if (NewItem != None)
		{
			Quantity += Pickup(NewItem).NumCopies + 1;
		}
		Quantity = itemLimit - Quantity;

		if (Quantity < 11)
		{
			C.Style = 3;
			C.SetPos(WinHeight, 0.0);
			C.Font = ThPlusHUD(tpp.myHUD).SansFontTiny;
			C.DrawColor = class'TInfo'.static.GetColor(169, 169, 157);
			if (Quantity > 1)
			{
				C.TextSize("Stock: "$Quantity, TextW, TextH);
				C.SetPos(WinHeight + Pad, WinHeight - 0.7 * Pad - TextH);
				C.DrawText("Stock: "$Quantity);
			}
		}
	}
}

function SetupShopItemDisplay()
{
	local class<ThieveryWeapon> WeaponClass;
	local class<ThieveryAmmo> AmmoClass;
	local class<ThieveryProjectile> ProjectileClass;

	Super.SetupShopItemDisplay();

	if (Slot == 255)
	{
		return;
	}

	if (bMelee)
	{
		WeaponClass = class<ThieveryWeapon>(Shop.Melee[ShopItemIndex].Item);
	}
	else if (bRanged)
	{
		AmmoClass = class<ThieveryAmmo>(Shop.Ranged[ShopItemIndex].Item);
		if (AmmoClass != None)
		{
			ProjectileClass = AmmoClass.Default.ProjectileClass;
		}
	}
	else if (bItem)
	{
		itemClass = class<ThieveryPickup>(Shop.Items[ShopItemIndex].Item);
	}

	if (WeaponClass != None || ProjectileClass != None || itemClass != None)
	{
		class'ThPlusHUD'.static.ApplyLoadoutMeshCorrections(
				WeaponClass, ProjectileClass, itemClass,
				displayMesh, displayScale, displayOffset, displayRotation,
				displaySkin0, displaySkin1, displaySkin2, displaySkin3, Glow);
	}
}

function Resized()
{
	local float PosX, PosY, ButtonWidth, ButtonHeight, ColumnSpacing;
	local int Column, Row;

	scaleY = class'ThHUD'.static.GetScaleY(Root.WinWidth, Root.WinHeight);

	PosX = 0.5 * Root.WinWidth - 64.0 * scaleY;
	PosY = 144.0 * scaleY;

	ButtonWidth = 256.0 * scaleY;
	ButtonHeight = 64.0 * scaleY;

	ColumnSpacing = 32.0 * scaleY;

	Column = Slot % 2;
	Row = Slot / 2;

	WinLeft = PosX + Column * (ButtonWidth + ColumnSpacing);
	WinTop = PosY + Row * ButtonHeight;
	WinWidth = ButtonWidth;
	WinHeight = ButtonHeight;
}

function PaintTooltip(canvas C, float X, float Y)
{
	local float PosX, PosY;
	local ThieveryPPawn tpp;

	if (itemName == "" || !MouseIsReallyOver())
	{
		return;
	}

	tpp = ThieveryPPawn(GetPlayerOwner());
	if (tpp == None || ThPlusHUD(tpp.myHUD) == None)
	{
		return;
	}

	PosX = WinLeft + 1.09 * WinHeight;
	PosY = WinTop + 0.7 * WinHeight;
	ThPlusHUD(tpp.myHUD).PaintTooltip(C, PosX, PosY, itemName, itemDesc, true, itemCost, itemGemCost);
}

defaultproperties
{
}
