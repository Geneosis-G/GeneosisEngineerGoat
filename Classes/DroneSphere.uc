class DroneSphere extends LinkedKActor;

var TurretGun myGun;

var Material mDefensiveMaterial;

function string GetActorName()
{
	return "Drone";
}

function InitLinkedKActor(LinkedKActor l)
{
		super.InitLinkedKActor(l);
		if(!Drone(GetRoot()).mIsOffensive)
		{
			StaticMeshComponent.SetMaterial(0, mDefensiveMaterial);
		}

		SetPhysics(PHYS_None);
		SetCollisionType( COLLIDE_NoCollision );

		myGun=Spawn(class'TurretGun', self,, Location, Rotation,, true);
		myGun.mPosOffset.X+=15.f;
		myGun.mPosOffset.Y=0.f;
		myGun.InitLinkedKActor(self);
		linkedActors.AddItem(myGun);
}

function SetLocationAndRotation( float deltaTime )
{
	local Drone drone;
	local vector newLocation, targetLocation;
	local rotator newRotation, desiredRotation;

	newRotation = mParent.Rotation;
	newLocation = TransformVectorByRotation(mParent.Rotation, mPosOffset) + mParent.Location;

	drone=Drone(GetRoot());
	if(drone.target != none)
	{
		targetLocation=drone.GetTargetPosition();
		desiredRotation = rotator(Normal(targetLocation - Location));
		newRotation=RInterpTo( Rotation, desiredRotation, deltaTime, mRotationInterpSpeed, false );
	}
	else
	{
		if(!drone.targetLost)
		{
			newRotation=RInterpTo( Rotation, mParent.Rotation, deltaTime, mRotationInterpSpeed, false );
		}
	}

	SetLocation(newLocation);
	SetRotation(newRotation);
}

DefaultProperties
{
	mDefensiveMaterial=Material'GasStation.Materials.Roof_Blue_Mat_01'

	Begin Object name=StaticMeshComponent0
		bNotifyRigidBodyCollision=true
		ScriptRigidBodyCollisionThreshold=50.0f
		CollideActors=true
		BlockActors=true
		BlockZeroExtent=true
		BlockNonZeroExtent=true

		StaticMesh=StaticMesh'Zombie_Craftable_Items.Meshes.Crystal_Ball'
		Materials[0]=Material'GasStation.Materials.FireExtinguisher_Red'
		Scale3D=(X=3.5f,Y=3.5f,Z=3.5f)
		Rotation=(Pitch=0,Yaw=0/*16384*/,Roll=0)
	End Object

	mPosOffset=(X=-20.f,Y=0.f,Z=-25.f)

	mRotationInterpSpeed=10.f
}