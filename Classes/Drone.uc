class Drone extends LinkedKActor;

var EngineerGoatComponent myCreator;
var GGPawn goatHolder;

var vector mExpectedLocation;
var rotator mExpectedRotation;

var DroneSphere mySphere;
var array<DroneArm> myArms;

var bool isActive;
var bool mIsOffensive;
var GGPawn target;
var float distToTarget;
var float scanRadius;
var float scanHalfAngle;
var AudioComponent mAc;
var SoundCue activeSound;
var float mSoundVolume;
var bool targetLost;

var float shotInterval;

var float activationRange;

function string GetActorName()
{
	return "Drone";
}

function InitDrone(EngineerGoatComponent creator)
{
	local int i;
	local float dist;
	local vector newLocation, offset, dest;
	local rotator newRotation, rotOffset;

	myCreator=creator;
	mIsOffensive=myCreator.mIsOffensive;
	mExpectedLocation=Location;
	mExpectedRotation=Rotation;

	mySphere=Spawn(class'DroneSphere', self,, Location, Rotation,, true);
	mySphere.InitLinkedKActor(self);
	linkedActors.AddItem(mySphere);

	rotOffset.Yaw = 8192;
	offset.X=30.f;// Offset between the base of the arm and the drone center
	for(i=0 ; i<4 ; i++)
	{
		//Rotate the 4 arms on the 4 angles
		myArms.AddItem(Spawn(class'DroneArm', self,, Location, Rotation,, true));
		newLocation = TransformVectorByRotation(rotOffset, offset) + vect(-20, 0, 0);// Offset between the drone center and the actual center of the disk item
		newRotation = myArms[i].StaticMeshComponent.Rotation;
		newRotation.Roll -= newRotation.Roll * 2.f;
		newRotation = rTurn(rotOffset, newRotation);
		myArms[i].StaticMeshComponent.SetRotation(newRotation);
		myArms[i].mPosOffset = newLocation;
		myArms[i].InitLinkedKActor(self);
		linkedActors.AddItem(myArms[i]);
		//Move the rotors to the right spots
		dist = VSize2D(myArms[i].myRotor.mPosOffset);
    	dest = Normal(vector(rotOffset)) * dist;
    	dest.Z = myArms[i].myRotor.mPosOffset.Z;
		myArms[i].myRotor.mPosOffset = dest;
		// Add 1/4 of turn for next arm
		rotOffset.Yaw += 16384;
	}

}

function rotator rTurn(rotator rHeading,rotator rTurnAngle)
{
    // Generate a turn in object coordinates
    //     this should handle any gymbal lock issues

    local vector vForward,vRight,vUpward;
    local vector vForward2,vRight2,vUpward2;
    local rotator T;
    local vector  V;

    GetAxes(rHeading,vForward,vRight,vUpward);
    //  rotate in plane that contains vForward&vRight
    T.Yaw=rTurnAngle.Yaw; V=vector(T);
    vForward2=V.X*vForward + V.Y*vRight;
    vRight2=V.X*vRight - V.Y*vForward;
    vUpward2=vUpward;

    // rotate in plane that contains vForward&vUpward
    T.Yaw=rTurnAngle.Pitch; V=vector(T);
    vForward=V.X*vForward2 + V.Y*vUpward2;
    vRight=vRight2;
    vUpward=V.X*vUpward2 - V.Y*vForward2;

    // rotate in plane that contains vUpward&vRight
    T.Yaw=rTurnAngle.Roll; V=vector(T);
    vForward2=vForward;
    vRight2=V.X*vRight + V.Y*vUpward;
    vUpward2=V.X*vUpward - V.Y*vRight;

    T=OrthoRotation(vForward2,vRight2,vUpward2);

   return(T);
}

function HoldMe(GGPawn goat)
{
	local vector desiredPos, diagonalOffset;
	local float diagonalLength;
	local Turret t;
	local Drone d;
	local GGPawn basedPawn;

	if(goatHolder != none || goat.mIsRagdoll)
	{
		return;
	}

	foreach AllActors(class'Turret', t)
	{
		if(t.goatHolder == goat)
		{
			return;
		}
	}
	foreach AllActors(class'Drone', d)
	{
		if(d.goatHolder == goat)
		{
			return;
		}
	}

	foreach BasedActors(class'GGPawn', basedPawn)
	{
		if(basedPawn != none)
		{
			return;
		}
	}

	//SetPhysics(PHYS_None);
	goatHolder=goat;

	goatHolder.mesh.GetSocketWorldLocationAndRotation( 'Demonic', desiredPos );
	if(IsZero(desiredPos))
	{
		desiredPos=goatHolder.Location + (Normal(vector(goatHolder.Rotation)) * (goatHolder.GetCollisionRadius() + 30.f));
	}
	diagonalOffset=desiredPos-goatHolder.Location;
	diagonalLength=VSize(diagonalOffset);
	mPosOffset.Z=diagonalLength;
}

function DropMe()
{
	//SetPhysics(PHYS_RigidBody);
	goatHolder=none;
}

