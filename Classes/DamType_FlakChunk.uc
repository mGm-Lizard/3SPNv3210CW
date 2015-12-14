class DamType_FlakChunk extends DamTypeFlakChunk;

static function IncrementKills(Controller Killer)
{
	local xPlayerReplicationInfo xPRI;

	xPRI = xPlayerReplicationInfo(Killer.PlayerReplicationInfo);
	if ( xPRI != None )
	{
		xPRI.flakcount++;
		if ((xPRI.flakcount == 5) && (UnrealPlayer(Killer) != None))
			UnrealPlayer(Killer).ClientDelayedAnnouncementNamed('FlackMonkey',15);
	}
}

defaultproperties
{
}
