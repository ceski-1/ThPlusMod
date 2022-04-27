//=============================================================================
// ThPlusLoadoutButton.
//=============================================================================

class ThPlusLoadoutButton extends WindowButtonNoKeyboard;

var font ScaledFont;
var color ButtonColor, ButtonColorOver, ButtonColorDown;
var color TextColorDown;

function Created()
{
	Super.Created();
	HideWindow();
}

function Paint(canvas C, float X, float Y)
{
	if (MouseIsOver())
	{
		if (bMouseDown)
		{
			DrawButton(C, DownTexture, ButtonColorDown, TextColorDown);
		}
		else
		{
			DrawButton(C, OverTexture, ButtonColorOver, TextColorOver);
		}
	}
	else
	{
		DrawButton(C, UpTexture, ButtonColor, TextColor);
	}
}

function DrawButton(canvas C, texture Tex, color NewButtonColor, color NewTextColor)
{
	local float TextW, TextH, PosX, PosY;

	if (Tex != None && ScaledFont != None)
	{
		C.bNoSmooth = false;

		C.Style = 1;
		C.DrawColor = NewButtonColor;
		DrawStretchedTexture(C, 0.0, 0.0, WinWidth, WinHeight, Tex);

		C.Style = 3;
		C.DrawColor = NewTextColor;
		C.Font = ScaledFont;
		C.TextSize(Text, TextW, TextH);
		PosX = 0.5 * (WinWidth - TextW);
		PosY = 0.5 * (WinHeight - TextH);
		ClipText(C, PosX, PosY, Text);
	}
}

defaultproperties
{
	ButtonColor=(R=160,G=160,B=160)
	ButtonColorOver=(R=255,G=255,B=255)
	ButtonColorDown=(R=127,G=127,B=127)
	TextColor=(R=128,G=118,B=108)
	TextColorOver=(R=255,G=255,B=255)
	TextColorDown=(R=96,G=89,B=81)
	UpTexture=texture'ChunkyButton'
	DownTexture=texture'ChunkyButton'
	OverTexture=texture'ChunkyButton'
	OverSound=sound'TC_OverSnd'
	DownSound=sound'TC_PickSnd'
}