event Tick( float deltaTime )
{
	local int i;

	super.Tick( deltaTime );

	if(mAc == none || mAc.IsPendingKill())
	{
		mAc=CreateAudioComponent(activeSound, false);
		mAc.PitchMultiplier = 2.f;

		if(isActive && !mAc.IsPlaying())
		{
			mAc.FadeIn(2.f, mSoundVolume);
		}
	}

	UpdateActivation();

	target=none;
	distToTarget=0;
	if(isActive)
	{
		AquireTarget();
		//WorldInfo.Game.Broadcast(self, "target : " $ target);

		if(target == none)
		{
			if(!targetLost && !IsTimerActive(NameOf( LostTarget )))
			{
				SetTimer(1.f, false, NameOf( LostTarget ));
			}
		}
		else
		{
			targetLost=false;
			if(IsTimerActive(NameOf( LostTarget )))
			{
				ClearTimer(NameOf( LostTarget ));
			}
			if(!IsTimerActive(NameOf( ShootTarget )))
			{
				ShootTarget();
			}
		}
	}
	else
	{
		targetLost=true;
	}

	SetLocationAndRotation( deltaTime );
	mySphere.SetLocationAndRotation( deltaTime );
	mySphere.myGun.SetLocationAndRotation( deltaTime );
	mySphere.myGun.myLaser.SetLocationAndRotation( deltaTime );
	for(i=0 ; i<4 ; i++)
	{
		myArms[i].SetLocationAndRotation( deltaTime );
		myArms[i].myRotor.SetLocationAndRotation( deltaTime );
	}
}

function SetLocationAndRotation( float deltaTime )
{
	if(Physics != PHYS_None)
	{
		SetPhysics(PHYS_None);
	}

	if(goatHolder == none)
	{
		SetLocation(mExpectedLocation);
		SetRotation(mExpectedRotation);
	}
	else
	{
		mExpectedRotation = rot(0, 1, 0) * goatHolder.Rotation.Yaw;
		mExpectedLocation = TransformVectorByRotation(mExpectedRotation, mPosOffset) + goatHolder.Location;

		SetLocation(mExpectedLocation);
		SetRotation(mExpectedRotation);
	}
}

function UpdateActivation()
{
	local GGPlayerControllerGame pc;
	local bool outOfRange;
	local bool wasActive;

	wasActive=isActive;
	// Deactivate turret if no goat near
	outOfRange=true;
	foreach WorldInfo.AllControllers( class'GGPlayerControllerGame', pc )
	{
		if( pc.IsLocalPlayerController() && pc.Pawn != none )
		{
			if(VSize(Location-GetPosition(GGPawn(pc.Pawn))) <= activationRange)
			{
				outOfRange=false;
				break;
			}
		}
	}
	isActive=!outOfRange;

	// Manage sound
	if(isActive && !wasActive && !mAc.IsPlaying())
	{
		mAc.FadeIn(2.f, mSoundVolume);
	}
	if(!isActive && wasActive && mAc.IsPlaying())
	{
		mAc.FadeOut(2.f, 0.f);
	}
}

function AquireTarget()
{
	local float disToCurrTarget;
	local GGPawn currTarget;

	foreach VisibleCollidingActors( class'GGPawn', currTarget, scanRadius, mySphere.Location )
    {
		if(!IsValidTarget(currTarget))
		{
			continue;
		}

		if(currTarget.Location.Z <= Location.Z)
		{
			disToCurrTarget=VSize(currTarget.Location - Location);
			if(target == none || disToCurrTarget < distToTarget)
			{
				target=currTarget;
				distToTarget=disToCurrTarget;
			}
		}
    }
}

function LostTarget()
{
	targetLost=true;
}

function bool IsValidTarget(GGPawn targ)
{
	return (targ != myCreator.gMe && targ != goatHolder && targ.Controller != none);
}

function ShootTarget()
{
	if(!isActive || target == none || IsTimerActive(NameOf( ShootTarget )))
	{
		return;
	}

	mySphere.myGun.myLaser.Shoot();
	SetTimer(shotInterval, false, NameOf(ShootTarget));
}

function vector GetTargetPosition()
{
	return GetPosition(target);
}

function vector GetPosition(GGPawn pawn)
{
	if(pawn.mIsRagdoll)
	{
		return pawn.Mesh.GetPosition();
	}
	else
	{
		return pawn.Location;
	}
}

function bool RecycleDrone(GGPawn gpawn)
{
	if(gpawn != none && gpawn == goatHolder)
	{
		TryDestroy();
		return true;
	}

	return false;
}

function OnDestruction()
{
	mAc.FadeOut(2.f, 0.f);
	myCreator.DroneDestroyed(self);
	super.OnDestruction();
}

/*********************************************************************************************
 GRABBABLE ACTOR INTERFACE
*********************************************************************************************/

function OnGrabbed( Actor grabbedByActor )
{
	local GGGoat grabber;

	super.OnGrabbed( grabbedByActor );

	grabber=GGGoat(grabbedByActor);
	if(grabber != none && goatHolder == none )
	{
		HoldMe(grabber);
	}
}

/*********************************************************************************************
 END GRABBABLE ACTOR INTERFACE
*********************************************************************************************/

/**
 * Called when an actor begins to ragdoll
 */
function OnRagdoll( Actor ragdolledActor, bool isRagdoll )
{
	if(ragdolledActor == goatHolder)
	{
		DropMe();
	}
}

DefaultProperties
{
	Begin Object name=StaticMeshComponent0
		bNotifyRigidBodyCollision=true
		ScriptRigidBodyCollisionThreshold=50.0f
		CollideActors=true
		BlockActors=true
		BlockZeroExtent=true
		BlockNonZeroExtent=true

		StaticMesh=StaticMesh'Space_Portal.Meshes.DoorFrame'
		Materials[0]=Material'Kitchen_01.Materials.White_Mat_01'
		Scale3D=(X=0.2f,Y=0.2f,Z=0.2f)
		Rotation=(Pitch=16384,Yaw=0,Roll=0)
	End Object

	activeSound=SoundCue'Space_Podracer_Sounds.PodEngine.Podracer_Engine_Loop_Cue'
	mSoundVolume=0.25f

	scanRadius=2500.0f

	targetLost=true
	shotInterval=0.5f

	activationRange=15000.f
}