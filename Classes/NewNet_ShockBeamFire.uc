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
class NewNet_ShockBeamFire extends WeaponFire_Shock;

var bool bUseReplicatedInfo;
var rotator savedRot;
var vector savedVec;

var float PingDT;
var bool bSkipNextEffect;
var bool bUseEnhancedNetCode;

function PlayFiring()
{
   super.PlayFiring();

   if(Level.NetMode != NM_Client || !class'Misc_Player'.static.UseNewNet())
       return;
   if(!bSkipNextEffect)
       CheckFireEffect();
   else
   {
      bSkipNextEffect=false;
      Weapon.ClientStopFire(0);
   }
}

function CheckFireEffect()
{
   if(Level.NetMode == NM_Client && Instigator.IsLocallyControlled())
   {
       DoFireEffect();
   }
}

function DoTrace(Vector Start, Rotator Dir)
{
    local Vector X, End, HitLocation, HitNormal, RefNormal;
    local Actor Other;
    local int Damage;
    local bool bDoReflect;
    local int ReflectNum;
    local vector PawnHitLocation;

    if(!bUseEnhancedNetCode)
    {
        super.DoTrace(Start,Dir);
        return;
    }

	MaxRange();

    ReflectNum = 0;

    while (true)
    {
        TimeTravel(pingDT);
        bDoReflect = false;
        X = Vector(Dir);
        End = Start + TraceRange * X;

        if(PingDT <=0.0)
            Other = Weapon.Trace(HitLocation,HitNormal,End,Start,true);
        else
            Other = DoTimeTravelTrace(HitLocation, HitNormal, End, Start);

        if(Other!=None && Other.IsA('NewNet_PawnCollisionCopy'))
        {
             PawnHitLocation = HitLocation + NewNet_PawnCollisionCopy(Other).CopiedPawn.Location - Other.Location;
             Other=NewNet_PawnCollisionCopy(Other).CopiedPawn;
        }
        else
        {
            PawnHitLocation = HitLocation;
        }
        UnTimeTravel();

        if ( Other != None && (Other != Instigator || ReflectNum > 0) )
        {
            if (bReflective && Other.IsA('xPawn') && xPawn(Other).CheckReflect(PawnHitLocation, RefNormal, DamageMin*0.25))
            {
                bDoReflect = true;
                HitNormal = Vect(0,0,0);
            }
            else if ( !Other.bWorldGeometry )
            {
				Damage = DamageMin;
				if ( (DamageMin != DamageMax) && (FRand() > 0.5) )
					Damage += Rand(1 + DamageMax - DamageMin);
                Damage = Damage * DamageAtten;

				// Update hit effect except for pawns (blood) other than vehicles.
               	if ( Other.IsA('Vehicle') || (!Other.IsA('Pawn') && !Other.IsA('HitScanBlockingVolume')) )
					WeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other, PawnHitLocation, HitNormal);

               	Other.TakeDamage(Damage, Instigator, PawnHitLocation, Momentum*X, DamageType);
                HitNormal = Vect(0,0,0);
            }
            else if ( WeaponAttachment(Weapon.ThirdPersonActor) != None )
				WeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other,PawnHitLocation,HitNormal);
        }
        else
        {
            HitLocation = End;
            HitNormal = Vect(0,0,0);
			WeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other,PawnHitLocation,HitNormal);
        }

        SpawnBeamEffect(Start, Dir, HitLocation, HitNormal, ReflectNum);

        if (bDoReflect && ++ReflectNum < 4)
        {
            //Log("reflecting off"@Other@Start@HitLocation);
            Start = HitLocation;
            Dir = Rotator(RefNormal); //Rotator( X - 2.0*RefNormal*(X dot RefNormal) );
        }
        else
        {
            break;
        }
    }

}

function DoInstantFireEffect()
{
   if(Level.NetMode == NM_Client && Instigator.IsLocallyControlled())
   {
       DoFireEffect();
       bSkipNextEffect=true;
   }
}

