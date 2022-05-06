//=============================================================================
// ThPlusPawn.
//=============================================================================

class ThPlusPawn extends ThieveryProPawn;

var float LastSizeX;             // screen width
var float LastSizeY;             // screen height
var float AspectRatio;           // screen aspect ratio

var float BaseFOV;               // default 4:3 aspect ratio fov
var float RatFOV;                // fov when playing as a rat
var float ZoomOffsetFOV;         // fov subtracted when zooming. scaled by ZoomLevel
var float ZoomAlpha;             // used for easing in/out when zooming

var bool bLastUseFOVCorrection;  // fov is updated when player toggles fov setting
var float LastBaseFOV;           // fov is updated when BaseFOV changes
var float LastAspectRatio;       // fov is updated when AspectRatio changes
var bool bUpdateServerFOV;       // server fov is updated when BaseFOV or AspectRatio change
var float LastUpdateFOVTime;     // don't spam the server with fov updates

var class<Weapon> PVOClass[20];  // every weapon class
var vector DefaultPVO[20];       // default PlayerViewOffset for every weapon class

var Weapon SharedGroupWeapon;    // weapon in inventory group "2" when shared by two weapons

var float CollisionAlpha;        // used for fps independent crouching speed
var float LastCollisionHeight;   // used for smoother EyeHeight when crouching

// enforced by server (see ThPlusConfigServer and ThPlusMutator)
var bool bAllowFOVCorrection;    // allow player to use fov correction
var bool bAllowViewBob;          // allow player to adjust view bob
var bool bAllowRaiseBehindView;  // allow player to raise behind view height
var bool bReplayPendingMove;     // replay the pending move after saved moves
var bool bLimitClientAdjust;     // limit the frequency of client adjustments

//=============================================================================

replication
{
	reliable if (bNetOwner && Role == ROLE_Authority)
		bAllowFOVCorrection, bAllowViewBob, bAllowRaiseBehindView,
		bReplayPendingMove, bLimitClientAdjust, ClientRatFOV, ClientDefaultFOV;
	unreliable if (bNetOwner && Role == ROLE_Authority)
		ClientPlayASound;
	reliable if (Role < ROLE_Authority)
		ServerUpdateFOV, ServerClearOrderingBot, ServerReleaseHook;
}

//=============================================================================

static function float Round(float X)
{
	if (X < 0)
	{
		return int(X - 0.5);
	}
	else if (X > 0)
	{
		return int(X + 0.5);
	}
	return 0;
}

static function vector RoundVector(vector V)
{
	V.X = Round(V.X);
	V.Y = Round(V.Y);
	V.Z = Round(V.Z);
	return V;
}

//=============================================================================

simulated function PreBeginPlay()
{
	DisableAutoFOV();

	Super.PreBeginPlay();

	// no pixelated textures
	class'ThWeaponBlackjack'.Default.bNoSmooth = false;
	class'ThWeaponMace'.Default.bNoSmooth = false;
	class'ThWeaponSword'.Default.bNoSmooth = false;
}

//=============================================================================
// switch to ThWeaponNone to prevent weapon 'None' and phantom weapons

function ResetToDefaultInventory()
{
	SwitchToEmptyWeapon();
	Super.ResetToDefaultInventory();
	if (Weapon == None)
	{
		SwitchToEmptyWeapon();
	}
}

function SafeSellItem(class<Actor> A)
{
	Super.SafeSellItem(A);
	if (Weapon == None)
	{
		SwitchToEmptyWeapon();
	}
}

//=============================================================================
// same as parent but don't draw weapon if fov is changing or player is holding
// an object

simulated event RenderOverlays(canvas C)
{
	RenderListenServerFrobTarget(C);

	if (Weapon != None && Health > 0 && DesiredFOV == DefaultFOV && HeldItem == None)
	{
		Weapon.RenderOverlays(C);
	}

	if (myHUD != None)
	{
		myHUD.RenderOverlays(C);
	}

	RenderSensingEffect(C);
}

// same as parent
simulated function RenderListenServerFrobTarget(canvas C)
{
	if (Role == ROLE_Authority && Level.Netmode == NM_ListenServer
		&& FrobTarget != None && !FrobTarget.bHidden)
	{
		FrobTargetNormalLightType = FrobTarget.LightType;
		FrobTargetNormalScaleGlow = FrobTarget.ScaleGlow;
		FrobTargetNormalAmbientGlow = FrobTarget.AmbientGlow;
		FrobTarget.AmbientGlow = 254;
		FrobTarget.ScaleGlow = 50;
		C.DrawActor(FrobTarget, false, false);
		FrobTarget.AmbientGlow = FrobTargetNormalAmbientGlow;
		FrobTarget.ScaleGlow = FrobTargetNormalScaleGlow;
		FrobTarget.bHidden = false;
	}
}

// same as parent
simulated function RenderSensingEffect(canvas C)
{
	local ThieverySensingEffect Red;

	foreach AllActors(class'ThieverySensingEffect', Red)
	{
		if (Red.bRenderSensingEffect)
		{
			Red.Render(C);
		}
	}
}

//=============================================================================
// fov correction

event PreRender(canvas C)
{
	Super.PreRender(C);

	if (bAllowFOVCorrection)
	{
		if (class'ThPlusConfig'.Default.bUseFOVCorrection != bLastUseFOVCorrection)
		{
			bLastUseFOVCorrection = class'ThPlusConfig'.Default.bUseFOVCorrection;
			LastSizeX = 0.0; // force update
		}

		if (LastSizeX != C.SizeX || LastSizeY != C.SizeY)
		{
			LastSizeX = C.SizeX;
			LastSizeY = C.SizeY;
			if (class'ThPlusConfig'.Default.bUseFOVCorrection)
			{
				AspectRatio = LastSizeX / LastSizeY;
			}
			else
			{
				AspectRatio = 0.0;
			}
		}
	}
	else
	{
		AspectRatio = 0.0;
	}

	if (AspectRatio != LastAspectRatio || BaseFOV != LastBaseFOV)
	{
		LastAspectRatio = AspectRatio;
		LastBaseFOV = BaseFOV;
		UpdateFOV();
		bUpdateServerFOV = true;
	}

	if (Role < ROLE_Authority && bUpdateServerFOV)
	{
		// don't spam the server
		if (Level.TimeSeconds - LastUpdateFOVTime > 1.0 || LastUpdateFOVTime == 0.0)
		{
			bUpdateServerFOV = false;
			LastUpdateFOVTime = Level.TimeSeconds;
			ServerUpdateFOV(AspectRatio, BaseFOV);
		}
	}
}

