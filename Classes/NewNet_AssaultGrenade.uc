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
//-----------------------------------------------------------
//
//-----------------------------------------------------------
class NewNet_AssaultGrenade extends WeaponFire_AssaultAlt;

var float PingDT;
var bool bUseEnhancedNetCode;

const PROJ_TIMESTEP = 0.0201;
const MAX_PROJECTILE_FUDGE = 0.0750;

function projectile SpawnProjectile(Vector Start, Rotator Dir)
{
    local Grenade g;
    local vector X, Y, Z;
    local float pawnSpeed;
    local vector Velocity;
    local float Speed;

    local rotator NewDir;
    local actor Other;
    local vector HitNormal,HitLocation,End;
    local float h,f;

    if(!bUseEnhancedNetCode)
    {
        return super.SpawnProjectile(start,dir);
    }

    Weapon.GetViewAxes(X,Y,Z);
    pawnSpeed = X dot Instigator.Velocity;
    if ( Bot(Instigator.Controller) != None )
		Speed = mHoldSpeedMax;
	else
		Speed = mHoldSpeedMin + HoldTime*mHoldSpeedGainPerSec;
	Speed = FClamp(Speed, mHoldSpeedMin, mHoldSpeedMax);
    Speed = pawnSpeed + Speed;
    Velocity = Speed * Vector(Dir);

    if(PingDT > 0.0 && Weapon.Owner!=None)
    {
            NewDir=Dir;
            for(f=0.00; f<pingDT + PROJ_TIMESTEP; f+=PROJ_TIMESTEP)
            {
                //Make sure the last trace we do is right where we want
                //the proj to spawn if it makes it to the end
                h = Fmin(pingdt, f);
                //Where will it be after deltaF, NewDir byRef for next tick
                End = Start + Extrapolate(NewDir, PROJ_TIMESTEP, Speed);
                //Put pawns there
                TimeTravel(pingdt - h);
                //Trace between the start and extrapolated end
                Other = DoTimeTravelTrace(HitLocation, HitNormal, End, Start);
                if(Other!=None)
                {
                    break;
                }
                //repeat
                Start=End;
           }
           UnTimeTravel();

           if(Other!=None && Other.IsA('NewNet_PawnCollisionCopy'))
           {
                 HitLocation = HitLocation + NewNet_PawnCollisionCopy(Other).CopiedPawn.Location - Other.Location;
                 Other=NewNet_PawnCollisionCopy(Other).CopiedPawn;
           }

           Velocity = Speed * Vector(NewDir);
           if(Other == none)
               g = Weapon.Spawn(class'Grenade',,, End, NewDir);
           else
               g = Weapon.Spawn(class'Grenade',,, HitLocation - Vector(Newdir)*16.0, NewDir);
    }
    else
        g = Weapon.Spawn(class'Grenade', instigator,, Start, Dir);


    if(g==None)
        return none;

    g.Speed = Speed;
    g.Velocity = Velocity;
    g.Damage *= DamageAtten;

    return g;
}

function vector Extrapolate(out rotator Dir, float dF, float Speed)
{
    local rotator OldDir;
    OldDir=Dir;

    Dir = rotator(vector(OldDir)*speed + Weapon.Owner.PhysicsVolume.Gravity*dF);

    return vector(OldDir)*speed*dF + 0.5*Square(dF)*Weapon.Owner.PhysicsVolume.Gravity;
}

// We need to do 2 traces. First, one that ignores the things which have already been copied
// and a second one that looks only for things that are copied
function Actor DoTimeTravelTrace(Out vector Hitlocation, out vector HitNormal, vector End, vector Start)
{
    local Actor Other;
    local bool bFoundPCC;
    local vector NewEnd, WorldHitNormal,WorldHitLocation;
    local vector PCCHitNormal,PCCHitLocation;
    local NewNet_PawnCollisionCopy PCC, returnPCC;

    //First, lets set the extent of our trace.  End once we hit an actor which won't
    //be checked by an unlagged copy.
    foreach Weapon.TraceActors(class'Actor', Other,WorldHitLocation,WorldHitNormal,End,Start)
    {
       if((Other.bBlockActors || Other.bProjTarget || Other.bWorldGeometry) && !class'TAM_Mutator'.static.IsPredicted(Other))
       {
           break;
       }
       Other=None;
    }
    if(Other!=None)
        NewEnd=WorldHitlocation;
    else
        NewEnd=End;

    //Now, lets see if we run into any copies, we stop at the location
    //determined by the previous trace.
    foreach Weapon.TraceActors(Class'NewNet_PawnCollisionCopy', PCC, PCCHitLocation, PCCHitNormal, NewEnd,Start)
    {
        if(PCC!=None && PCC.CopiedPawn!=None && PCC.CopiedPawn!=Instigator)
        {
            bFoundPCC=True;
            returnPCC=PCC;
            break;
        }
    }

    // Give back the corresponding info depending on whether or not
    // we found a copy

    if(bFoundPCC)
    {
        HitLocation = PCCHitLocation;
        HitNormal = PCCHitNormal;
        return returnPCC;
    }
    else
    {
        HitLocation = WorldHitLocation;
        HitNormal = WorldHitNormal;
        return Other;
    }
}

function TimeTravel(float delta)
{
    local NewNet_PawnCollisionCopy PCC;

    if(NewNet_AssaultRifle(Weapon).M == none)
        foreach Weapon.DynamicActors(class'TAM_Mutator',NewNet_AssaultRifle(Weapon).M)
            break;

    for(PCC = NewNet_AssaultRifle(Weapon).M.PCC; PCC!=None; PCC=PCC.Next)
        PCC.TimeTravelPawn(Delta);
}

function UnTimeTravel()
{
    local NewNet_PawnCollisionCopy PCC;
    //Now, lets turn off the old hits
    for(PCC = NewNet_AssaultRifle(Weapon).M.PCC; PCC!=None; PCC=PCC.Next)
        PCC.TurnOffCollision();
}


defaultproperties
{
}
