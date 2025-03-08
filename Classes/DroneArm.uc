class DroneArm extends LinkedKActor;

var DroneRotor myRotor;

function string GetActorName()
{
	return "Drone";
}

function InitLinkedKActor(LinkedKActor l)
{
		super.InitLinkedKActor(l);

		SetPhysics(PHYS_None);
		SetCollisionType( COLLIDE_NoCollision );

		myRotor=Spawn(class'DroneRotor', self,, Location, Rotation,, true);
		myRotor.InitLinkedKActor(self);
		linkedActors.AddItem(myRotor);
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

		//StaticMesh=StaticMesh'Zombie_Food.Meshes.Food_Banana_01'
		StaticMesh=StaticMesh'Windmill.mesh.Windmill_Shaft'
		//Materials[0]=Material'Kitchen_01.Materials.White_Mat_01'
		Scale3D=(X=0.03f,Y=0.03f,Z=0.03f)
		Rotation=(Pitch=0,Yaw=-16384,Roll=12000)
	End Object

	mPosOffset=(X=10,Y=0.f,Z=0.f)
}