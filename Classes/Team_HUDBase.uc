class Team_HUDBase extends HudCTeamDeathmatch
    abstract;

#exec TEXTURE IMPORT NAME=CHair FILE=Textures\CHair.tga     GROUP=Textures MIPS=On ALPHA=1 DXT=5

var Texture TeamTex;
var Material TrackedPlayer;
var int OldRoundTime;
var Misc_Player myOwner;

var Color FullHealthColor;
var Color NameColor;
var Color LocationColor;
var Color LowYellowColor;
var Color HighYellowColor;

struct StatsListStruct
{
	var string ListName;
	var array<string> RowNames;
	var array<string> RowValues;
};
var StatsListStruct StatsLists[2];
var int CurrentStatsList;

var array<vector> TargetingLines;
var Actor TargetingActor;

exec function ShowStats()
{
	bShowLocalStats = !bShowLocalStats;
    Misc_Player(PlayerOwner).bFirstOpen = bShowLocalStats;
}

function Draw2DLocationDot(Canvas C, vector Loc, float OffsetX, float OffsetY, float ScaleX, float ScaleY)
{
	local rotator Dir;
	local float Angle, Scaling;
	local Actor Start;

	if(PlayerOwner.Pawn == None)
    {
        if(PlayerOwner.ViewTarget != None)
            Start = PlayerOwner.ViewTarget;
        else
		    Start = PlayerOwner;
    }
	else
		Start = PlayerOwner.Pawn;

	Dir = rotator(Loc - Start.Location);
	Angle = ((Dir.Yaw - PlayerOwner.Rotation.Yaw) & 65535) * 6.2832 / 65536;
	C.Style = ERenderStyle.STY_Alpha;
	C.SetPos(OffsetX * C.ClipX + ScaleX * C.ClipX * sin(Angle),
			OffsetY * C.ClipY - ScaleY * C.ClipY * cos(Angle));

	Scaling = 24 * C.ClipX * (0.45 * HUDScale) / 1600;

	C.DrawTile(LocationDot, Scaling, Scaling, 340, 432, 78, 78);
}

simulated function bool ShouldDrawPlayer(Misc_PRI PRI)
{
    if(PRI == None || PRI.PawnReplicationInfo == None || PRI.bOutOfLives || PRI.Team == None || PRI == PlayerOwner.PlayerReplicationInfo)
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
            C.DrawColor = LocationColor;
            C.DrawText(name);

            // draw health dot
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
            C.DrawColor = HudColorTeam[PRI.Team.TeamIndex];
            C.SetPos(posx - (0.016 * Scale * C.ClipX), posy + (0.0035 * Scale * C.ClipY));
            C.DrawTile(TeamTex, C.ClipX * 0.0165 * Scale, C.ClipY * 0.0185 * Scale, 340, 432, 78, 78);

            // enemies shown
            enemies++;
        }
    }
}

simulated function DrawSpectatingHud(Canvas C)
{
  Super.DrawSpectatingHud(C);
  
  if(PlayerOwner.PlayerReplicationInfo!=None && PlayerOwner.PlayerReplicationInfo.bOnlySpectator) {
    if(class'Misc_Player'.default.bAdminVisionInSpec)
      DrawAdminVision(C);
    if(class'Misc_Player'.default.bDrawTargetingLineInSpec)
      DrawTargetingLine(C);
  }
}

simulated function DrawHudPassC(Canvas C)
{
  Super.DrawHudPassC(C);

  if(PlayerOwner.PlayerReplicationInfo!=None && PlayerOwner.PlayerReplicationInfo.bOnlySpectator) {
    if(class'Misc_Player'.default.bAdminVisionInSpec)
      DrawAdminVision(C);
    if(class'Misc_Player'.default.bDrawTargetingLineInSpec)
      DrawTargetingLine(C);
  }
}

simulated function UpdateRankAndSpread(Canvas C)
{
    if(MyOwner == None)
        return;

    if(!class'Misc_Player'.default.bExtendedInfo)
        DrawPlayers(C);
    else
        DrawPlayersExtended(C);
}

