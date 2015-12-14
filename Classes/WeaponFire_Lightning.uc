class WeaponFire_Lightning extends SniperFire;

event ModeDoFire()
{
    Misc_PRI(xPawn(Weapon.Owner).PlayerReplicationInfo).Sniper.Fired += load;
    Super.ModeDoFire();
}

defaultproperties
{
     DamageTypeHeadShot=Class'3SPNv3210CW.DamType_Headshot'
}
