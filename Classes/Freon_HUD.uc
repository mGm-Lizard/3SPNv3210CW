class Freon_HUD extends TAM_HUD;

#exec TEXTURE IMPORT NAME=Flake FILE=Textures\flake5.tga GROUP=Textures MIPS=On ALPHA=1 DXT=5

var Texture FrozenBeacon;

var float ThawBarWidth;
var float ThawBarHeight;
var Texture ThawBackMat;
var Texture ThawBarMat;

static function bool IsTargetInFrontOfPlayer( Canvas C, Actor Target, out Vector ScreenPos,
											 Vector CamLoc, Rotator CamRot )
{
	// Is Target located behind camera ?
	if((Target.Location - CamLoc) Dot vector(CamRot) < 0)
		return false;

	// Is Target on visible canvas area ?
	ScreenPos = C.WorldToScreen(Target.Location + vect(0,0,1) * Target.CollisionHeight);
	if(ScreenPos.X <= 0 || ScreenPos.X >= C.ClipX)
        return false;
	if(ScreenPos.Y <= 0 || ScreenPos.Y >= C.ClipY)
        return false;

	return true;
}

function DrawCustomBeacon(Canvas C, Pawn P, float ScreenLocX, float ScreenLocY)
{
    local vector ScreenLoc;
    local vector CamLoc;
    local rotator CamRot;
    local float distance;
    local float scaledist;
    local float scale;
	local float XL, YL;
    local byte pawnTeam, ownerTeam;
    local string info;
	local string name;

	if((FrozenBeacon == None) || (P.PlayerReplicationInfo == None) || P.PlayerReplicationInfo.Team == None)
		return;

    pawnTeam = P.PlayerReplicationInfo.Team.TeamIndex;
    ownerTeam = PlayerOwner.GetTeamNum();

    if(!PlayerOwner.PlayerReplicationInfo.bOnlySpectator && pawnTeam != ownerTeam)
    	return;

    C.GetCameraLocation(CamLoc, CamRot);

    distance = VSize(CamLoc - P.Location);
    if(distance > PlayerOwner.TeamBeaconMaxDist)
		return;

    if(!IsTargetInFrontOfPlayer(C, P, ScreenLoc, CamLoc, CamRot) || !FastTrace(P.Location, CamLoc))
        return;

    scaledist = PlayerOwner.TeamBeaconMaxDist * FClamp(0.04 * P.CollisionRadius, 1.0, 2.0);
    scale = FClamp(0.28 * (scaledist - distance) / scaledist, 0.1, 0.25);

    if(distance <= class'Freon_Trigger'.default.CollisionRadius)
        C.DrawColor = class'Freon_PRI'.default.FrozenColor;
    else
        C.DrawColor = class'Freon_PRI'.default.FrozenColor * 0.75;
    
    C.Style = ERenderStyle.STY_Normal;
    if(distance < PlayerOwner.TeamBeaconPlayerInfoMaxDist)
    {
        C.Font = C.SmallFont;

		if(class'TAM_ScoreBoard'.default.bEnableColoredNamesOnHUD)
			name = Misc_PRI(P.PlayerReplicationInfo).GetColoredName();
		else
			name = P.PlayerReplicationInfo.PlayerName;
        info = name $ " (" $ P.Health $ "%)";
	    C.TextSize(info, XL, YL);
	    C.SetPos(ScreenLoc.X - 0.125 * FrozenBeacon.USize, ScreenLoc.Y - 0.125 * FrozenBeacon.VSize - YL);
	    C.DrawTextClipped(info, false);

        // thaw bar
        C.SetPos(ScreenLoc.X + 1.25 * FrozenBeacon.USize * scale, ScreenLoc.Y + 0.1 * FrozenBeacon.VSize * scale);
        C.DrawTileStretched(ThawBackMat, ThawBarWidth, FrozenBeacon.VSize * scale * 0.5);

        C.SetPos(ScreenLoc.X + 1.25 * FrozenBeacon.USize * scale, ScreenLoc.Y + 0.1 * FrozenBeacon.VSize * scale);
        C.DrawTileStretched(ThawBarMat, ThawBarWidth * (P.Health / 100.0), FrozenBeacon.VSize * scale * 0.5);
    }

	C.SetPos(ScreenLoc.X - 0.125 * FrozenBeacon.USize * scale, ScreenLoc.Y - 0.125 * FrozenBeacon.VSize * scale);
	C.DrawTile(FrozenBeacon,
		FrozenBeacon.USize * scale,
		FrozenBeacon.VSize * scale,
		0.0,
		0.0,
		FrozenBeacon.USize,
		FrozenBeacon.VSize);
}