function ServerUpdateFOV(float NewAspectRatio, float NewBaseFOV)
{
	AspectRatio = NewAspectRatio;
	BaseFOV = NewBaseFOV;
	UpdateFOV();
}

function UpdateFOV()
{
	local int i;

	// player fov correction
	DefaultFOV = GetCorrectedFOV(BaseFOV);
	RatFOV = GetCorrectedFOV(Default.RatFOV);
	if (IsARat())
	{
		DesiredFOV = RatFOV;
		FOVAngle = RatFOV;
	}
	else if (ZoomLevel == 0.0 && !bOnCrack)
	{
		DesiredFOV = DefaultFOV;
		FOVAngle = DefaultFOV;
	}

	// telescope fov correction
	UpdateZoomOffsetFOV();

	// weapon fov correction
	for (i = 0; i < ArrayCount(PVOClass); i++)
	{
		if (PVOClass[i] != None)
		{
			PVOClass[i].Default.PlayerViewOffset = DefaultPVO[i] * DefaultFOV / 90.0;
		}
	}

	// reapply weapon's setHand() scaling
	if (Weapon != None)
	{
		Weapon.PlayerViewOffset = RoundVector(Weapon.Default.PlayerViewOffset * vect(1, -1, 1) * 100.0);
	}
}

function float GetCorrectedFOV(float NewFOV)
{
	if (AspectRatio > 0.0)
	{
		return atan(tan(NewFOV * Pi / 360.0) * AspectRatio / (4.0 / 3.0)) * 360.0 / Pi;
	}
	return NewFOV;
}

function bool IsARat()
{
	return (PlayerReplicationInfo != None && PlayerReplicationInfo.Team == 255 && !bHidden
			&& PlayerReplicationInfo.bIsSpectator && PlayerClass == 74 && ViewTarget == None);
}

function UpdateZoomOffsetFOV()
{
	local float MaxZoomLevel, ZoomFOV;

	MaxZoomLevel = 0.9;
	ZoomFOV = BaseFOV - MaxZoomLevel * Default.ZoomOffsetFOV;
	ZoomFOV = GetCorrectedFOV(ZoomFOV);
	ZoomOffsetFOV = (DefaultFOV - ZoomFOV) / MaxZoomLevel;
}

//=============================================================================
// eye height and zooming
//
// 1. eye height: smoother when collision height changes (crouching)
// 2. zooming: fov correction and easing functions for responsiveness

event UpdateEyeHeight(float DeltaTime)
{
	if (PlayerClass == 74) // rat
	{
		return;
	}

	if (Physics == PHYS_Walking)
	{
		if (CollisionHeight != LastCollisionHeight) // see PlayerWalking state
		{
			EyeHeight += (LastCollisionHeight - CollisionHeight);
			EyeHeight = FClamp(EyeHeight, 0.0, DefaultBaseEyeHeight);
			LastCollisionHeight = CollisionHeight;
		}
	}

	Super.UpdateEyeHeight(DeltaTime);

	if (bZooming && ZoomAlpha < 1.0)
	{
		ZoomAlpha += DeltaTime / 0.3;
		ZoomAlpha = FMin(1.0, ZoomAlpha);
		ZoomLevel = class'ThPlusHUD'.static.EaseOut(0.0, 0.9, ZoomAlpha);
	}
	else if (!bZooming && ZoomAlpha > 0.0)
	{
		ZoomAlpha -= DeltaTime / 0.3;
		ZoomAlpha = FMax(0.0, ZoomAlpha);
		ZoomLevel = class'ThPlusHUD'.static.EaseIn(0.0, 0.9, ZoomAlpha);
	}

	if (ZoomLevel > 0.0)
	{
		DesiredFOV = FClamp(DefaultFOV - (ZoomLevel * ZoomOffsetFOV), 1.0, 170.0);
	}
}

function StartZoom()
{
	ZoomAlpha = 0.0;
	ZoomLevel = 0.0;
	bZooming = true;
}

//=============================================================================
// "set fov" functions
//
// called by ThieveryDeathMatchPlus to reset fov during login and respawn

function SetFOVAngle(float NewFOV)
{
	FOVAngle = GetCorrectedFOV(NewFOV);
}

exec function SetDesiredFOV(float F)
{
	if (DisableAutoFOV())
	{
		F = BaseFOV;
	}

	if (F >= 90.0 || Level.bAllowFOV || bAdmin || Level.Netmode == NM_Standalone)
	{
		BaseFOV = FClamp(F, 1.0, 170.0);
		DefaultFOV = GetCorrectedFOV(BaseFOV);
		DesiredFOV = DefaultFOV;
		SaveConfig();
	}
}

// disable AutoFOV (kentie's d3d10 renderer and its derivatives)
function bool DisableAutoFOV()
{
	local bool bAutoFOV;

	bAutoFOV = bool(ConsoleCommand("get ini:Engine.Engine.GameRenderDevice AutoFOV"));
	if (bAutoFOV)
	{
		ConsoleCommand("set ini:Engine.Engine.GameRenderDevice AutoFOV false");
	}
	return bAutoFOV;
}

//=============================================================================
// crack effect
//
// 1. ThPlusOnCrackEffect resets DesiredFOV to DefaultFOV instead of 90
// 2. OnCrackEffect replaced if spawned elsewhere (see ThPlusReplacer)

function GiveCrack()
{
	Spawn(class'ThPlusOnCrackEffect', Self, , Location, Rotation);
	if (class'ThieveryConfigClient'.Default.bCoverCrack)
	{
		setClientBlindness(ExperimentCrackCover);
	}
}

function GiveCrackArrowEffect()
{
	if (!bOnCrackImmune)
	{
		GiveCrack();
	}
}

//=============================================================================
// fov literals replaced with variables

