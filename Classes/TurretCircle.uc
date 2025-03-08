class TurretCircle extends LinkedKActor;

var TurretPivot myPivot;

function string GetActorName()
{
	return "Turret";
}

function InitLinkedKActor(LinkedKActor l)
{
		super.InitLinkedKActor(l);

		SetPhysics(PHYS_None);
		SetCollisionType( COLLIDE_NoCollision );

		myPivot=Spawn(class'TurretPivot', self,, Location, Rotation,, true);
		myPivot.InitLinkedKActor(self);
		linkedActors.AddItem(myPivot);
}

function SetLocationAndRotation( float deltaTime )
{
	local Turret turret;
	local vector newLocation, targetLocation, X, Y, Z, tX, tY, tZ, vertLocation, targetDirection;
	local rotator newRotation, desiredRotation;

	newRotation = mParent.Rotation;
	newLocation = TransformVectorByRotation(mParent.Rotation, mPosOffset) + mParent.Location;

	turret=Turret(GetRoot());
	if(turret.target != none)
	{
		targetLocation=turret.GetTargetPosition();
		GetAxes(mParent.Rotation, tX, tY, tZ);
		//DrawDebugLine(newLocation, targetLocation, 100, 100, 100, false);
		//WorldInfo.Game.Broadcast(self, "targetLocation : " $ targetLocation);

		GetAxes(newRotation, X, Y, Z);
		//DrawDebugLine(newLocation, newLocation + X*100, 255, 0, 0, false);
		//DrawDebugLine(newLocation, newLocation + Y*100, 0, 255, 0, false);
		//DrawDebugLine(newLocation, newLocation + Z*100, 0, 0, 255, false);

		vertLocation=PointProjectToPlane(targetLocation, newLocation, newLocation + X, newLocation + Y);
		//WorldInfo.Game.Broadcast(self, "vertLocation : " $ vertLocation);
		//DrawDebugLine(newLocation, vertLocation, 255, 255, 255, false);

		targetDirection=Normal(vertLocation-newLocation);
		desiredRotation=OrthoRotation(targetDirection, -Normal(targetDirection cross tZ), tZ);
		newRotation=RInterpTo( Rotation, desiredRotation, deltaTime, mRotationInterpSpeed, false );
	}
	else
	{
		if(!turret.targetLost)
		{
			newRotation=RInterpTo( Rotation, mParent.Rotation, deltaTime, mRotationInterpSpeed, false );
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

		StaticMesh=StaticMesh'Goat_Props_01.Mesh.RingIndustry_Small_02'
		Scale3D=(X=0.069f,Y=0.069f,Z=0.069f)
		Rotation=(Pitch=0,Yaw=16384,Roll=0)
	End Object

	mPosOffset=(X=0.f,Y=0.f,Z=140.f)

	mRotationInterpSpeed=10.f
}