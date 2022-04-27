//=============================================================================
// ThPlusRadarController.
//=============================================================================

class ThPlusRadarController extends ThreatIndicatorController;

simulated function PostRender(canvas C)
{
	local int i, Radius, BlipX, BlipY;
	local float dT, ScaleY, PosX, PosY, DeltaZ, BlipScale;
	local vector VectXY;
	local bool bInnerVisible;
	local Texture Tex;

	if (NextHUDMutator != None)
	{
		NextHUDMutator.PostRender(C);
	}

	if (Level.NetMode == NM_DedicatedServer)
	{
		return;
	}

	// update blip visibility
	dT = Level.TimeSeconds - fLastRenderTime;
	fLastRenderTime = Level.TimeSeconds;
	for (i = 0; i < ArrayCount(BlipArray); i++)
	{
		if (BlipArray[i].bActive)
		{
			VectXY = vect(1, 1, 0) * (BlipArray[i].Location - Owner.Location);
			if (VSize(VectXY) < MinRangeForDirectional)
			{
				bInnerVisible = true;
				BlipAlpha[i] -= dT / fFadeTime;
			}
			else
			{
				BlipAlpha[i] += dT / fFadeTime;
			}
			BlipAlpha[i] = FClamp(BlipAlpha[i], 0.0, 1.0);
		}
	}
	if (bInnerVisible)
	{
		fInnerAlpha += dT / fFadeTime;
	}
	else
	{
		fInnerAlpha -= dT / fFadeTime;
	}
	fInnerAlpha = FClamp(fInnerAlpha, 0.0, 1.0);

	// set reference point and scale
	PosX = 0.5 * C.ClipX;
	ScaleY = class'ThHUD'.static.GetScaleY(C.ClipX, C.ClipY);
	PosY = 8.0 * ScaleY;
	PosY += 0.5 * BackgroundTexture.VSize * ScaleY;

	// draw background
	C.Reset();
	C.Style = 3;
	C.CurX = PosX - 0.5 * BackgroundTexture.USize * ScaleY;
	C.CurY = PosY - 0.5 * BackgroundTexture.VSize * ScaleY;
	C.DrawIcon(BackgroundTexture, ScaleY);

	// draw inner blip
	if (fInnerAlpha > 0)
	{
		C.DrawColor = class'ThHUD'.Default.WhiteColor * fInnerAlpha;
		C.CurX = PosX - 0.5 * CentreBlipTexture.USize * ScaleY;
		C.CurY = PosY - 0.5 * CentreBlipTexture.VSize * ScaleY;
		C.DrawIcon(CentreBlipTexture, ScaleY);
	}

	// draw outer blips
	for (i = 0; i < ArrayCount(BlipArray); i++)
	{
		if (BlipArray[i].bActive && BlipAlpha[i] > 0.0)
		{
			VectXY = vect(1, 1, 0) * (BlipArray[i].Location - Owner.Location);
			Radius = (0.5 * BackgroundTexture.USize - nBlipRadiusInset) * ScaleY;
			GetBlipRadarCoords(VectXY, Radius, BlipX, BlipY);
			BlipScale = 0.5 * ScaleY * BlipAlpha[i];

			DeltaZ = BlipArray[i].Location.Z - Owner.Location.Z;
			if (DeltaZ > 128.0)
			{
				Tex = BlipAboveTexture;
			}
			else if (DeltaZ < -128.0)
			{
				Tex = BlipBelowTexture;
			}
			else
			{
				Tex = BlipTexture;
			}

			C.DrawColor = class'ThHUD'.Default.WhiteColor * BlipAlpha[i];
			C.CurX = PosX + BlipX - 0.5 * Tex.USize * BlipScale;
			C.CurY = PosY + BlipY - 0.5 * Tex.VSize * BlipScale;
			C.DrawIcon(Tex, BlipScale);
		}
	}
}

defaultproperties
{
}