function ClientResetPlayerEffects()
{
	Super.ClientResetPlayerEffects();
	if (IsARat())
	{
		DesiredFOV = RatFOV;
		FOVAngle = RatFOV;
	}
	else
	{
		DesiredFOV = DefaultFOV;
		FOVAngle = DefaultFOV;
	}
}

function MakeThief()
{
	Super.MakeThief();
	DesiredFOV = DefaultFOV;
	FOVAngle = DefaultFOV;
}

function MakeGuard()
{
	Super.MakeGuard();
	DesiredFOV = DefaultFOV;
	FOVAngle = DefaultFOV;
}

function MakeRat()
{
	Super.MakeRat();
	DesiredFOV = RatFOV;
	FOVAngle = RatFOV;
}

function SpectateRat()
{
	local bool bOldHidden;

	bOldHidden = bHidden;
	Super.SpectateRat();
	if (bOldHidden)
	{
		DesiredFOV = RatFOV;
		FOVAngle = RatFOV;
		ClientRatFOV();
	}
}

state PlayerWaiting
{
	exec function frob()
	{
		Super.frob();
		if (IsARat())
		{
			DesiredFOV = RatFOV;
			FOVAngle = RatFOV;
		}
		else
		{
			DesiredFOV = DefaultFOV;
			FOVAngle = DefaultFOV;
		}
	}

	event PlayerTick(float DeltaTime)
	{
		local float OldDesiredFOV, OldFOVAngle;

		OldDesiredFOV = DesiredFOV;
		OldFOVAngle = FOVAngle;
		Super.PlayerTick(DeltaTime);
		DesiredFOV = OldDesiredFOV;
		FOVAngle = OldFOVAngle;
	}

	function EndState()
	{
		Super.EndState();
		if (PlayerReplicationInfo != None && PlayerReplicationInfo.Team != 255)
		{
			DesiredFOV = DefaultFOV;
			FOVAngle = DefaultFOV;
		}
	}

	function BeginState()
	{
		Super.BeginState();
		DesiredFOV = DefaultFOV;
		FOVAngle = DefaultFOV;
	}
}

state EnterTeamSpectating
{
	function BeginState()
	{
		Super.BeginState();
		DesiredFOV = DefaultFOV;
		FOVAngle = DefaultFOV;
	}
}

function TeamFollowCam()
{
	Super.TeamFollowCam();
	DesiredFOV = DefaultFOV;
	FOVAngle = DefaultFOV;
}

exec function Follow(string s)
{
	if (PlayerReplicationInfo == None || PlayerReplicationInfo.Team != 255)
	{
		return;
	}
	Super.Follow(s);
	if (ViewTarget == None && !bBehindView)
	{
		DesiredFOV = RatFOV;
		FOVAngle = RatFOV;
		ClientRatFOV();
	}
	else
	{
		DesiredFOV = DefaultFOV;
		FOVAngle = DefaultFOV;
		ClientDefaultFOV();
	}
}

function FollowCam()
{
	if (LastFollowCamCommandTime != 0.0 && Level.TimeSeconds < LastFollowCamCommandTime + 1.0)
	{
		return;
	}
	Super.FollowCam();
	if (ViewTarget == None && !bBehindView && !bHidden)
	{
		DesiredFOV = RatFOV;
		FOVAngle = RatFOV;
		ClientRatFOV();
	}
	else
	{
		DesiredFOV = DefaultFOV;
		FOVAngle = DefaultFOV;
		ClientDefaultFOV();
	}
}

simulated function ClientRatFOV()
{
	DesiredFOV = RatFOV;
	FOVAngle = RatFOV;
}

simulated function ClientDefaultFOV()
{
	DesiredFOV = DefaultFOV;
	FOVAngle = DefaultFOV;
}

//=============================================================================
// 1. more fov literals replaced with variables
// 2. rat/spectator hud modified to scale correctly
// 3. fps independent crouching
// 4. player no longer gets stuck when releasing hook

state FreeCam
{
	function BeginState()
	{
		Super.BeginState();
		DesiredFOV = DefaultFOV;
		FOVAngle = DefaultFOV;
	}

	event PostRender(canvas C)
	{
		Global.PostRender(C);
		if (PlayerReplicationInfo != None && PlayerReplicationInfo.Team == 255)
		{
			class'ThPlusRatHUD'.static.Render(C, Self);
		}
	}
}

state PlayerSwimming
{
	event PostRender(canvas C)
	{
		Global.PostRender(C);
		if (PlayerReplicationInfo != None && PlayerReplicationInfo.Team == 255)
		{
			class'ThPlusRatHUD'.static.Render(C, Self);
		}
	}
}

