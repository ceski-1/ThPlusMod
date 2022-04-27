//=============================================================================
// ThPlusLoadoutInventoryButton.
//=============================================================================

class ThPlusLoadoutInventoryButton extends ThInventorySlotButton;

#exec TEXTURE IMPORT NAME=LoadoutInvBG0 FILE=Textures\LoadoutInvBG0.pcx GROUP=HUD MIPS=ON
#exec TEXTURE IMPORT NAME=LoadoutInvBG1 FILE=Textures\LoadoutInvBG1.pcx GROUP=HUD MIPS=ON

var float Glow;

function Paint(canvas C, float X, float Y)
{
	local float scaleY, TextW, TextH, PosX, PosY, TileSize, Pad, NewGlow;
	local ThieveryPPawn tpp;

	tpp = ThieveryPPawn(GetPlayerOwner());
	if (tpp == None || ThPlusHUD(tpp.myHUD) == None)
	{
		return;
	}

	SetupItemDisplay();
	scaleY = class'ThHUD'.static.GetScaleY(Root.WinWidth, Root.WinHeight);
	Pad = 6.0 * scaleY;

	// draw background
	C.Style = 1;
	C.DrawColor = C.Default.DrawColor;
	C.SetPos(0.0, 0.0);
	if (displayMesh != None)
	{
		C.DrawTile(texture'LoadoutInvBG0', WinWidth, WinHeight, 0.0, 0.0, 256.0, 256.0);
		if (MouseIsOver())
		{
			// draw highlighted background behind mesh
			C.DrawColor = class'ThPlusHUD'.Default.TrueSilverColor;
			C.SetPos(1.0 * scaleY, 1.0 * scaleY);
			TileSize = WinHeight - 2.0 * scaleY;
			C.DrawTile(texture'LoadoutInvBG0', TileSize, TileSize, 4.0, 4.0, 248.0, 248.0);
		}
	}
	else
	{
		C.DrawTile(texture'LoadoutInvBG1', WinWidth, WinHeight, 0.0, 0.0, 256.0, 256.0);
	}

	// draw mesh
	if (displayMesh == None)
	{
		return;
	}
	NewGlow = Glow;
	if (MouseIsOver())
	{
		NewGlow = 2.0;
	}
	PosX = WinLeft + 0.5 * WinHeight;
	PosY = WinTop + 0.5 * WinHeight;
	ThPlusHUD(tpp.myHUD).DrawLoadoutMesh(C, PosX, PosY, WinHeight,
										 displayMesh, displayScale, displayOffset, displayRotation,
										 displaySkin0, displaySkin1, displaySkin2, displaySkin3,
										 NewGlow);

	// draw item quantity
	if (itemQuantity > 1)
	{
		C.Style = 3;
		C.DrawColor = class'ThHUD'.Default.WhiteColor;
		C.Font = ThPlusHUD(tpp.myHUD).SansFontTiny;
		C.TextSize("x"$itemQuantity, TextW, TextH);
		C.SetPos(WinWidth - Pad - TextW, Pad);
		C.DrawText("x"$itemQuantity);
	}
}

function SetupItemDisplay()
{
	local class<ThieveryWeapon> WeaponClass;
	local class<ThieveryAmmo> AmmoClass;
	local class<ThieveryProjectile> ProjectileClass;
	local class<ThieveryPickup> ItemClass;
	local Inventory Item;

	Super.SetupItemDisplay();

	if (Slot == 255)
	{
		return;
	}

	Item = GetItem();
	if (Item == None)
	{
		return;
	}

 	if (Item.IsA('ThieveryWeapon'))
	{
		WeaponClass = class<ThieveryWeapon>(Item.Class);
	}
	else if (Item.IsA('ThieveryAmmo'))
	{
		AmmoClass = class<ThieveryAmmo>(Item.Class);
		if (AmmoClass != None)
		{
			ProjectileClass = AmmoClass.Default.ProjectileClass;
		}
	}
	else if (Item.IsA('ThieveryPickup'))
	{
		ItemClass = class<ThieveryPickup>(Item.Class);
	}

	if (WeaponClass != None || ProjectileClass != None || ItemClass != None)
	{
		class'ThPlusHUD'.static.ApplyLoadoutMeshCorrections(
				WeaponClass, ProjectileClass, ItemClass,
				displayMesh, displayScale, displayOffset, displayRotation,
				displaySkin0, displaySkin1, displaySkin2, displaySkin3, Glow);
	}
}

function Resized()
{
	local float scaleY, PosX, PosY, ButtonWidth, ButtonHeight;
	local int Column, Row;

	scaleY = class'ThHUD'.static.GetScaleY(Root.WinWidth, Root.WinHeight);

	PosX = 0.5 * Root.WinWidth - 512.0 * scaleY + 32.0 * scaleY;
	PosY = 144.0 * scaleY;

	ButtonWidth = 64.0 * scaleY;
	ButtonHeight = 64.0 * scaleY;

	Column = Slot % 5;
	Row = Slot / 5;

	WinLeft = PosX + Column * ButtonWidth;
	WinTop = PosY + Row * ButtonHeight;
	WinWidth = ButtonWidth;
	WinHeight = ButtonHeight;
}

function PaintTooltip(canvas C, float X, float Y)
{
	local float PosX, PosY;
	local ThieveryPPawn tpp;

	if (itemName == "")
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
	ThPlusHUD(tpp.myHUD).PaintTooltip(C, PosX, PosY, itemName, itemDesc);
}

defaultproperties
{
}
