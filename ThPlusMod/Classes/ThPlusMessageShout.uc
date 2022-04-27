//=============================================================================
// ThPlusMessageShout.
//=============================================================================

class ThPlusMessageShout extends ThShoutMessage;

var color TeamPrefixColor[2], PlayerNameColor[2];
var string TeamPrefix[2];

static function RenderComplexMessage(canvas C, out float XL, out float YL,
									 optional string MessageString,
									 optional int Switch,
									 optional PlayerReplicationInfo RelatedPRI_1,
									 optional PlayerReplicationInfo RelatedPRI_2,
									 optional Object OptionalObject)
{
	local float PosX, PosY;

	PosX = C.CurX;
	PosY = C.CurY;
	if (RelatedPRI_1 == None || RelatedPRI_1.PlayerName == "")
	{
		DrawBasicMessage(C, PosX, PosY, MessageString);
		return;
	}
	DrawMessage(C, PosX, PosY, MessageString, RelatedPRI_1);
}

static function DrawBasicMessage(canvas C, float PosX, float PosY,
								 string MessageString)
{
	DrawMessageBackground(C, PosX, PosY, MessageString, None);
	C.Style = 3;
	C.SetPos(PosX, PosY);
	C.DrawColor = Default.GreenColor;
	C.DrawText("Some taffer says: ", false);
	C.DrawColor = class'ThHUD'.Default.WhiteColor;
	C.CurY = PosY;
	C.DrawText(MessageString, false);
}

static function DrawMessage(canvas C, float PosX, float PosY,
							string MessageString,
							PlayerReplicationInfo RelatedPRI_1)
{
	DrawMessageBackground(C, PosX, PosY, MessageString, RelatedPRI_1);
	C.Style = 3;
	C.SetPos(PosX, PosY);

	// draw team prefix and player name
	if (RelatedPRI_1.Team < 2)
	{
		C.DrawColor = Default.TeamPrefixColor[RelatedPRI_1.Team];
		C.DrawText(GetPrefix(RelatedPRI_1), false);
		C.DrawColor = Default.PlayerNameColor[RelatedPRI_1.Team];
		C.CurY = PosY;
	}
	else
	{
		C.DrawColor = Default.GreenColor;
	}
	C.DrawText(RelatedPRI_1.PlayerName, false);

	// draw verb
	C.DrawColor = C.DrawColor * 0.75;
	C.CurY = PosY;
	C.DrawText(Default.infix, false);

	// draw message
	C.DrawColor = class'ThHUD'.Default.WhiteColor;
	C.CurY = PosY;
	C.DrawText(MessageString, false);
}

static function DrawMessageBackground(canvas C, float PosX, float PosY,
									  string MessageString,
									  PlayerReplicationInfo RelatedPRI_1)
{
	local float TextW, TextH;

	C.Style = 4;
	C.SetPos(PosX - 6.0, PosY);
	C.StrLen(AssembleString(None, , RelatedPRI_1, MessageString), TextW, TextH);
	C.DrawTile(texture'GreyBackground', TextW + 6.0, TextH, 0.0, 0.0, 32.0, 32.0);
}

static function string GetPrefix(PlayerReplicationInfo RelatedPRI_1)
{
	if (RelatedPRI_1.Team < 2)
	{
		return Default.TeamPrefix[RelatedPRI_1.Team];
	}
	return "";
}

defaultproperties
{
	TeamPrefixColor(0)=(R=255,G=26,B=68)
	TeamPrefixColor(1)=(R=26,G=148,B=255)
	PlayerNameColor(0)=(R=229,G=184,B=192)
	PlayerNameColor(1)=(R=184,G=192,B=229)
	TeamPrefix(0)="[T] "
	TeamPrefix(1)="[G] "
}