state PlayerWalking
{
	event PostRender(canvas C)
	{
		Global.PostRender(C);
		if (PlayerReplicationInfo != None && PlayerReplicationInfo.Team == 255)
		{
			class'ThPlusRatHUD'.static.Render(C, Self);
		}
	}

	function BeginState()
	{
		Super.BeginState();
		if (!bIsCrouching)
		{
			CollisionAlpha = 0.0;
			LastCollisionHeight = DefaultCollisionHeight;
		}
	}

	function EndState()
	{
		Super.EndState();
		if (!bIsCrouching)
		{
			CollisionAlpha = 0.0;
			LastCollisionHeight = DefaultCollisionHeight;
		}
	}

	function TProcessMove(float DeltaTime, vector NewAccel, eDodgeDir DodgeMove,
						  rotator DeltaRot, byte VelCap, optional float WinchHeight)
	{
		local vector OldAccel, HitLocation, HitNormal, Extent;
		local Actor TempActor;
		local float NewCollisionHeight;

		if (CurrentGrapplingHook != None)
		{
			Super.TProcessMove(DeltaTime, NewAccel, DodgeMove, DeltaRot, VelCap, WinchHeight);
			if (Role < ROLE_Authority && CurrentGrapplingHook == None)
			{
				ServerReleaseHook(); // client released hook, so update server
			}
			return;
		}

		ropeFixPos = 0.0;
		GroundSpeed = Default.GroundSpeed * (MSpeed / 100.0) * (VelCap / 100.0);
		AirSpeed = Default.AirSpeed * (MSpeed / 100.0);
		OldAccel = Acceleration;
		Acceleration = NewAccel;
		bIsTurning = (Abs(DeltaRot.Yaw / DeltaTime) > 5000.0);
		if (bPressedJump)
		{
			DoJump();
		}
		Dodge(DodgeMove);

		if (Mesh != None && (Physics == PHYS_Walking || bInsideLadder)
			&& GetAnimGroup(AnimSequence) != 'Dodge')
		{
			// adjust collision size when crouching
			if (Role == ROLE_Authority && CollisionHeight != TargetCollisionHeight)
			{
				if (bIsCrouching && CollisionHeight > TargetCollisionHeight)
				{
					CollisionAlpha += DeltaTime / 0.2;
				}
				else if (!bIsCrouching && CollisionHeight < TargetCollisionHeight)
				{
					CollisionAlpha -= DeltaTime / 0.2;
				}
				CollisionAlpha = FClamp(CollisionAlpha, 0.0, 1.0);
				NewCollisionHeight = DefaultCollisionHeight + (CrouchHeight - DefaultCollisionHeight) * CollisionAlpha;
				SetCollisionSize(CollisionRadius, NewCollisionHeight);
				PrePivot.Z = Default.PrePivot.Z + (CrouchingPrePivot.Z - Default.PrePivot.Z) * CollisionAlpha;
			}

			// handle crouching and duck key (same as parent)
			if (!bIsCrouching)
			{
				if (bDuck != 0 && bHumanAbilities)
				{
					bIsCrouching = true;
					TargetCollisionHeight = CrouchHeight;
					PlayDuck();
				}
			}
			else if (bDuck == 0 || !bSafeToStand)
			{
				Extent = vect(1, 1, 1);
				Extent *= CollisionRadius * 0.7;
				Extent.Z = 1.0;
				if (bInsideLadder)
				{
					Extent *= 0.1;
				}
				TempActor = Trace(HitLocation, HitNormal, Location + vect(0, 0, 300),
								  Location, true, Extent);
				bSafeToStand = true;

				if (TempActor != None
					&& (TempActor.bBlockPlayers || TempActor.IsA('LevelInfo')))
				{
					RoomAboveHead = (HitLocation.Z - Location.Z);
					if (HitLocation.Z - Location.Z <= Default.CollisionHeight - CrouchHeight)
					{
						bSafeToStand = false;
					}
				}

				if (bSafeToStand)
				{
					bDuck = 0;
					TargetCollisionHeight = DefaultCollisionHeight;
					OldAccel = vect(0, 0, 0);
					bIsCrouching = false;
					TweenToRunning(0.1);
				}
				else
				{
					bDuck = 1;
					bIsCrouching = true;
				}
			}

			// animation related (same as parent)
			if (!bIsCrouching)
			{
				if ((!bAnimTransition || AnimFrame > 0)
					&& GetAnimGroup(AnimSequence) != 'Landing')
				{
					if (Acceleration != vect(0, 0, 0))
					{
						if (GetAnimGroup(AnimSequence) == 'Waiting'
							|| GetAnimGroup(AnimSequence) == 'Gesture'
							|| GetAnimGroup(AnimSequence) == 'TakeHit')
						{
							bAnimTransition = true;
							TweenToRunning(0.1);
						}
					}
					else if (Square(Velocity.X) + Square(Velocity.Y) < 1000.0
							 && GetAnimGroup(AnimSequence) != 'Gesture')
					{
						if (GetAnimGroup(AnimSequence) == 'Waiting')
						{
							if (bIsTurning && AnimFrame >= 0)
							{
								bAnimTransition = true;
								PlayTurning();
							}
						}
						else if (!bIsTurning)
						{
							bAnimTransition = true;
							TweenToWaiting(0.2);
						}
					}
				}
			}
			else
			{
				if (OldAccel == vect(0, 0, 0) && Acceleration != vect(0, 0, 0))
				{
					PlayCrawling();
				}
				else if (!bIsTurning && Acceleration == vect(0, 0, 0) && AnimFrame > 0.1)
				{
					PlayDuck();
				}
			}
		}
		CheckFallingOffLadder();
		OldVelocity = Velocity;
	}
}

function ServerReleaseHook()
{
	if (CurrentGrapplingHook != None)
	{
		CurrentGrapplingHook.ReleaseHook();
	}
}

//=============================================================================
// smoother client movement
//
// 1. replay the pending move after saved moves
// 2. limit the frequency of client adjustments

function ClientUpdatePosition()
{
	Super.ClientUpdatePosition();
	if (bReplayPendingMove && PendingMove != None)
	{
		// replay the pending move
		TMoveAutonomous(PendingMove.Delta, PendingMove.bRun, PendingMove.bDuck,
						PendingMove.bPressedJump, PendingMove.DodgeMove,
						PendingMove.Acceleration, rot(0, 0, 0),
						PendingMove.VelCap, PendingMove.WinchHeight);
	}
}

function TServerMove(float TimeStamp, vector InAccel, vector ClientLoc,
					 byte PackedBits, eDodgeDir DodgeMove, byte ClientRoll,
					 int View, optional byte OldTimeDelta, optional int OldAccel,
					 optional byte VelCap, optional float WinchHeight)
{
	local float OldUpdateTime, ClientErr, DeltaTime;
	local vector LocDiff;

	// discard outdated move
	if (CurrentTimeStamp >= TimeStamp)
	{
		return;
	}

	if (!bLimitClientAdjust)
	{
		Super.TServerMove(TimeStamp, InAccel, ClientLoc, PackedBits, DodgeMove,
						  ClientRoll, View, OldTimeDelta, OldAccel, VelCap, WinchHeight);
		return;
	}

	// bypass parent calling ClientAdjustPosition
	OldUpdateTime = LastUpdateTime;
	LastUpdateTime = Level.TimeSeconds;
	Super.TServerMove(TimeStamp, InAccel, ClientLoc, PackedBits, DodgeMove,
					  ClientRoll, View, OldTimeDelta, OldAccel, VelCap, WinchHeight);
	LastUpdateTime = OldUpdateTime;

	// limit client adjustment rate to once per 100 ms or 20 ms
	DeltaTime = Level.TimeSeconds - LastUpdateTime;
	if (DeltaTime > FMax(500.0 / Player.CurrentNetSpeed, 0.1))
	{
		ClientErr = 10000;
	}
	else if (DeltaTime > FMax(180.0 / Player.CurrentNetSpeed, 0.02))
	{
		LocDiff = Location - ClientLoc;
		ClientErr = LocDiff Dot LocDiff;
	}

	// call ClientAdjustPosition from here instead
	if (ClientErr > 3)
	{
		ClientLoc = Location;
		if (Mover(Base) != None)
		{
			ClientLoc -= Base.Location;
		}
		LastUpdateTime = Level.TimeSeconds;
		ClientAdjustPosition(TimeStamp, GetStateName(), Physics,
							 ClientLoc.X, ClientLoc.Y, ClientLoc.Z,
							 Velocity.X, Velocity.Y, Velocity.Z, Base);
	}
}

