//=============================================================================
// ThPlusLoadoutEditBox.
//=============================================================================

class ThPlusLoadoutEditBox extends ThEditBox;

var float LastKeyTime;

function Created()
{
	Super(UWindowDialogControl).Created();
	HideWindow();
}

function KeyUp(int Key, float X, float Y)
{
	local PlayerPawn P;

	P = GetPlayerOwner();
	switch (Key)
	{
		case P.EInputKey.IK_Enter:
			if (ThLoadoutClientWindow(ParentWindow).ShopPage == 0)
			{
				ThLoadoutClientWindow(ParentWindow).WeaponsTab.LMouseDown(0, 0);
				ThLoadoutClientWindow(ParentWindow).WeaponsTab.LMouseUp(0, 0);
			}
			else
			{
				ThLoadoutClientWindow(ParentWindow).ItemsTab.LMouseDown(0, 0);
				ThLoadoutClientWindow(ParentWindow).ItemsTab.LMouseUp(0, 0);
			}
			break;
		default:
			Super(UWindowEditBox).KeyUp(Key, X, Y);
			break;
	}
}

function Paint(canvas C, float X, float Y)
{
	local float TextW, TextH;
	local float PosY;
	local float ScaleY;

	C.Style = 3;
	C.DrawColor = TextColor;
	C.Font = class'ThPlusLoadoutWindow'.static.GetFont(WinHeight, 0.5);
	TextSize(C, " ", TextW, TextH);
	PosY = 0.5 * (WinHeight - TextH);

	TextSize(C, Left(Value, CaretOffset), TextW, TextH);
	if (TextW + Offset < 0.0)
	{
		Offset = -TextW;
	}

	if (TextW + Offset > WinWidth - 2.0)
	{
		Offset = (WinWidth - 2.0) - TextW;
		Offset = FMin(0.0, Offset);
	}

	if (bAllSelected)
	{
		C.DrawColor = class'TInfo'.static.GetColor(96, 96, 96);
		DrawStretchedTexture(C, Offset + 1.0, PosY, TextW, TextH, texture'WhiteTexture');
		C.DrawColor = TextColor;
	}
	ClipText(C, Offset + 1.0, PosY, Value);

	if (!bHasKeyboardFocus || !bCanEdit)
	{
		bShowCaret = False;
	}
	else
	{
		if (GetLevel().TimeSeconds - LastDrawTime > 0.3)
		{
			LastDrawTime = GetLevel().TimeSeconds;
			bShowCaret = !bShowCaret;
		}
	}

	if (bShowCaret)
	{
		ClipText(C, FMax(0.0, Offset + TextW - 1.0), PosY, "|");
	}
}

defaultproperties
{
	bCanEdit=true
	bDelayedNotify=true
	bAlwaysOnTop=true
	MaxLength=25
	TextColor=(R=255,G=255,B=255)
}
