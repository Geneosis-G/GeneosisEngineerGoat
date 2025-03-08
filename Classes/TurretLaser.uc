class TurretLaser extends LinkedKActor;

var bool mIsOffensive;
var ParticleSystem mDefensiveLaserRay;
var ParticleSystem mOffensiveLaserRay;
var ParticleSystem mLaserHit;
var SoundCue mDefensiveLaserSound;
var SoundCue mOffensiveLaserSound;
var vector laserOffset;
var float mLaserRange;
var float mLaserMomentum;
var float mMomentumMultiplier;
var float mLaserDamages;

function string GetActorName()
{
	return "Turret";
}

function InitLinkedKActor(LinkedKActor l)
{
	super.InitLinkedKActor(l);
	mIsOffensive=TurretGun(mParent).mIsOffensive;

	SetPhysics(PHYS_None);
	SetCollisionType( COLLIDE_NoCollision );

	InitLaserBeam();
}

function InitLaserBeam()
{
	local ParticleEmitter pe;
	local ParticleLODLevel plodl;
	local ParticleModule pm;
	local ParticleModuleBeamTarget pmbt;

	foreach mDefensiveLaserRay.Emitters(pe)
	{
		foreach pe.LODLevels(plodl)
		{
			foreach plodl.Modules(pm)
			{
				pmbt=ParticleModuleBeamTarget(pm);
				if(pmbt != none)
				{
					//WorldInfo.Game.Broadcast(self, "particle updated : " $ pmbt);
					pmbt.bTargetAbsolute=true;
				}
			}
		}
	}
	foreach mOffensiveLaserRay.Emitters(pe)
	{
		foreach pe.LODLevels(plodl)
		{
			foreach plodl.Modules(pm)
			{
				pmbt=ParticleModuleBeamTarget(pm);
				if(pmbt != none)
				{
					//WorldInfo.Game.Broadcast(self, "particle updated : " $ pmbt);
					pmbt.bTargetAbsolute=true;
				}
			}
		}
	}
}

function Shoot()
{
	local Turret turret;
	local Drone drone;
	local vector dir, hitLocation, traceStart, traceEnd, hitNormal, targetLocation;
	local rotator traceDir;
	local Actor hitActor;
	local GGPawn hitPawn;
	local GGPawn laserTarget;
	local ParticleSystemComponent psc;
	local AudioComponent tmpAc;

	turret=Turret(GetRoot());
	drone=Drone(GetRoot());
	if(turret != none)
	{
		laserTarget=turret.target;
	}
	if(drone != none)
	{
		laserTarget=drone.target;
	}
	if(laserTarget == none)
	{
		return;
	}

	//Find actor touched by the laser
	if(turret != none)
	{
		targetLocation=turret.GetTargetPosition();
	}
	if(drone != none)
	{
		targetLocation=drone.GetTargetPosition();
	}
	traceStart=TransformVectorByRotation(Rotation, laserOffset) + Location;
	traceDir=QuatToRotator(QuatSlerp(QuatFromRotator(Rotation), QuatFromRotator(Rotator(Normal(targetLocation-traceStart))), FRand()));
	traceEnd=(Vector(traceDir) * mLaserRange) + traceStart;

	hitActor=Trace(hitLocation, hitNormal, traceEnd, traceStart, true);
	if( hitActor == none )
	{
		hitLocation=traceEnd;
	}
	dir = Normal( traceEnd - traceStart );

	//Fix ragdoll not hit correctly
	if(laserTarget.mIsRagdoll)
	{
		if(hitActor == none || VSize(targetLocation-traceStart)<VSize(hitLocation-traceStart))
		{
			hitActor=laserTarget;
			hitLocation=PointProjectToPlane(targetLocation, traceEnd, traceStart, Normal(dir cross (targetLocation - traceStart)) + traceEnd);
		}
	}

	//Laser sound
	tmpAc=CreateAudioComponent(mIsOffensive?mOffensiveLaserSound:mDefensiveLaserSound, false, true, true, Location, true);
	tmpAc.VolumeMultiplier=0.3f;
	tmpAc.Play();
	//Laser beam effect
	psc=WorldInfo.MyEmitterPool.SpawnEmitter(mIsOffensive?mOffensiveLaserRay:mDefensiveLaserRay, traceStart, rotator(dir));
	psc.SetVectorParameter('ShockBeamEnd', hitLocation);

	if(hitActor != none)
	{
		//Laser hit effect
		WorldInfo.MyEmitterPool.SpawnEmitter(mLaserHit, hitLocation);

		dir.Z += 1.0f;

		//If living pawn
		hitPawn=GGPawn(hitActor);
		if(hitPawn != none && !hitPawn.mIsRagdoll)
		{
			hitPawn.SetPhysics( PHYS_Falling );

			//apply force, with a random factor (0.75 - 1.25)
			hitPawn.HandleMomentum( dir * mLaserMomentum * Lerp( 0.75f, 1.25f, FRand() ), hitLocation, class'GGDamageTypeGTwo' );
			// Apply damages
			if(mIsOffensive)
			{
				ApplymLaserDamages(hitActor, hitLocation, dir);
			}
			//maybe ragdoll
			if( FRand() < 0.10f )
			{
				hitPawn.SetRagdoll( true );
			}
		}
		//If object or ragdoll
		else if( !hitActor.bWorldGeometry )
		{
			hitActor.TakeDamage( 0, none, hitLocation, dir * mLaserMomentum * mMomentumMultiplier * Lerp( 0.75f, 1.25f, FRand() ), class'GGDamageTypeGTwo',, self);
			if(mIsOffensive)
			{
				ApplymLaserDamages(hitActor, hitLocation, dir);
			}
		}
	}
}