//=============================================================================
// bot order window
//
// 1. modified to scale correctly and be user friendly
// 2. OrderingBot is cleared when window closes
// 3. crosshair and tooltip are hidden while ordering a bot (see ThPlusHUD)
// 4. ClientPlayASound prevents sounds emitting from listen server host
// 5. window closes if bot is no longer relevant

function bool SpawnBotOrderWindow()
{
	local WindowConsole Con;
	local UWindowWindow Win;

	Con = WindowConsole(Player.Console);
	if (Con != None)
	{
		if (!Con.bCreatedRoot || Con.Root == None)
		{
			Con.CreateRootWindow(None);
		}
		Win = Con.Root.CreateWindow(class'ThPlusBotWindow', 0, 0, 0, 0);
		if (Win != None)
		{
			if (Con.bShowConsole)
			{
				Con.HideConsole();
			}
			Con.bQuickKeyEnable = true;
			Con.LaunchUWindow();
			ClientPlayASound(sound'TC_PickSnd', SLOT_Interact);
			return true;
		}
	}
	ClearOrderingBot();
	return false;
}

simulated function ClientPlayASound(sound ASound, ESoundSlot Slot)
{
	PlaySound(ASound, Slot);
}

function ClearOrderingBot()
{
	OrderingBot = None;
	if (Role < ROLE_Authority)
	{
		ServerClearOrderingBot();
	}
}

function ServerClearOrderingBot()
{
	OrderingBot = None;
}

//=============================================================================
// adjustable view bob

function CheckBob(float DeltaTime, float Speed2D, vector Y)
{
	Super.CheckBob(DeltaTime, Speed2D, Y);
	if (bAllowViewBob && class'ThPlusConfig'.Default.ViewBob < 1.0)
	{
		UpdateWalkBob();
	}
}

function bool LeanCollision()
{
	local actor HitActor;
	local vector HitLocation, HitNormal, TraceStart, TraceEnd;

	if (bAllowViewBob && class'ThPlusConfig'.Default.ViewBob < 1.0)
	{
		UpdateWalkBob();
		TraceEnd = Location + EyeHeight * vect(0, 0, 1) + WalkBob * 1.1;
		TraceStart = SafeLocation + EyeHeight * vect(0, 0, 1);
		HitActor = Trace(HitLocation, HitNormal, TraceEnd, TraceStart, true, );
		return (HitActor != None);
	}
	else
	{
		return Super.LeanCollision();
	}
}

function UpdateWalkBob()
{
	local rotator SideRotator, LeanRotator;
	local vector ForwardVector, SideVector, LeanVector;

	ForwardVector = vector(ViewRotation);

	SideRotator = ViewRotation + rot(0, 16384, 0);
	if (SideRotator.Yaw > 65535)
	{
		SideRotator.Yaw -= 65536;
	}
	SideVector = vector(SideRotator);

	LeanRotator = LeanDirection + rot(0, 16384, 0);
	if (LeanRotator.Yaw > 65535)
	{
		LeanRotator.Yaw -= 65536;
	}
	LeanVector = vector(LeanRotator);

	WalkBob.X = BobX * 0.5 * SideVector.X + BobY * ForwardVector.X;
	WalkBob.Y = BobX * 0.5 * SideVector.Y + BobY * ForwardVector.Y;
	WalkBob.Z = BobY * BobRangeScale + BobScale * 30.0 * Sin(12.0 * BobTime);

	WalkBob *= class'ThPlusConfig'.Default.ViewBob;

	WalkBob.X += (LeanCurve / 50.0) * LeanVector.X;
	WalkBob.Y += (LeanCurve / 50.0) * LeanVector.Y;
	WalkBob.Z -= Abs(LeanCurve / 50.0) / 25.0;
}

//=============================================================================
// raise behind view height
//
// set to eye height when standing and just below collision height when
// crouching. rat behind view is slightly higher as well

event PlayerCalcView(out actor ViewActor, out vector CameraLocation, out rotator CameraRotation)
{
	Super.PlayerCalcView(ViewActor, CameraLocation, CameraRotation);
	if (bBehindView && bAllowRaiseBehindView && class'ThPlusConfig'.Default.bRaiseBehindView)
	{
		if (ViewTarget != None && !ViewTarget.IsA('ThieveryPPawnLeanActor'))
		{
			if (Pawn(ViewTarget) != None)
			{
				CameraLocation = ViewTarget.Location;
				CameraLocation.Z += 27.0 + 18.0 * Pawn(ViewTarget).EyeHeight / 45.0;
				CalcBehindView(CameraLocation, CameraRotation, 180.0);
			}
			return;
		}
		CameraLocation = Location;
		CameraLocation.Z += 27.0 + 18.0 * EyeHeight / 45.0;
		CalcBehindView(CameraLocation, CameraRotation, 150.0);
	}
}

//=============================================================================
// player input
//
// 1. input scaling no longer assumes default fov is 90, so mouse sensitivity
//    doesn't need to be adjusted whenever the screen resolution changes
// 2. option to completely disable mouse smoothing. unmodded ut99 has partial
//    mouse smoothing applied even with "Mouse Smoothing" unchecked under input
//    preferences

