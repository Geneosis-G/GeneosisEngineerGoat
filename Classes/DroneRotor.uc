class DroneRotor extends LinkedKActor;

function string GetActorName()
{
	return "Drone";
}

function InitLinkedKActor(LinkedKActor l)
{
		super.InitLinkedKActor(l);

		SetPhysics(PHYS_None);
		SetCollisionType( COLLIDE_NoCollision );
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

		StaticMesh=StaticMesh'Space_ObstacleCourse.Meshes.Net_Square'
		Materials[0]=Material'Helikopter.Materials.RotorBlades_Mat'
		Scale3D=(X=0.3f,Y=0.3f,Z=0.3f)
		Rotation=(Pitch=0,Yaw=0,Roll=0)
	End Object

	mPosOffset=(X=78.f,Y=0.f,Z=40.f)
}