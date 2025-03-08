class TurretEye extends LinkedKActor;

var ParticleSystem redGlowTemplate;
var ParticleSystemComponent redGlow;

function string GetActorName()
{
	return "Turret";
}

function InitLinkedKActor(LinkedKActor l)
{
		super.InitLinkedKActor(l);

		SetPhysics(PHYS_None);
		SetCollisionType( COLLIDE_NoCollision );

		redGlow = WorldInfo.MyEmitterPool.SpawnEmitter( redGlowTemplate, Location, Rotation, self );
		redGlow.SetScale3D(vect(0.1f, 0.1f, 0.1f));
}

function OnDestruction()
{
	redGlow.DeactivateSystem();
	redGlow.KillParticlesForced();
	super.OnDestruction();
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

		StaticMesh=StaticMesh'MMO_Props_02.Mesh.Fisheye_01'
		Scale3D=(X=1.f,Y=1.f,Z=1.f)
		Rotation=(Pitch=-16384,Yaw=0,Roll=0)
	End Object

	redGlowTemplate=ParticleSystem'Zombie_Particles.Particles.Crate_Light_PS'

	mPosOffset=(X=-5.f,Y=2.5f,Z=0.f)
}