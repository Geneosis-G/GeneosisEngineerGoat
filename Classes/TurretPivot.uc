class TurretPivot extends LinkedKActor;

var TurretGun myLeftGun;
var TurretGun myRightGun;

function string GetActorName()
{
	return "Turret";
}

function InitLinkedKActor(LinkedKActor l)
{
		local vector vScale;
		super.InitLinkedKActor(l);

		SetPhysics(PHYS_None);
		SetCollisionType( COLLIDE_NoCollision );

		myLeftGun=Spawn(class'TurretGun', self,, Location, Rotation,, true);
		myLeftGun.mPosOffset.Y*=-1;
		vScale=myLeftGun.CollisionComponent.Scale3D;
		vScale.Y*=-1;
		myLeftGun.CollisionComponent.SetScale3D(vScale);
		myLeftGun.InitLinkedKActor(self);
		linkedActors.AddItem(myLeftGun);

		myRightGun=Spawn(class'TurretGun', self,, Location, Rotation,, true);
		myRightGun.InitLinkedKActor(self);
		linkedActors.AddItem(myRightGun);
}

function SetLocationAndRotation( float deltaTime )
{
	local Turret turret;
	local vector newLocation, targetLocation, X, Y, Z, cX, cY, cZ, vertLocation, targetDirection;
	local rotator newRotation, desiredRotation;

	newRotation = mParent.Rotation;
	newLocation = mParent.Location;

	turret=Turret(GetRoot());
	if(turret.target != none)
	{
		targetLocation=turret.GetTargetPosition();
		GetAxes(mParent.Rotation, cX, cY, cZ);

		GetAxes(newRotation, X, Y, Z);
		vertLocation=PointProjectToPlane(targetLocation, newLocation, newLocation + X, newLocation + Z);

		targetDirection=Normal(vertLocation-newLocation);
		desiredRotation=OrthoRotation(targetDirection, cY, Normal(targetDirection cross cY));
		newRotation=RInterpTo( Rotation, desiredRotation, deltaTime, mParent.mRotationInterpSpeed, false );
	}
	else
	{
		if(!turret.targetLost)
		{
			newRotation=RInterpTo( Rotation, mParent.Rotation, deltaTime, mParent.mRotationInterpSpeed, false );
		}
	}

	SetLocation(newLocation);
	SetRotation(newRotation);
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

		StaticMesh=StaticMesh'Props_01.Mesh.Baseball_01'
	End Object
}