simulated function UpdateHUD()
{
    local Color red;
    local Color blue;
    local int team;

    if(myOwner == None)
    {
        myOwner = Misc_Player(PlayerOwner);

        if(myOwner == None)
        {
            Super.UpdateHUD();
            return;
        }
    }

    if(class'Misc_Player'.default.bMatchHUDToSkins)
	{
        if(MyOwner.PlayerReplicationInfo.bOnlySpectator)
        {
            if(Pawn(MyOwner.ViewTarget) != None && Pawn(MyOwner.ViewTarget).GetTeamNum() != 255)
                team = Pawn(MyOwner.ViewTarget).GetTeamNum();
            else
                return;
        }
        else
            team = MyOwner.GetTeamNum();

        red = class'Misc_Player'.default.RedOrEnemy * 2;
        blue = class'Misc_Player'.default.BlueOrAlly * 2;
        red.A = HudColorRed.A;
        blue.A = HudColorBlue.A;

		if(!class'Misc_Player'.default.bUseTeamColors)
		{
			if(team == 0)
			{
				HudColorRed = blue;
				HudColorBlue = red;
                HudColorTeam[0] = blue;
                HudColorTeam[1] = red;

				TeamSymbols[0].Tints[0] = blue;
				TeamSymbols[0].Tints[1] = blue;
				TeamSymbols[1].Tints[0] = red;
				TeamSymbols[1].Tints[1] = red;
			}
			else
			{
				HudColorBlue = blue;
				HudColorRed = red;
                HudColorTeam[1] = blue;
                HudColorTeam[0] = red;

				TeamSymbols[0].Tints[0] = red;
				TeamSymbols[0].Tints[1] = red;
				TeamSymbols[1].Tints[0] = blue;
				TeamSymbols[1].Tints[1] = blue;
			}
		}
		else
		{
			HudColorRed = red;
			HudColorBlue = blue;
		}
	}
	else
	{
		HudColorRed = default.HudColorRed;
		HudColorBlue = default.HudColorBlue;
        HudColorTeam[0] = default.HudColorTeam[0];
        HudColorTeam[1] = default.HudColorTeam[1];

		TeamSymbols[0].Tints[0] = default.HudColorTeam[0];
		TeamSymbols[0].Tints[1] = default.HudColorTeam[0];
		TeamSymbols[1].Tints[0] = default.HudColorTeam[1];
		TeamSymbols[1].Tints[1] = default.HudColorTeam[1];
	}
  
    Super.UpdateHUD();
}

simulated function DrawAdminVision(Canvas C)
{
    local Pawn Pawn;
    foreach AllActors(class'Pawn', Pawn)
    {
      if(PawnOwner == Pawn)
        continue;
      C.DrawActor(Pawn, false, true);
    }
}

simulated function DrawTargetingLine(Canvas C)
{
  local vector TargetPoint1, TargetPoint2, Loc,Dir;
  local int i;
  local Actor ViewActor;
  local rotator Rot;

  if(PlayerOwner==None)
    return;
    
  PlayerOwner.PlayerCalcView(ViewActor, Loc, Rot);
  Dir = Vector(Rot);
  
  if(TargetingActor!=ViewActor) {
    TargetingLines.Length = 0;
    TargetingActor = ViewActor;
  }
  
  if(ViewActor==None)
    return;
  
  i = TargetingLines.Length;
  if(i==0 || Dir!=TargetingLines[i-1]) {
    if(i>100) {
      TargetingLines.Remove(0,i-100);
      i = TargetingLines.Length;
    }
    TargetingLines.Length = i+1;
    TargetingLines[i] = Dir;
  }
  
  for(i=0; i<TargetingLines.Length-1; ++i) {
    if(TargetingLines[i] Dot Dir <= 0)
      continue;
    if(TargetingLines[i+1] Dot Dir <= 0)
      continue;
  
    TargetPoint1 = C.WorldToScreen(Loc + TargetingLines[i] * 2);
    TargetPoint2 = C.WorldToScreen(Loc + TargetingLines[i+1] * 2);
    DrawCanvasLine(TargetPoint1.X, TargetPoint1.Y, TargetPoint2.X, TargetPoint2.Y, RedColor);
  }
}

