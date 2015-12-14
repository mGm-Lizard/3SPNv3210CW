/*
UTComp - UT2004 Mutator
Copyright (C) 2004-2005 Aaron Everitt & Jo�l Moffatt

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/
class NewNet_ShockProjectile extends WeaponFire_ShockCombo;

var PlayerController PC;
var vector DesiredDeltaFake;
var float CurrentDeltaFakeTime;
var bool bInterpFake;
var bool bOwned;
var bool bMoved;

var float ping;

var NewNet_FakeProjectileManager FPM;

const INTERP_TIME = 0.70;
const PLACEBO_FIX = 0.025;

replication
{
    unreliable if(bDemoRecording)
       DoMove, DoSetLoc;
}

simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();
    if(Level.NetMode != NM_Client)
        return;
    DoPostNet();
}

simulated function DoPostNet()
{
    PC = Level.GetLocalPlayerController();
    if (CheckOwned())
        if( !CheckForFakeProj())
        {
            bMoved = true;
            DoMove(FMax(0.00, (Class'NewNet_PRI'.default.PredictedPing - 1.50*Class'NewNet_TimeStamp'.default.AverDT))*Velocity);
        }
}

simulated function DoMove(Vector V)
{
    Move(V);
}

simulated function DoSetLoc(Vector V)
{
    SetLocation(V);
}

simulated function bool CheckOwned()
{
	if(class'Misc_Player'.default.bEnableEnhancedNetCode==False)
		return false;
    bOwned = (PC!=None && PC.Pawn!=None && PC.Pawn == Instigator);
    return bOwned;
}

simulated function bool CheckForFakeProj()
{
     local Projectile FP;

     ping = FMax(0.0, Class'NewNet_PRI'.default.PredictedPing - 1.50*Class'NewNet_TimeStamp'.default.AverDT);
	 
    if(FPM==None)
	{
        FindFPM();
		if(FPM==None)
			return false;
	}
		
     FP = FPM.GetFP(Class'NewNet_Fake_ShockProjectile');
     if(FP != none)
     {
         bInterpFake=true;
         if(bMoved)
             DesiredDeltaFake = Location - FP.Location;
         else
             DesiredDeltaFake = (Location+Velocity*ping) - FP.Location;
         DoSetLoc(FP.Location);
         FPM.RemoveProjectile(FP);
         bOwned=False;
         return true;
     }
     return false;
}

simulated function FindFPM()
{
    foreach DynamicActors(Class'NewNet_FakeProjectileManager', FPM)
        break;
}


simulated function Tick(float deltatime)
{
    super.Tick(deltatime);
    if(Level.NetMode != NM_Client)
        return;
    DoTick(deltatime);
}

simulated function DoTick(float deltatime)
{
    if(bInterpFake)
        FakeInterp(deltatime);
    else if(bOwned)
        CheckForFakeProj();
}

simulated function FakeInterp(float dt)
{
    local vector V;
    local float OldDeltaFakeTime;

    V=DesiredDeltaFake*dt/INTERP_TIME;

    OldDeltaFakeTime = CurrentDeltaFakeTime;
    CurrentDeltaFakeTime+=dt;

    if(CurrentDeltaFakeTime < INTERP_TIME)
        Domove(V);
    else // (We overshot)
    {
        DoMove((INTERP_TIME - OldDeltaFakeTime)/dt*V);
        bInterpFake=False;
        //Turn off checking for fakes
    }
}



defaultproperties
{
}
