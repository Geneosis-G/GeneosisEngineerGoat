class Turret extends LinkedKActor;

var EngineerGoatComponent myCreator;
var GGPawn goatHolder;

var PhysicalMaterial customPhysMat;
var TurretCircle myCircle;
var TurretCamera myCamera;

var bool isActive;
var bool mIsOffensive;
var float activationHalfAngle;
var GGPawn target;
var float distToTarget;
var float scanRadius;
var float scanHalfAngle;
var AudioComponent mAc;
var SoundCue activeSound;
var bool targetLost;

var bool shootLeft;
var float shotInterval;

var float activationRange;

function string GetActorName()
{
	return "Turret";
}

function InitTurret(EngineerGoatComponent creator)
{
	myCreator=creator;
	mIsOffensive=myCreator.mIsOffensive;
	StaticMeshComponent.SetPhysMaterialOverride(customPhysMat);

	myCircle=Spawn(class'TurretCircle', self,, Location, Rotation,, true);
	myCircle.InitLinkedKActor(self);
	linkedActors.AddItem(myCircle);

	myCamera=Spawn(class'TurretCamera', self,, Location, Rotation,, true);
	myCamera.InitLinkedKActor(self);
	linkedActors.AddItem(myCamera);
}

function HoldMe(GGPawn goat)
{
	local vector desiredPos, diagonalOffset;
	local float diagonalLength, radius, height, gRadius, gHeight;
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

	SetPhysics(PHYS_None);
	goatHolder=goat;

	goatHolder.Mesh.GetSocketWorldLocationAndRotation( 'Demonic', desiredPos );
	if(IsZero(desiredPos))
	{
		desiredPos=goatHolder.Location + (Normal(vector(goatHolder.Rotation)) * (goatHolder.GetCollisionRadius() + 30.f));
	}
	diagonalOffset=desiredPos-goatHolder.Location;
	diagonalLength=VSize(diagonalOffset);
	mPosOffset.Z=diagonalOffset.Z;
	goatHolder.GetBoundingCylinder( gRadius, gHeight );
	GetBoundingCylinder( radius, height );
	mPosOffset.X=FMax(sqrt(diagonalLength*diagonalLength - diagonalOffset.Z*diagonalOffset.Z), gRadius+radius+1.f);
}

function DropMe()
{
	SetPhysics(PHYS_RigidBody);
	goatHolder=none;
}

event Tick( float deltaTime )
{
	super.Tick( deltaTime );

	if(mAc == none || mAc.IsPendingKill())
	{
		mAc=CreateAudioComponent(activeSound, false);
		//ac.PitchMultiplier = 2.f;

		if(isActive && !mAc.IsPlaying())
		{
			mAc.Play();
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
	myCircle.SetLocationAndRotation( deltaTime );
	myCircle.myPivot.SetLocationAndRotation( deltaTime );
	myCircle.myPivot.myLeftGun.SetLocationAndRotation( deltaTime );
	myCircle.myPivot.myLeftGun.myLaser.SetLocationAndRotation( deltaTime );
	myCircle.myPivot.myRightGun.SetLocationAndRotation( deltaTime );
	myCircle.myPivot.myRightGun.myLaser.SetLocationAndRotation( deltaTime );
	myCamera.SetLocationAndRotation( deltaTime );
	myCamera.myEye.SetLocationAndRotation( deltaTime );
}

function SetLocationAndRotation( float deltaTime )
{
	local vector newLocation;
	local rotator newRotation;

	if(goatHolder == none)
	{
		return;
	}

	newRotation = rot(0, 1, 0) * goatHolder.Rotation.Yaw;
	newLocation = TransformVectorByRotation(newRotation, mPosOffset) + goatHolder.Location;

	SetLocation(newLocation);
	SetRotation(newRotation);
}

function UpdateActivation()
{
	local vector X, Y, Z, upDirection;
	local float dotTreshold;
	local GGPlayerControllerGame pc;
	local bool outOfRange;
	local bool wasActive;

	wasActive=isActive;
	upDirection = Normal( vect(0, 0, 1) );
    dotTreshold = Cos( activationHalfAngle );

	GetAxes(Rotation, X, Y, Z);
	// Active if angle < 45 deg
	isActive = ( Z dot upDirection > dotTreshold);

	// Deactivate turret if no goat near
	if(isActive)
	{
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
	}

	bEnableStayUprightSpring=isActive;
	myCamera.myEye.redGlow.SetHidden(!isActive);
	// Manage sound
	if(isActive && !wasActive && !mAc.IsPlaying())
	{
		mAc.FadeIn(2.f, 1.f);
	}
	if(!isActive && wasActive && mAc.IsPlaying())
	{
		mAc.FadeOut(2.f, 0.f);
	}
}

function AquireTarget()
{
	local vector forceDirection, fireDirection;
	local float dotTreshold, disToCurrTarget;
	local GGPawn currTarget;

	fireDirection = Normal( vector( Rotation ) );
    dotTreshold = Cos( scanHalfAngle );

	foreach VisibleCollidingActors( class'GGPawn', currTarget, scanRadius, myCamera.myEye.Location )
    {
		if(!IsValidTarget(currTarget))
		{
			continue;
		}

		forceDirection = Normal( currTarget.Location - Location );
		// Angle < 45 deg
        if( forceDirection dot fireDirection > dotTreshold)
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

	shootLeft=!shootLeft;
	if(shootLeft)
	{
		myCircle.myPivot.myLeftGun.myLaser.Shoot();
	}
	else
	{
		myCircle.myPivot.myRightGun.myLaser.Shoot();
	}
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

function bool RecycleTurret(GGPawn gpawn)
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
	myCreator.TurretDestroyed(self);
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

		StaticMesh=StaticMesh'Props_01.Mesh.EasterEgg_Grill_01'
		Scale3D=(X=1.5f,Y=1.5f,Z=2.f)
		Rotation=(Pitch=0,Yaw=-16384,Roll=0)
	End Object

	customPhysMat=PhysicalMaterial'Physical_Materials.goat.PhysMat_BaseballMachine'
	activeSound=SoundCue'EngineerGoatSounds.Turret_Active_Cue'

	bEnableStayUprightSpring=true
	StayUprightMaxTorque=1500 //default 1500
	StayUprightTorqueFactor=1500 //default 1000
	activationHalfAngle=0.78f

	scanRadius=2500.0f
	scanHalfAngle=0.78f

	targetLost=true
	shotInterval=0.25f

	activationRange=15000.f
}