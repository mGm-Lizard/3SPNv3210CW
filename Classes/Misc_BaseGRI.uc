class Misc_BaseGRI extends GameReplicationInfo;

var string Version;
var string Acronym;

var int RoundTime;
var int RoundMinute;
var int CurrentRound;
var bool bEndOfRound;
var bool bGamePaused;

var int MinsPerRound;
var int OTDamage;
var int OTInterval;

var int StartingHealth;
var int StartingArmor;
var float MaxHealth;

var float CampThreshold;
var bool bKickExcessiveCampers;

var bool bForceRUP;
var int ForceRUPMinPlayers;

var bool bDisableSpeed;
var bool bDisableBooster;
var bool bDisableInvis;
var bool bDisableBerserk;

var int  TimeOuts;

var bool EnableNewNet;

var string ShieldTextureName;
var string FlagTextureName;
var bool ShowServerName;
var bool FlagTextureEnabled;
var bool FlagTextureShowAcronym;

var string SoundAloneName;
var string SoundSpawnProtectionName;

replication
{
    reliable if(bNetInitial && Role == ROLE_Authority)
        RoundTime, MinsPerRound, bDisableSpeed, bDisableBooster, bDisableInvis,
        bDisableBerserk, StartingHealth, StartingArmor, MaxHealth, OTDamage,
        OTInterval, CampThreshold, bKickExcessiveCampers, bForceRUP, ForceRUPMinPlayers,
        TimeOuts, Acronym, EnableNewNet, ShieldTextureName, ShowServerName,
        FlagTextureEnabled, FlagTextureName, FlagTextureShowAcronym, SoundAloneName,
        SoundSpawnProtectionName;

    reliable if(!bNetInitial && bNetDirty && Role == ROLE_Authority)
        RoundMinute;

    reliable if(bNetDirty && Role == ROLE_Authority)
        CurrentRound, bEndOfRound, bGamePaused;
}

simulated function Timer()
{
    Super.Timer();

    if(Level.NetMode == NM_Client)
    {
        if(RoundMinute > 0)
        {
            RoundTime = RoundMinute;
            RoundMinute = 0;
        }

        if(RoundTime > 0 && !bStopCountDown)
            RoundTime--;
    }
}

defaultproperties
{
     Version="3.210CW"
	 EnableNewNet=True
}
