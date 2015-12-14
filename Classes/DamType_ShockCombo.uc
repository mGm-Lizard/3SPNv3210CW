class DamType_ShockCombo extends DamTypeShockCombo;

static function IncrementKills(Controller Killer)
{
	local xPlayerReplicationInfo xPRI;
	
	xPRI = xPlayerReplicationInfo(Killer.PlayerReplicationInfo);
	if ( xPRI != None )
	{
		xPRI.combocount++;
		if ( (xPRI.combocount == 5) && (UnrealPlayer(Killer) != None) )
			UnrealPlayer(Killer).ClientDelayedAnnouncementNamed('ComboWhore',15);
	}
}

defaultproperties
{
}
