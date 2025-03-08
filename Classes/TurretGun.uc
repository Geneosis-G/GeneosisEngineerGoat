class TurretGun extends LinkedKActor;

var Turret myTurret;
var Drone myDrone;
var TurretLaser myLaser;

var bool mIsOffensive;
var Material mDefensiveMaterial;

function string GetActorName()
{
	return "Turret";
}

function InitLinkedKActor(LinkedKActor l)
{
		super.InitLinkedKActor(l);
		myTurret=Turret(GetRoot());
		myDrone=Drone(GetRoot());
		if(myTurret != none)
		{
			mIsOffensive=myTurret.mIsOffensive;
		}
		else
		{
			mIsOffensive=myDrone.mIsOffensive;
		}
		SetPhysics(PHYS_None);
		SetCollisionType( COLLIDE_NoCollision );

		if(!mIsOffensive)
		{
			StaticMeshComponent.SetMaterial(0, mDefensiveMaterial);
		}

		myLaser=Spawn(class'TurretLaser', self,, Location, Rotation,, true);
		myLaser.InitLinkedKActor(self);
		linkedActors.AddItem(myLaser);
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

		StaticMesh=StaticMesh'GasStation.mesh.GasStation_FireExtinguisher'
		Materials[0]=Material'GasStation.Materials.FireExtinguisher_Red'
		Scale3D=(X=1.f,Y=1.f,Z=1.f)
		Rotation=(Pitch=16384,Yaw=0,Roll=0)
	End Object

	mPosOffset=(X=24.f,Y=49.f,Z=0.f)

	//StaticMesh'CityProps.Mesh.Lights_lamp_B'
}