//=============================================================================
// ThPlusBotButton.
//=============================================================================

class ThPlusBotButton extends UWindowButton;

#exec TEXTURE IMPORT NAME=BotButtonDisabled FILE=Textures\BotButtonDisabled.pcx GROUP=Icons MIPS=ON

var ThPlusPawn tpp;
var float Pad;

function Created()
{
	Super.Created();
	HideWindow();
}

function Paint(canvas C, float X, float Y)
{
	local float ButtonW, ButtonH, PosX, PosY, TextW, TextH;
	local texture Tex;

	tpp = ThPlusPawn(GetPlayerOwner());
	if (tpp == None || ThHUD(tpp.myHUD) == None)
	{
		return;
	}

	C.bNoSmooth = false;
	C.Style = 3;

	if (bDisabled)
	{
		C.DrawColor = class'TInfo'.static.GetColor(32, 32, 32);
		Tex = texture'BotButtonDisabled';
	}
	else
	{
		if (MouseIsOver())
		{
			// draw highlight
			C.DrawColor = class'TInfo'.static.GetColor(16, 16, 16);
			DrawStretchedTexture(C, 0, 0, WinWidth, WinHeight, texture'GreyBackground');

			if (bMouseDown)
			{
				C.DrawColor = class'TInfo'.static.GetColor(112, 112, 112);
				Tex = texture'BotOrderButtonDown';
			}
			else
			{
				C.DrawColor = class'ThHUD'.Default.WhiteColor;
				Tex = texture'BotOrderButtonOver';
			}
		}
		else
		{
			C.DrawColor = class'ThPlusHUD'.Default.TrueSilverColor;
			Tex = texture'BotOrderButtonUp';
		}
	}

	ButtonH = WinHeight - 2.0 * Pad;
	ButtonW = ButtonH;

	// draw text
	C.Font = ThHUD(tpp.myHUD).MyFontSmall;
	PosX = Pad + ButtonW + Pad;
	Text = class'ThPlusHUD'.static.TrimText(C, Text, WinWidth - PosX - Pad);
	C.TextSize(Text, TextW, TextH);
	PosY = 0.5 * WinHeight - 0.5 * TextH;
	C.SetPos(PosX, PosY);
	C.DrawText(Text);

	// draw button
	C.Style = 1;
	C.DrawColor = class'ThHUD'.Default.WhiteColor;
	DrawStretchedTexture(C, Pad, Pad, ButtonW, ButtonH, Tex);

	C.bNoSmooth = true;
}

simulated function MouseEnter()
{
	if (!bDisabled)
	{
		Notify(DE_MouseEnter);
		if (tpp != None)
		{
			tpp.ClientPlayASound(sound'TC_OverSnd', SLOT_Interface);
		}
	}
}

simulated function Click(float X, float Y)
{
	if (!bDisabled)
	{
		Notify(DE_Click);
		if (tpp != None)
		{
			tpp.ClientPlayASound(sound'TC_PickSnd', SLOT_Interact);
		}
	}
}

function KeyDown(int Key, float X, float Y)
{
}

defaultproperties
{
}