simulated function bool ShouldDrawPlayer(Misc_PRI PRI)
{
    if(PRI == None || PRI.Team == None)
        return false;
    if(Freon_PawnReplicationInfo(PRI.PawnReplicationInfo) == None || 
            (PRI.bOutOfLives && !Freon_PawnReplicationInfo(PRI.PawnReplicationInfo).bFrozen) || 
            PRI == PlayerOwner.PlayerReplicationInfo)
        return false;
    return true;
}

simulated function DrawPlayers(Canvas C)
{
    local int i;
    local int Team;
    local float xl;
    local float yl;
    local float MaxNamePos;
    local int posx;
    local int posy;
    local float scale;
    local string name;
    local int listy;
    local int space;
    local int namey;
    local int namex;
    local int height;
    local int width;
    
    local int health;
    local int starthealth;

    local int allies;
    local int enemies;

    local Misc_PRI PRI;

    if(myOwner == None)
        return;

    if(PlayerOwner.PlayerReplicationInfo.Team != None)
        Team = PlayerOwner.GetTeamNum();
    else
    {
        if(Pawn(PlayerOwner.ViewTarget) == None || Pawn(PlayerOwner.ViewTarget).GetTeamNum() == 255)
            return;
        Team = Pawn(PlayerOwner.ViewTarget).GetTeamNum();
    }

    listy = 0.08 * HUDScale * C.ClipY;
    space = 0.005 * HUDScale * C.ClipY;
    scale = FMax(HUDScale, 0.75);
    height = C.ClipY * 0.0255 * Scale;
    width = C.ClipX * 0.13 * Scale;
    namex = C.ClipX * 0.025 * Scale; 
    MaxNamePos = 0.99 * (width - namex);
    C.Font = GetFontSizeIndex(C, -3 + int(Scale * 1.25));
    C.StrLen("Test", xl, yl);
    namey = (height * 0.6) - (yl * 0.5);

    for(i = 0; i < MyOwner.GameReplicationInfo.PRIArray.Length; i++)
    {
        PRI = Misc_PRI(myOwner.GameReplicationInfo.PRIArray[i]);
        if(!ShouldDrawPlayer(PRI))
            continue;

        if(!class'Misc_Player'.default.bShowTeamInfo)
            continue;

        if(PRI.Team.TeamIndex == Team)
        {
            if(allies > 9)
                continue;

            posy = listy + ((height + space) * allies);
            posx = C.ClipX * 0.01;
            
            // draw background
            C.SetPos(posx, posy);

            if(Freon_PawnReplicationInfo(PRI.PawnReplicationInfo) != None && Freon_PawnReplicationInfo(PRI.PawnReplicationInfo).bFrozen)
                C.DrawColor = class'Freon_PRI'.default.FrozenColor * 0.6;
            else
                C.DrawColor = default.BlackColor;
            C.DrawColor.A = 100;
            C.DrawTile(TeamTex, width, height, 168, 211, 166, 44);

            // draw disc
            C.SetPos(posx, posy);
            C.DrawColor = default.WhiteColor;
            C.DrawTile(TeamTex, C.ClipX * 0.0195 * Scale, C.ClipY * 0.026 * Scale, 119, 258, 54, 55);

            // draw name
			if(class'TAM_ScoreBoard'.default.bEnableColoredNamesOnHUD)
				name = PRI.GetColoredName();
			else
				name = PRI.PlayerName;
            C.DrawColor = NameColor;
            C.SetPos(posx + namex, posy + namey); 
			class'Misc_Util'.static.DrawTextClipped(C, name, MaxNamePos);

            // draw health dot
            if(Freon_PawnReplicationInfo(PRI.PawnReplicationInfo)!= None && Freon_PawnReplicationInfo(PRI.PawnReplicationInfo).bFrozen)
            {
                health = PRI.PawnReplicationInfo.Health;
                C.DrawColor = class'Freon_PRI'.default.FrozenColor * (0.5 + (health * 0.005));
            }
            else
            {
                health = PRI.PawnReplicationInfo.Health + PRI.PawnReplicationInfo.Shield;
                if(TAM_TeamInfo(PRI.Team) != None)
                    starthealth = TAM_TeamInfo(PRI.Team).StartingHealth;
                else if(TAM_TeamInfoRed(PRI.Team) != None)
                    starthealth = TAM_TeamInfoRed(PRI.Team).StartingHealth;
                else if(TAM_TeamInfoBlue(PRI.Team) != None)
                    starthealth = TAM_TeamInfoBlue(PRI.Team).StartingHealth;
                else
                    starthealth = 200;

                if(health < starthealth)
                {
                    C.DrawColor.B = 0;
                    C.DrawColor.R = Min(255, (511 * (float(StartHealth - Health) / float(StartHealth))));

                    if(C.DrawColor.R == 255)
				        C.DrawColor.G = Min(255, (511 * (float(Health) / float(StartHealth))));
                    else
                        C.DrawColor.G = 255;
                }
                else
                    C.DrawColor = FullHealthColor;
            }

            C.SetPos(posx + (0.0022 * Scale * C.ClipX), posy + (0.0035 * Scale * C.ClipY));
            C.DrawTile(TeamTex, C.ClipX * 0.0165 * Scale, C.ClipY * 0.0185 * Scale, 340, 432, 78, 78);

            // draw location dot
            C.DrawColor = WhiteColor;
            Draw2DLocationDot(C, PRI.PawnReplicationInfo.Position, (posx / C.ClipX) + (0.006 * Scale), (posy / C.ClipY) + (0.008 * Scale), 0.008 * Scale, 0.01 * Scale);

            // friends shown
            allies++;
        }
        else
        {
            if(enemies > 9)
                continue;

            posy = listy + ((height + space) * enemies);
            posx = C.ClipX * 0.99;

            // draw background
            C.SetPos(posx - width, posy);
            if(Freon_PawnReplicationInfo(PRI.PawnReplicationInfo) != None && Freon_PawnReplicationInfo(PRI.PawnReplicationInfo).bFrozen)
                C.DrawColor = class'Freon_PRI'.default.FrozenColor * 0.6;
            else
                C.DrawColor = default.BlackColor;
            C.DrawColor.A = 100;
            C.DrawTile(TeamTex, width, height, 168, 211, 166, 44);

            // draw disc
            C.SetPos(posx - (C.ClipX * 0.0195 * Scale), posy);
            C.DrawColor = default.WhiteColor;
            C.DrawTile(TeamTex, C.ClipX * 0.0195 * Scale, C.ClipY * 0.026 * Scale, 119, 258, 54, 55);

            // draw name
			if(class'TAM_ScoreBoard'.default.bEnableColoredNamesOnHUD)
				name = PRI.GetColoredName();
			else
				name = PRI.PlayerName;
            C.TextSize(name, xl, yl);
			xl = Min(xl, MaxNamePos);
            C.DrawColor = NameColor;
            C.SetPos(posx - xl - namex, posy + namey); 
			class'Misc_Util'.static.DrawTextClipped(C, name, MaxNamePos);

            // draw health dot
            if(Freon_PawnReplicationInfo(PRI.PawnReplicationInfo)!= None && Freon_PawnReplicationInfo(PRI.PawnReplicationInfo).bFrozen)
                C.DrawColor = class'Freon_PRI'.default.FrozenColor;
            else
                C.DrawColor = HudColorTeam[PRI.Team.TeamIndex];
            C.SetPos(posx - (0.0165 * Scale * C.ClipX), posy + (0.0035 * Scale * C.ClipY));
            C.DrawTile(TeamTex, C.ClipX * 0.0165 * Scale, C.ClipY * 0.0185 * Scale, 340, 432, 78, 78);

            // enemies shown
            enemies++;
        }
    }
}