event PlayerInput(float DeltaTime)
{
	local float FOVScale, MouseScale, AbsSmoothX, AbsSmoothY, MouseTime;

	if (bShowMenu && myHUD != None)
	{
		if (myHUD.MainMenu != None)
		{
			myHUD.MainMenu.MenuTick(DeltaTime);
		}
		bEdgeForward = false;
		bEdgeBack = false;
		bEdgeLeft = false;
		bEdgeRight = false;
		bWasForward = false;
		bWasBack = false;
		bWasLeft = false;
		bWasRight = false;
		aStrafe = 0.0;
		aTurn = 0.0;
		aForward = 0.0;
		aLookUp = 0.0;
		return;
	}
	else if (bDelayedCommand)
	{
		bDelayedCommand = false;
		if (TestSkill(DelayedCommand))
		{
			ConsoleCommand(DelayedCommand);
		}
	}

	bEdgeForward = (bWasForward ^^ (aBaseY > 0.0));
	bEdgeBack = (bWasBack ^^ (aBaseY < 0.0));
	bEdgeLeft = (bWasLeft ^^ (aStrafe > 0.0));
	bEdgeRight = (bWasRight ^^ (aStrafe < 0.0));
	bWasForward = (aBaseY > 0.0);
	bWasBack = (aBaseY < 0.0);
	bWasLeft = (aStrafe > 0.0);
	bWasRight = (aStrafe < 0.0);

	FOVScale = DesiredFOV / DefaultFOV; // was DesiredFOV * 0.01111, i.e. DesiredFOV / 90.0
	MouseScale = MouseSensitivity * FOVScale;
	aMouseX *= MouseScale;
	aMouseY *= MouseScale;

	AbsSmoothX = SmoothMouseX;
	AbsSmoothY = SmoothMouseY;
	if (class'ThPlusConfig'.Default.bUseMouseSmoothing)
	{
		MouseTime = (Level.TimeSeconds - MouseZeroTime) / Level.TimeDilation;

		if (bMaxMouseSmoothing && aMouseX == 0.0 && MouseTime < MouseSmoothThreshold)
		{
			SmoothMouseX = 0.5 * (MouseSmoothThreshold - MouseTime) * AbsSmoothX / MouseSmoothThreshold;
			BorrowedMouseX += SmoothMouseX;
		}
		else
		{
			if (SmoothMouseX == 0.0 || aMouseX == 0.0 || (SmoothMouseX > 0.0 != aMouseX > 0.0))
			{
				SmoothMouseX = aMouseX;
				BorrowedMouseX = 0.0;
			}
			else
			{
				SmoothMouseX = 0.5 * (SmoothMouseX + aMouseX - BorrowedMouseX);
				if (SmoothMouseX > 0.0 != aMouseX > 0.0)
				{
					if (aMouseX > 0.0)
					{
						SmoothMouseX = 1.0;
					}
					else
					{
						SmoothMouseX = -1.0;
					}
				}
				BorrowedMouseX = SmoothMouseX - aMouseX;
			}
			AbsSmoothX = SmoothMouseX;
		}

		if (bMaxMouseSmoothing && aMouseY == 0.0 && MouseTime < MouseSmoothThreshold)
		{
			SmoothMouseY = 0.5 * (MouseSmoothThreshold - MouseTime) * AbsSmoothY / MouseSmoothThreshold;
			BorrowedMouseY += SmoothMouseY;
		}
		else
		{
			if (SmoothMouseY == 0.0 || aMouseY == 0.0 || (SmoothMouseY > 0.0 != aMouseY > 0.0))
			{
				SmoothMouseY = aMouseY;
				BorrowedMouseY = 0.0;
			}
			else
			{
				SmoothMouseY = 0.5 * (SmoothMouseY + aMouseY - BorrowedMouseY);
				if (SmoothMouseY > 0.0 != aMouseY > 0.0)
				{
					if (aMouseY > 0.0)
					{
						SmoothMouseY = 1.0;
					}
					else
					{
						SmoothMouseY = -1.0;
					}
				}
				BorrowedMouseY = SmoothMouseY - aMouseY;
			}
			AbsSmoothY = SmoothMouseY;
		}
	}
	else
	{
		SmoothMouseX = aMouseX;
		SmoothMouseY = aMouseY;
		BorrowedMouseX = 0.0;
		BorrowedMouseY = 0.0;
	}

	if (aMouseX != 0.0 || aMouseY != 0.0)
	{
		MouseZeroTime = Level.TimeSeconds;
	}

	// adjust keyboard and joystick movement
	aLookUp *= FOVScale;
	aTurn *= FOVScale;

	// remap x-axis movement
	if (bStrafe != 0)
	{
		aStrafe += aBaseX + SmoothMouseX;
	}
	else
	{
		aTurn += aBaseX * FOVScale + SmoothMouseX;
	}
	aBaseX = 0.0;

	// remap y-axis movement
	if (bStrafe == 0 && (bAlwaysMouseLook || bLook != 0))
	{
		if (bInvertMouse)
		{
			aLookUp -= SmoothMouseY;
		}
		else
		{
			aLookUp += SmoothMouseY;
		}
	}
	else
	{
		aForward += SmoothMouseY;
	}
	SmoothMouseX = AbsSmoothX;
	SmoothMouseY = AbsSmoothY;

	if (bSnapLevel != 0)
	{
		bCenterView = true;
		bKeyboardLook = false;
	}
	else if (aLookUp != 0.0)
	{
		bCenterView = false;
		bKeyboardLook = true;
	}
	else if (bSnapToLevel && !bAlwaysMouseLook)
	{
		bCenterView = true;
		bKeyboardLook = false;
	}

	// remap other y-axis movement
	if (bFreeLook != 0)
	{
		bKeyboardLook = true;
		aLookUp += 0.5 * aBaseY * FOVScale;
	}
	else
	{
		aForward += aBaseY;
	}
	aBaseY = 0.0;

	HandleWalking();
}

//=============================================================================
// weapon switching when inventory group "2" is shared by two weapons
//
// 1. last weapon in inventory group "2" is remembered when switching weapons
// 2. weapon hotbar shows correct weapon (see ThPlusHUD.TrackSharedGroup())

