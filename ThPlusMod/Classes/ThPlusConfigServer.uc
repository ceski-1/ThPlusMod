//=============================================================================
// ThPlusConfigServer.
//=============================================================================

class ThPlusConfigServer extends Info config(ThieveryMod);

var globalconfig bool bAllowFOVCorrection;    // allow player to use fov correction
var globalconfig bool bAllowViewBob;          // allow player to adjust view bob
var globalconfig bool bAllowRaiseBehindView;  // allow player to raise behind view height
var globalconfig bool bReplayPendingMove;     // replay the pending move after saved moves
var globalconfig bool bLimitClientAdjust;     // limit the frequency of client adjustments
var globalconfig int MinNetSpeed;             // min client netspeed
var globalconfig int MaxNetSpeed;             // max client netspeed (max framerate = netspeed / 64)

defaultproperties
{
	bAllowFOVCorrection=true
	bAllowViewBob=true
	bAllowRaiseBehindView=true
	bReplayPendingMove=true
	bLimitClientAdjust=true
	MinNetSpeed=2600
	MaxNetSpeed=10000
}