/*simulated function DrawTrackedPlayer(Canvas C, Misc_PawnReplicationInfo P, Misc_PRI PRI)
{
    local float	SizeScale, SizeX, SizeY;
    local vector ScreenPos;

    if(DrawPlayerTracking(C, P, false, ScreenPos) && (!p.bInvis || MyOwner.bEnhancedRadar) && PRI != PawnOwner.PlayerReplicationInfo)
    {
        if(MyOwner.bEnhancedRadar)
            C.DrawColor = HudColorTeam[pri.Team.TeamIndex];
        else
            C.DrawColor = WhiteColor * 0.8;
        C.DrawColor.A = 175;
        C.Style = ERenderStyle.STY_Alpha;

	    SizeScale	= 0.2;
	    SizeX		= 32 * SizeScale * ResScaleX;
	    SizeY		= 32 * SizeScale * ResScaleY;

	    C.SetPos(ScreenPos.X - SizeX * 0.5, ScreenPos.Y - SizeY * 0.5);
	    C.DrawTile(TrackedPlayer, SizeX, SizeY, 0, 0, 64, 64);
    }
}

simulated function bool DrawPlayerTracking( Canvas C, Actor P, bool bOptionalIndicator, out vector ScreenPos )
{
	local Vector	CamLoc;
	local Rotator	CamRot;

	C.GetCameraLocation(CamLoc, CamRot);

	if(IsTargetInFrontOfPlayer(C, P, ScreenPos, CamLoc, CamRot) && !FastTrace(Misc_PawnReplicationInfo(P).Position, CamLoc))
		return true;

	return false;
}

static function bool IsTargetInFrontOfPlayer( Canvas C, Actor Target, out Vector ScreenPos,
											 Vector CamLoc, Rotator CamRot )
{
	// Is Target located behind camera ?
	if((Misc_PawnReplicationInfo(Target).Position - CamLoc) Dot vector(CamRot) < 0)
		return false;

	// Is Target on visible canvas area ?
	ScreenPos = C.WorldToScreen(Misc_PawnReplicationInfo(Target).Position);
	if(ScreenPos.X <= 0 || ScreenPos.X >= C.ClipX)
        return false;
	if(ScreenPos.Y <= 0 || ScreenPos.Y >= C.ClipY)
        return false;

	return true;
}*/

function CheckCountdown(GameReplicationInfo GRI)
{
    local Misc_BaseGRI G;

    G = Misc_BaseGRI(GRI);
    if(G == None || G.MinsPerRound == 0 || G.RoundTime == 0 || G.RoundTime == OldRoundTime || GRI.Winner != None)
    {
        Super.CheckCountdown(GRI);
        return;
    }

    OldRoundTime = G.RoundTime;

    if(OldRoundTime > 30 && G.MinsPerRound < 2)
        return;

    if(OldRoundTime == 60)
        PlayerOwner.PlayStatusAnnouncement(LongCountName[3], 1, true);
    else if(OldRoundTime == 30)
        PlayerOwner.PlayStatusAnnouncement(LongCountName[4], 1, true);
    else if(OldRoundTime == 20)
        PlayerOwner.PlayStatusAnnouncement(LongCountName[5], 1, true);
    else if(OldRoundTime <= 5 && OldRoundTime > 0)
        PlayerOwner.PlayStatusAnnouncement(CountDownName[OldRoundTime - 1], 1, true);
}