function DoFireEffect()
{
    local Vector StartTrace;
    local Rotator R, Aim;

    if(!bUseEnhancedNetCode && Level.NetMode != NM_Client)
    {
        super.DoFireEffect();
        return;
    }

    Instigator.MakeNoise(1.0);

    if(bUseReplicatedInfo)
    {
        StartTrace=savedVec;
        R=SavedRot;
        bUseReplicatedInfo=false;
	}
    else
    {
        // the to-hit trace always starts right in front of the eye
        StartTrace = Instigator.Location + Instigator.EyePosition();
        Aim = AdjustAim(StartTrace, AimError);
	    R = rotator(vector(Aim) + VRand()*FRand()*Spread);
    }
    if(Level.NetMode == NM_Client)
        DoClientTrace(StartTrace, R);
    else
        DoTrace(StartTrace, R);
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

    if(NewNet_ShockRifle(Weapon).M == none)
        foreach Weapon.DynamicActors(class'TAM_Mutator',NewNet_ShockRifle(Weapon).M)
            break;

    for(PCC = NewNet_ShockRifle(Weapon).M.PCC; PCC!=None; PCC=PCC.Next)
        PCC.TimeTravelPawn(Delta);
}

function UnTimeTravel()
{
    local NewNet_PawnCollisionCopy PCC;
    //Now, lets turn off the old hits
    for(PCC = NewNet_ShockRifle(Weapon).M.PCC; PCC!=None; PCC=PCC.Next)
        PCC.TurnOffCollision();
}



simulated function DoClientTrace(Vector Start, Rotator Dir)
{
    local Vector X, End, HitLocation, HitNormal, RefNormal;
    local Actor Other;
    local bool bDoReflect;
    local int ReflectNum;

	MaxRange();

    ReflectNum = 0;
    while (true)
    {
        bDoReflect = false;
        X = Vector(Dir);
        End = Start + TraceRange * X;

        Other = Weapon.Trace(HitLocation, HitNormal, End, Start, true);

        if ( Other != None && (Other != Instigator || ReflectNum > 0) )
        {
            if (bReflective && Other.IsA('xPawn') && xPawn(Other).CheckReflect(HitLocation, RefNormal, DamageMin*0.25))
            {
                bDoReflect = true;
                HitNormal = Vect(0,0,0);
            }
            else if ( !Other.bWorldGeometry )
            {
				// Update hit effect except for pawns (blood) other than vehicles.
               	if ( Other.IsA('Vehicle') || (!Other.IsA('Pawn') && !Other.IsA('HitScanBlockingVolume')) )
					WeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other, HitLocation, HitNormal);

                HitNormal = Vect(0,0,0);
            }
            else if ( WeaponAttachment(Weapon.ThirdPersonActor) != None )
				WeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other,HitLocation,HitNormal);
        }
        else
        {
            HitLocation = End;
            HitNormal = Vect(0,0,0);
			WeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other,HitLocation,HitNormal);
        }

        SpawnClientBeamEffect(Start, Dir, HitLocation, HitNormal, ReflectNum);

        if (bDoReflect && ++ReflectNum < 4)
        {
            //Log("reflecting off"@Other@Start@HitLocation);
            Start = HitLocation;
            Dir = Rotator(RefNormal); //Rotator( X - 2.0*RefNormal*(X dot RefNormal) );
        }
        else
        {
            break;
        }
    }
}

simulated function SpawnClientBeamEffect(Vector Start, Rotator Dir, Vector HitLocation, Vector HitNormal, int ReflectNum)
{
    NewNet_ShockRifle(Weapon).SpawnBeamEffect(Hitlocation, hitnormal, start, dir, reflectnum);
}

function SpawnBeamEffect(Vector Start, Rotator Dir, Vector HitLocation, Vector HitNormal, int ReflectNum)
{
    local ShockBeamEffect Beam;
    if(!bUseEnhancedNetCode)
    {
        if (Weapon != None)
        {
            Beam = Weapon.Spawn(Class'XWeapons.ShockBeamEffect',,, Start, Dir);
            if (ReflectNum != 0) Beam.Instigator = None; // prevents client side repositioning of beam start
                Beam.AimAt(HitLocation, HitNormal);
        }
        return;
    }

    if (Weapon != None)
    {
        Beam = Weapon.Spawn(BeamEffectClass,Weapon.Owner,, Start, Dir);
        if (ReflectNum != 0) Beam.Instigator = None; // prevents client side repositioning of beam start
            Beam.AimAt(HitLocation, HitNormal);
    }
}


defaultproperties
{
    BeamEffectClass=Class'NewNet_ShockBeamEffect'
}