function ApplymLaserDamages(Actor hitActor, vector hitLocation, vector hitNormal)
{
	local GGPawn gpawn;
	local GGNPCMMOEnemy mmoEnemy;
	local GGNpcZombieGameModeAbstract zombieEnemy;
	local GGKactor kActor;
	local GGSVehicle vehicle;
	local GGApexDestructibleActor apexActor;

	gpawn = GGPawn(hitActor);
	mmoEnemy = GGNPCMMOEnemy(hitActor);
	zombieEnemy = GGNpcZombieGameModeAbstract(hitActor);
	kActor = GGKActor(hitActor);
	vehicle = GGSVehicle(hitActor);
	apexActor=GGApexDestructibleActor(hitActor);
	if(gpawn != none)
	{
		//Damage MMO enemies
		if(mmoEnemy != none)
		{
			mmoEnemy.TakeDamageFrom( mLaserDamages, none, class'GGDamageTypeExplosiveActor');
		}
		//Damage zombies
		else if(zombieEnemy != none)
		{
			zombieEnemy.TakeDamage( mLaserDamages, none, hitLocation, hitNormal, class'GGDamageTypeZombieSurvivalMode');
		}
		else
		{
			gpawn.TakeDamage( mLaserDamages, none, hitLocation, hitNormal, class'GGDamageTypeGTwo',, self);
		}
		if(!gpawn.mIsRagdoll)
		{
			gpawn.SetRagdoll(true);
		}
	}
	if(kActor != none)
	{
		kActor.TakeDamage( mLaserDamages, none, hitLocation, hitNormal, class'GGDamageTypeGTwo',, self);
	}
	else if(vehicle != none)
	{
		vehicle.TakeDamage( mLaserDamages, none, hitLocation, hitNormal, class'GGDamageTypeGTwo',, self);
	}
	else if(apexActor != none)
	{
		if(!apexActor.mIsFractured)
		{
			apexActor.Fracture(0, none, hitLocation, hitNormal, class'GGDamageTypeAbility');
		}
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

		StaticMesh=StaticMesh'CityProps.Mesh.Lights_lamp_B'
		Scale3D=(X=0.1f,Y=0.1f,Z=0.1f)
		Rotation=(Pitch=-16384,Yaw=0,Roll=0)
	End Object

	mPosOffset=(X=-9.f,Y=0.f,Z=0.f)
	laserOffset=(X=40.f,Y=0.f,Z=0.f)

	mLaserRange=5000.f
	mLaserMomentum=750.0f
	mMomentumMultiplier=20.f;
	mLaserDamages=50.f

	mDefensiveLaserRay=ParticleSystem'MMO_Effects.Effects.Effects_Cow_Laser_01'
	mOffensiveLaserRay=ParticleSystem'MMO_Effects.Effects.Effects_Cow_Laser_02'
	mLaserHit=ParticleSystem'MMO_Effects.Effects.Effects_LaserHit_01'
	mDefensiveLaserSound=SoundCue'MMO_SFX_SOUND.Cue.SFX_Cow_Lazer_Cue'
	mOffensiveLaserSound=SoundCue'EngineerGoatSounds.Chihuahua_Turrets_Laser_02_Cue'
}