simulated function DrawPlayersExtended(Canvas C)
{
    local int i;
    local int Team;
    local float xl;
    local float yl;
    local float MaxNamePos;
    local int posx;
    local int posy;
    local float scale;
    local string name;
    local int listy;
    local int space;
    local int namey;
    local int namex;
    local int height;
    local int width;
    local Misc_PRI pri;
    local int health;
    local int starthealth;

    local int allies;
    local int enemies;

    if(myOwner == None)
        return;

    if(PlayerOwner.PlayerReplicationInfo.Team != None)
        Team = PlayerOwner.GetTeamNum();
    else
    {
        if(Pawn(PlayerOwner.ViewTarget) == None || Pawn(PlayerOwner.ViewTarget).GetTeamNum() == 255)
            return;
        Team = Pawn(PlayerOwner.ViewTarget).GetTeamNum();
    }

    listy = 0.08 * HUDScale * C.ClipY;
    scale = 0.75;
    height = C.ClipY * 0.02;
    space = height + (0.0075 * C.ClipY);
    namex = C.ClipX * 0.02; 
    
    C.Font = GetFontSizeIndex(C, -3);
    C.StrLen("Test", xl, yl);
    namey = (height * 0.6) - (yl * 0.5);

    for(i = 0; i < MyOwner.GameReplicationInfo.PRIArray.Length; i++)
    {
        PRI = Misc_PRI(myOwner.GameReplicationInfo.PRIArray[i]);
        if(!ShouldDrawPlayer(PRI))
            continue;

        if(!class'Misc_Player'.default.bShowTeamInfo)
            continue;

        if(PRI.Team.TeamIndex == Team)
        {
            if(allies > 9)
                continue;

            space = height + (0.0075 * C.ClipY);
            width = C.ClipX * 0.14;
            MaxNamePos = 0.78 * (width - namex);

            posy = listy + ((height + space) * allies);
            posx = C.ClipX * 0.01;
            
            // draw backgrounds
            C.SetPos(posx, posy);
            if(Freon_PawnReplicationInfo(PRI.PawnReplicationInfo) != None && Freon_PawnReplicationInfo(PRI.PawnReplicationInfo).bFrozen)
                C.DrawColor = class'Freon_PRI'.default.FrozenColor * 0.6;
            else
                C.DrawColor = default.BlackColor;
            C.DrawColor.A = 100;
            C.DrawTile(TeamTex, width + posx, height, 168, 211, 166, 44);
            C.SetPos(posx * 2, posy + height * 1.1);
            C.DrawTile(TeamTex, width, height, 168, 211, 166, 44);

            // draw disc
            C.SetPos(posx, posy);
            C.DrawColor = default.WhiteColor;
            C.DrawTile(TeamTex, C.ClipX * 0.0195 * Scale, C.ClipY * 0.026 * Scale, 119, 258, 54, 55);

            // draw name
			if(class'TAM_ScoreBoard'.default.bEnableColoredNamesOnHUD)
				name = PRI.GetColoredName();
			else
				name = PRI.PlayerName;
            C.DrawColor = NameColor;
            C.SetPos(posx + namex, posy + namey); 
			class'Misc_Util'.static.DrawTextClipped(C, name, MaxNamePos);

            // draw location
            MaxNamePos = 0.80 * (width - namex);
            name = PRI.GetLocationName();
            C.StrLen(name, xl, yl);
            if(xl > MaxNamePos)
                name = left(name, MaxNamePos / xl * len(name));
            C.SetPos(posx + namex, posy + (height * 1.1) + namey);

            if(Freon_PawnReplicationInfo(PRI.PawnReplicationInfo)!= None && Freon_PawnReplicationInfo(PRI.PawnReplicationInfo).bFrozen)
                C.DrawColor = class'Freon_PRI'.default.FrozenColor;
            else
                C.DrawColor = LocationColor;
            C.DrawText(name);

            // draw health dot
            if(Freon_PawnReplicationInfo(PRI.PawnReplicationInfo) != None && Freon_PawnReplicationInfo(PRI.PawnReplicationInfo).bFrozen)
            {
                health = PRI.PawnReplicationInfo.Health;
                C.DrawColor = class'Freon_PRI'.default.FrozenColor * (0.5 + (health * 0.005));
            }
            else
            {
                health = PRI.PawnReplicationInfo.Health + PRI.PawnReplicationInfo.Shield;
                if(TAM_TeamInfo(PRI.Team) != None)
                    starthealth = TAM_TeamInfo(PRI.Team).StartingHealth;
                else if(TAM_TeamInfoRed(PRI.Team) != None)
                    starthealth = TAM_TeamInfoRed(PRI.Team).StartingHealth;
                else if(TAM_TeamInfoBlue(PRI.Team) != None)
                    starthealth = TAM_TeamInfoBlue(PRI.Team).StartingHealth;
                else
                    starthealth = 200;

                if(health < starthealth)
                {
                    C.DrawColor.B = 0;
                    C.DrawColor.R = Min(200, (400 * (float(StartHealth - Health) / float(StartHealth))));

                    if(C.DrawColor.R == 200)
				        C.DrawColor.G = Min(200, (400 * (float(Health) / float(StartHealth))));
                    else
                        C.DrawColor.G = 200;
                }
                else
                    C.DrawColor = FullHealthColor;
            }

            C.SetPos(posx + (0.0022 * Scale * C.ClipX), posy + (0.0035 * Scale * C.ClipY));
            C.DrawTile(TeamTex, C.ClipX * 0.0165 * Scale, C.ClipY * 0.0185 * Scale, 340, 432, 78, 78);

            // draw health
            name = string(health);
            C.StrLen(name, xl, yl);
            C.SetPos(posx * 1.5 + width - xl, posy + namey);
            C.DrawText(name);

            // draw adrenaline
            name = string(PRI.PawnReplicationInfo.Adrenaline);
            C.StrLen(name, xl, yl);
            C.SetPos(posx * 1.5 + width - xl, posy + (height * 1.1) + namey);
            if(PRI.PawnReplicationInfo.Adrenaline<100)
                C.DrawColor = LowYellowColor;
            else
                C.DrawColor = HighYellowColor;
            C.DrawText(name);

            // draw location dot
            C.DrawColor = WhiteColor;
            Draw2DLocationDot(C, PRI.PawnReplicationInfo.Position, (posx / C.ClipX) + (0.006 * Scale), (posy / C.ClipY) + (0.008 * Scale), 0.008 * Scale, 0.01 * Scale);

            // friends shown
            allies++;
        }
        else
        {
            if(enemies > 9)
                continue;

            space = (0.005 * C.ClipY);
            width = C.ClipX * 0.11;
            MaxNamePos = 0.99 * (width - namex);

            posy = listy + ((height + space) * enemies);
            posx = C.ClipX * 0.99;

            // draw background
            C.SetPos(posx - width, posy);
            if(Freon_PawnReplicationInfo(PRI.PawnReplicationInfo) != None && Freon_PawnReplicationInfo(PRI.PawnReplicationInfo).bFrozen)
                C.DrawColor = class'Freon_PRI'.default.FrozenColor * 0.6;
            else
                C.DrawColor = default.BlackColor;
            C.DrawColor.A = 100;
            C.DrawTile(TeamTex, width, height, 168, 211, 166, 44);

            // draw disc
            C.SetPos(posx - (C.ClipX * 0.0195 * Scale), posy);
            C.DrawColor = default.WhiteColor;
            C.DrawTile(TeamTex, C.ClipX * 0.0195 * Scale, C.ClipY * 0.026 * Scale, 119, 258, 54, 55);

            // draw name
			if(class'TAM_ScoreBoard'.default.bEnableColoredNamesOnHUD)
				name = PRI.GetColoredName();
			else
				name = PRI.PlayerName;
            C.TextSize(name, xl, yl);
			xl = Min(xl, MaxNamePos);
            C.DrawColor = NameColor;
            C.SetPos(posx - xl - namex, posy + namey); 
			class'Misc_Util'.static.DrawTextClipped(C, name, MaxNamePos);

            // draw health dot
            if(Freon_PawnReplicationInfo(PRI.PawnReplicationInfo)!= None && Freon_PawnReplicationInfo(PRI.PawnReplicationInfo).bFrozen)
                C.DrawColor = class'Freon_PRI'.default.FrozenColor;
            else
                C.DrawColor = HudColorTeam[PRI.Team.TeamIndex];
            C.SetPos(posx - (0.016 * Scale * C.ClipX), posy + (0.0035 * Scale * C.ClipY));
            C.DrawTile(TeamTex, C.ClipX * 0.0165 * Scale, C.ClipY * 0.0185 * Scale, 340, 432, 78, 78);

            // enemies shown
            enemies++;
        }
    }
}

defaultproperties
{
     FrozenBeacon=Texture'3SPNv3210CW.textures.Flake'
     ThawBarWidth=50.000000
     ThawBarHeight=10.000000
     ThawBackMat=Texture'InterfaceContent.Menu.BorderBoxD'
     ThawBarMat=Texture'ONSInterface-TX.HealthBar'
}
