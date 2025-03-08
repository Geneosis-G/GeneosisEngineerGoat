class TurretCamera extends LinkedKActor;

var TurretEye myEye;

function string GetActorName()
{
	return "Turret";
}

function InitLinkedKActor(LinkedKActor l)
{
		super.InitLinkedKActor(l);

		SetPhysics(PHYS_None);
		SetCollisionType( COLLIDE_NoCollision );

		myEye=Spawn(class'TurretEye', self,, Location, Rotation,, true);
		myEye.InitLinkedKActor(self);
		linkedActors.AddItem(myEye);
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

		StaticMesh=StaticMesh'Goat_Props_01.Mesh.Thermos_02'
		Scale3D=(X=1.5f,Y=1.5f,Z=1.5f)
		Rotation=(Pitch=-16384,Yaw=32767,Roll=0)
	End Object

	mPosOffset=(X=30.f,Y=0.f,Z=170.f)
}