simulated function DrawTimer(Canvas C)
{
	local Misc_BaseGRI GRI;
	local int Minutes, Hours, Seconds;

	GRI = Misc_BaseGRI(PlayerOwner.GameReplicationInfo);

    if(GRI == None)
        return;

	if(GRI.MinsPerRound > 0)
    {
        Seconds = GRI.RoundTime;
        if(GRI.TimeLimit > 0 && GRI.RoundTime > GRI.RemainingTime)
            Seconds = GRI.RemainingTime;
    }
    else if(GRI.TimeLimit > 0)
        Seconds = GRI.RemainingTime;
	else
		Seconds = GRI.ElapsedTime;

	TimerBackground.Tints[TeamIndex] = HudColorBlack;
    TimerBackground.Tints[TeamIndex].A = 150;

	DrawSpriteWidget(C, TimerBackground);
	DrawSpriteWidget(C, TimerBackgroundDisc);
	DrawSpriteWidget(C, TimerIcon);

	TimerMinutes.OffsetX = default.TimerMinutes.OffsetX - 80;
	TimerSeconds.OffsetX = default.TimerSeconds.OffsetX - 80;
	TimerDigitSpacer[0].OffsetX = Default.TimerDigitSpacer[0].OffsetX;
	TimerDigitSpacer[1].OffsetX = Default.TimerDigitSpacer[1].OffsetX;

	if( Seconds > 3600 )
    {
        Hours = Seconds / 3600;
        Seconds -= Hours * 3600;

		DrawNumericWidget( C, TimerHours, DigitsBig);
        TimerHours.Value = Hours;

		if(Hours>9)
		{
			TimerMinutes.OffsetX = default.TimerMinutes.OffsetX;
			TimerSeconds.OffsetX = default.TimerSeconds.OffsetX;
		}
		else
		{
			TimerMinutes.OffsetX = default.TimerMinutes.OffsetX -40;
			TimerSeconds.OffsetX = default.TimerSeconds.OffsetX -40;
			TimerDigitSpacer[0].OffsetX = Default.TimerDigitSpacer[0].OffsetX - 32;
			TimerDigitSpacer[1].OffsetX = Default.TimerDigitSpacer[1].OffsetX - 32;
		}
		DrawSpriteWidget( C, TimerDigitSpacer[0]);
	}
	DrawSpriteWidget( C, TimerDigitSpacer[1]);

	Minutes = Seconds / 60;
    Seconds -= Minutes * 60;

    TimerMinutes.Value = Min(Minutes, 60);
	TimerSeconds.Value = Min(Seconds, 60);

	DrawNumericWidget( C, TimerMinutes, DigitsBig);
	DrawNumericWidget( C, TimerSeconds, DigitsBig);
}

/* colored names */

function DisplayEnemyName(Canvas C, PlayerReplicationInfo PRI)
{
	PlayerOwner.ReceiveLocalizedMessage(class'Message_PlayerName',0,PRI);
}

/* colored names */

simulated function DisplayLocalMessages( Canvas C )
{
	Super.DisplayLocalMessages(C);
	
	DrawStatsList(C,0,0.20);
	DrawStatsList(C,1,0.80);
}

function DrawStatsList(Canvas C, int Index, float xPos)
{
	local float y, xl, yl;
	local int i;
	
	if(Len(StatsLists[Index].ListName)==0)
		return;

	y = 0.35;
	C.Font = PlayerController(Owner).MyHUD.GetFontSizeIndex(C, -3);
	C.DrawColor = default.WhiteColor;
	C.DrawScreenText(StatsLists[Index].ListName, xPos, y, DP_LowerMiddle);	
    C.StrLen(StatsLists[Index].ListName, xl, yl);
	y += yl*2 / C.ClipY;
	
	C.DrawColor = default.WhiteColor * 0.7;
	for(i=0; i<StatsLists[Index].RowNames.Length; ++i)
	{
		C.DrawScreenText((i+1)$". "$StatsLists[Index].RowNames[i], xPos-0.1, y, DP_LowerLeft);
		C.DrawScreenText(StatsLists[Index].RowValues[i], xPos+0.1, y, DP_LowerRight);

		C.StrLen(StatsLists[Index].RowNames[i], xl, yl);		
		y += yl / C.ClipY;
	}	
}

defaultproperties
{
     TeamTex=Texture'HUDContent.Generic.HUD'
     TrackedPlayer=Texture'3SPNv3210CW.textures.chair'
     FullHealthColor=(B=200,G=100,A=255)
     NameColor=(B=200,G=200,R=200,A=255)
     LocationColor=(G=130,R=175,A=255)
     LowYellowColor=(R=120,G=120,B=0,A=255)
     HighYellowColor=(R=200,G=200,B=0,A=255)
	 CurrentStatsList=1
}
