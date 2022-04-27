//=============================================================================
// ThPlusEndgame.
//=============================================================================

class ThPlusEndgame extends ThEndgameSequence;

simulated function DisplayThiefVictory(canvas C)
{
	DrawBackground(C, texture'ThiefVictory');
}

static function DrawBackground(canvas C, texture Tex)
{
	local float ScaleY, TexW, TexH;

	C.Reset();
	C.DrawColor = class'ThHUD'.Default.WhiteColor;
	C.DrawRect(texture'BlackTexture', C.ClipX, C.ClipY);
	ScaleY = class'ThHUD'.static.GetScaleY(C.ClipX, C.ClipY);
	TexW = (Tex.USize - 1.0) * ScaleY;
	TexH = Tex.VSize * ScaleY;
	C.SetPos(0.5 * (C.ClipX - TexW), 0.5 * (C.ClipY - TexH));
	C.DrawTile(Tex, TexW, TexH, 0.0, 0.0, Tex.USize - 1.0, Tex.VSize);
	C.Reset();
}

defaultproperties
{
}