function Weapon TrackSharedGroup(byte F)
{
	local Inventory Inv;
	local Weapon WeaponA, WeaponB;

	for (Inv = Inventory; Inv != None; Inv = Inv.Inventory)
	{
		if (Inv.IsA('Weapon') && Weapon(Inv).InventoryGroup == 2)
		{
			WeaponA = Weapon(Inv);
			for (Inv = Inv.Inventory; Inv != None; Inv = Inv.Inventory)
			{
				if (Inv.IsA('Weapon') && Weapon(Inv).InventoryGroup == 2)
				{
					WeaponB = Weapon(Inv);

					// switch between two weapons in inventory group "2"
					if (F == 2 && Weapon.InventoryGroup == 2)
					{
						if (Weapon == WeaponA)
						{
							SharedGroupWeapon = WeaponB;
						}
						else
						{
							SharedGroupWeapon = WeaponA;
						}
						return SharedGroupWeapon;
					}

					// switch to a weapon in a different inventory group
					if (F != 2 && Weapon.InventoryGroup == 2)
					{
						SharedGroupWeapon = Weapon; // save weapon
						return None;
					}

					// check if saved weapon is valid
					if (SharedGroupWeapon != WeaponA && SharedGroupWeapon != WeaponB)
					{
						SharedGroupWeapon = WeaponA;
					}

					// switch to the saved weapon in inventory group "2"
					if (F == 2 && Weapon.InventoryGroup != 2)
					{
						return SharedGroupWeapon;
					}
					return None;
				}
			}
			return None;
		}
	}
	return None;
}

// same as parent but with TrackSharedGroup() added
exec function SwitchWeapon(byte F)
{
	local Weapon NewWeapon;

	if (CurrentGrapplingHook != None && F != 1)
	{
		return;
	}

	if (HeldItem != None && (F != 1 || (F != 254
		&& !ThieveryGameReplicationInfo(GameReplicationInfo).bClassicInventory)))
	{
		if (!ServerThrowHeldItem())
		{
			return;
		}
	}

	if (bShowMenu || Level.Pauser != "")
	{
		if (myHUD != None)
		{
			myHUD.InputNumber(F);
		}
		return;
	}

	if (Inventory == None)
	{
		return;
	}

	NewWeapon = TrackSharedGroup(F);

	if (NewWeapon == None)
	{
		if (Weapon != None && Weapon.Inventory != None)
		{
			NewWeapon = Weapon.Inventory.WeaponChange(F);
		}

		if (NewWeapon == None)
		{
			NewWeapon = Inventory.WeaponChange(F);
		}

		if (NewWeapon == None)
		{
			return;
		}
	}

	if (Weapon == None)
	{
		PendingWeapon = NewWeapon;
		ChangedWeapon();
	}
	else if (Weapon != NewWeapon)
	{
		PendingWeapon = NewWeapon;
		if (!Weapon.PutDown())
		{
			PendingWeapon = None;
		}
	}
}

//=============================================================================
// show/hide hud screens (reduce screens overlapping and causing confusion)

//-----------------------------------------------------------------------------
// shared functions

function UpdateVisibleHUDScreens(string HUDScreen)
{
	switch (HUDScreen)
	{
		case "PlayerScouting":
		case "PlayerReadingBook":
		case "frobGuardBot":
			StopUsingTelescope();
			HideServerInfo();
			HideObjectives();
			bShowScores = false;
			bShowMapScreen = false;
			break;
		case "Dying":
			HideServerInfo();
			HideObjectives();
			bShowMapScreen = false;
			break;
		case "ShowScores":
			StopUsingScoutingOrb();
			StopReading();
			HideServerInfo();
			HideObjectives();
			bShowMapScreen = false;
			break;
		case "ShowServerInfo": // see ThPlusHUD.ShowServerInfo()
			StopUsingScoutingOrb();
			StopReading();
			HideObjectives();
			bShowScores = false;
			bShowMapScreen = false;
			break;
		case "TelescopeOn":
			StopReading();
			bShowMapScreen = false;
			break;
		case "ViewMapScreen":
			StopUsingScoutingOrb();
			StopReading();
			StopUsingTelescope();
			HideServerInfo();
			HideObjectives();
			bShowScores = false;
			break;
		case "ViewObjectives":
			StopUsingScoutingOrb();
			StopReading();
			HideServerInfo();
			bShowScores = false;
			bShowMapScreen = false;
			break;
		default:
			log("UpdateVisibleHUDScreens() invalid input: "$HUDScreen);
			break;
	}
}

function StopUsingTelescope()
{
	if (bUsingScope)
	{
		TelescopeOff();
	}
}

function HideServerInfo()
{
	if (ThHUD(myHUD) != None)
	{
		ThHUD(myHUD).bShowInfo = false;
	}
}

function HideObjectives()
{
	if (GetStateName() != 'PlayerWaiting')
	{
		bShowObjectives = 0;
	}
}

function StopUsingScoutingOrb()
{
	if (ThProjectileScoutingOrbD(ViewTarget) != None || GetStateName() == 'PlayerScouting')
	{
		StopScouting();
	}
}

function StopReading()
{
	if (CurrentReadBook != None || GetStateName() == 'PlayerReadingBook')
	{
		GotoState('PlayerWalking');
		StopReadingBook();
	}
}

//-----------------------------------------------------------------------------
// additions to show/hide various hud screens

state PlayerScouting
{
	function BeginState()
	{
		UpdateVisibleHUDScreens("PlayerScouting");
		Super.BeginState();
	}

	exec function Fire(optional float F)
	{
		ViewRotation = Rotation;
		StopScouting();
	}

	exec function Interact()
	{
		ViewRotation = Rotation;
		StopScouting();
	}
}

state PlayerReadingBook
{
	simulated function BeginState()
	{
		UpdateVisibleHUDScreens("PlayerReadingBook");
		Super.BeginState();
	}
}

state Dying
{
	function BeginState()
	{
		UpdateVisibleHUDScreens("Dying");
		Super.BeginState();
	}
}

exec function ShowScores()
{
	if (!bShowScores)
	{
		UpdateVisibleHUDScreens("ShowScores");
	}
	bShowScores = !bShowScores;
}

exec function TelescopeOn()
{
	UpdateVisibleHUDScreens("TelescopeOn");
	Super.TelescopeOn();
}

exec function ViewMapScreen()
{
	if (!bShowMapScreen)
	{
		UpdateVisibleHUDScreens("ViewMapScreen");
	}
	bShowMapScreen = !bShowMapScreen;
}

exec function ViewObjectives()
{
	local ThieveryGameReplicationInfo GRI;

	UpdateVisibleHUDScreens("ViewObjectives");
	GRI = ThieveryGameReplicationInfo(GameReplicationInfo);
	if (GRI != None && GRI.bThiefMatch)
	{
		// only show thief objectives
		bShowObjectives = int(bShowObjectives != 1);
	}
	else
	{
		Super.ViewObjectives();
	}
}

simulated function bool frobGuardBot()
{
	if (Super.frobGuardBot())
	{
		UpdateVisibleHUDScreens("frobGuardBot");
		return true;
	}
	return false;
}

//-----------------------------------------------------------------------------
// extra hotkeys to close map screen

function bool HideMap()
{
	if (bShowMapScreen && !bShowMenu)
	{
		bShowMapScreen = false;
		return true;
	}
	return false;
}

exec function Fire(optional float F)
{
	if (HideMap())
	{
		return;
	}
	Super.Fire(F);
}

exec function Interact()
{
	if (HideMap())
	{
		return;
	}
	Super.Interact();
}

exec function frob()
{
	if (HideMap())
	{
		return;
	}
	Super.frob();
}

exec function frobInventoryItem()
{
	if (HideMap())
	{
		return;
	}
	Super.frobInventoryItem();
}

//=============================================================================
// misc.

simulated function PostBeginPlay()
{
	// bypass ThieveryProPawn, ThPlusScoreboard handles bLimitAIInfo now
	Super(ThieveryPPawn).PostBeginPlay();
}

simulated event PostNetBeginPlay()
{
	if (Role != ROLE_SimulatedProxy)
	{
		return;
	}

	// removed log line to prevent "Accessed None" warnings, otherwise same as parent
	if (bIsMultiSkinned)
	{
		if (MultiSkins[1] == None)
		{
			if (bIsPlayer)
			{
				ThSetMesh();
			}
			else
			{
				SetMultiSkin(Self, "", "", 0);
			}
		}
	}
	else if (Skin == None)
	{
		Skin = Default.Skin;
	}

	if (PlayerReplicationInfo != None && PlayerReplicationInfo.Owner == None)
	{
		PlayerReplicationInfo.SetOwner(Self);
	}
}

simulated function DoClientActivateItem()
{
	if (HeldItem != None)
	{
		return;
	}

	if (!ThieveryGameReplicationInfo(GameReplicationInfo).bClassicInventory)
	{
		return;
	}

	if (!bClientsideInventory)
	{
		ActivateItem();
		return;
	}

	// added check to prevent "Accessed None" warnings, otherwise same as parent
	if (ClientSelectedItem != None)
	{
		ThUsePickup(class<Pickup>(ClientSelectedItem.class));
	}
}

//=============================================================================

defaultproperties
{
	bAllowFOVCorrection=true
	bAllowViewBob=true
	bAllowRaiseBehindView=true
	bReplayPendingMove=true
	bLimitClientAdjust=true
	LastBaseFOV=90.0
	BaseFOV=90.0
	RatFOV=120.0
	ZoomOffsetFOV=70.0
	PVOClass(0)=class'ThWeaponArrowGun'
	PVOClass(1)=class'ThWeaponBlackjack'
	PVOClass(2)=class'ThWeaponBow'
	PVOClass(3)=class'ThWeaponBowLightweight'
	PVOClass(4)=class'ThWeaponCrossbow'
	PVOClass(5)=class'ThWeaponCrossbowOld'
	PVOClass(6)=class'ThWeaponCrossbowRepeating'
	PVOClass(7)=class'ThWeaponFists'
	PVOClass(8)=class'ThWeaponFistsOld'
	PVOClass(9)=class'ThWeaponHeldItem'
	PVOClass(10)=class'ThWeaponInventoryItem'
	PVOClass(11)=class'ThWeaponLantern'
	PVOClass(12)=class'ThWeaponMace'
	PVOClass(13)=class'ThWeaponNone'
	PVOClass(14)=class'ThWeaponRatClaws'
	PVOClass(15)=class'ThWeaponShockRifle'
	PVOClass(16)=class'ThWeaponSword'
	PVOClass(17)=class'ThPlusWeaponBow'
	PVOClass(18)=class'ThPlusWeaponBowLight'
	PVOClass(19)=class'ThPlusWeaponCrossbow'
	DefaultPVO(0)=(X=25.000000,Y=-4.000000,Z=-3.000000)
	DefaultPVO(1)=(X=60.000000,Y=-25.000000,Z=25.000000)
	DefaultPVO(2)=(X=-25.000000,Y=20.000000,Z=-5.000000)
	DefaultPVO(3)=(X=-25.000000,Y=20.000000,Z=-5.000000)
	DefaultPVO(4)=(X=16.799999,Y=0.000000,Z=-9.000000)
	DefaultPVO(5)=(X=25.000000,Y=-4.000000,Z=-5.000000)
	DefaultPVO(6)=(X=16.799999,Y=0.000000,Z=-9.000000)
	DefaultPVO(7)=(X=25.000000,Y=0.400000,Z=-5.000000)
	DefaultPVO(8)=(X=25.000000,Y=0.400000,Z=-5.000000)
	DefaultPVO(9)=(X=-5.000000,Y=-10.000000,Z=-14.000000)
	DefaultPVO(10)=(X=30.000000,Y=0.000000,Z=-5.000000)
	DefaultPVO(11)=(X=12.000000,Y=-22.000000,Z=-12.000000)
	DefaultPVO(12)=(X=12.000000,Y=-7.800000,Z=-34.400002)
	DefaultPVO(13)=(X=0.000000,Y=0.000000,Z=-5.000000)
	DefaultPVO(14)=(X=-300.799988,Y=-100.599998,Z=-100.800003)
	DefaultPVO(15)=(X=4.400000,Y=-1.700000,Z=-1.600000)
	DefaultPVO(16)=(X=12.000000,Y=-22.000000,Z=-12.000000)
	DefaultPVO(17)=(X=-25.000000,Y=20.000000,Z=-5.000000)
	DefaultPVO(18)=(X=-25.000000,Y=20.000000,Z=-5.000000)
	DefaultPVO(19)=(X=16.799999,Y=0.000000,Z=-9.000000)
}
