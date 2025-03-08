class EngineerGoatComponent extends GGMutatorComponent;

var GGGoat gMe;
var GGMutator myMut;

var int mTurretLimit;
var int mDroneLimit;
var bool mIsOffensive;
var bool mCreateDrone;
var array<Turret> myTurrets;
var array<Drone> myDrones;
var int oldestTurretIndex;
var int oldestDroneIndex;
var bool isBuilding;
var float mBuildTime;
var int mMaterialsRequired;
var int materialCount;
var ParticleSystem mBuildEffectTemplate;
var ParticleSystemComponent bluidEffect;
var AudioComponent ac;
var SoundCue mBuildSound;
var float mCraftForceRadius;
var GGRadialForceActor craftForceComp;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	super.AttachToPlayer(goat, owningMutator);

	if(mGoat != none)
	{
		gMe=goat;
		myMut=owningMutator;

		craftForceComp = mGoat.Spawn( class'GGRadialForceActor' );
		craftForceComp.ForceRadius = mCraftForceRadius;
		craftForceComp.ForceStrength = -1000.f;
		craftForceComp.SetBase( gMe,, gMe.mesh, 'Demonic' );
	}
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PCOwner.PlayerInput );

	if( keyState == KS_Down )
	{
		if( localInput.IsKeyIsPressed( "GBA_Special", string( newKey ) ) )
		{
			if(IsZero(gMe.Velocity))
			{
				gMe.SetTimer( mBuildTime, false, NameOf( CraftTurret ), self );
				StartCraftingEffect();
			}
		}
		if( localInput.IsKeyIsPressed( "GBA_Baa", string( newKey ) ) )
		{
			if(IsZero(gMe.Velocity))
			{
				RecycleRobot();
			}
		}
		if( newKey == 'LEFTCONTROL' || newKey == 'XboxTypeS_DPad_Down')
		{
			if(IsZero(gMe.Velocity))
			{
				SwapCraftedRobot();
			}
		}
	}
	else if( keyState == KS_Up )
	{
		if( localInput.IsKeyIsPressed( "GBA_Special", string( newKey ) ) )
		{
			if(gMe.IsTimerActive(NameOf( CraftTurret ), self))
			{
				gMe.ClearTimer(NameOf( CraftTurret ), self);
				StopCraftingEffect();
			}
		}
	}
}

function TurretDestroyed(Turret t)
{
	myTurrets.RemoveItem(t);
	if(myTurrets.Length < oldestTurretIndex)
	{
		oldestTurretIndex = myTurrets.Length;
	}
}

function DroneDestroyed(Drone d)
{
	myDrones.RemoveItem(d);
	if(myDrones.Length < oldestDroneIndex)
	{
		oldestDroneIndex = myDrones.Length;
	}
}

function StartCraftingEffect()
{
	local vector craftLocation;

	ac.Play();
	gMe.mesh.GetSocketWorldLocationAndRotation( 'Demonic', craftLocation );
	if(IsZero(craftLocation))
	{
		craftLocation=gMe.Location + (Normal(vector(gMe.Rotation)) * (gMe.GetCollisionRadius() + 30.f));
	}
	bluidEffect=gMe.WorldInfo.MyEmitterPool.SpawnEmitter(mBuildEffectTemplate, craftLocation);
	craftForceComp.bForceActive = true;
	isBuilding=true;
}

function StopCraftingEffect()
{
	ac.Stop();
	bluidEffect.DeactivateSystem();
	bluidEffect.KillParticlesForced();
	craftForceComp.bForceActive = false;
	isBuilding=false;
}

function SwapCraftedRobot()
{
	if(!mIsOffensive && !mCreateDrone)
	{
		mIsOffensive = true;
		myMut.WorldInfo.Game.Broadcast(myMut, "Offensive Turret");
	}
	else if(mIsOffensive && !mCreateDrone)
	{
		mCreateDrone = true;
		myMut.WorldInfo.Game.Broadcast(myMut, "Offensive Drone");
	}
	else if(mIsOffensive && mCreateDrone)
	{
		mIsOffensive = false;
		myMut.WorldInfo.Game.Broadcast(myMut, "Defensive Drone");
	}
	else if(!mIsOffensive && mCreateDrone)
	{
		mCreateDrone = false;
		myMut.WorldInfo.Game.Broadcast(myMut, "Defensive Turret");
	}
}

function CraftTurret()
{
	local GGPhysicalMaterialProperty physicalProperty;
	local GGKActor kAct;
	local vector craftLocation;

	StopCraftingEffect();

	gMe.mesh.GetSocketWorldLocationAndRotation( 'Demonic', craftLocation );
	if(IsZero(craftLocation))
	{
		craftLocation=gMe.Location + (Normal(vector(gMe.Rotation)) * (gMe.GetCollisionRadius() + 30.f));
	}
	foreach gMe.OverlappingActors( class'GGKActor', kAct, mCraftForceRadius, craftLocation )
	{
		physicalProperty = GGPhysicalMaterialProperty( kAct.GetKActorPhysMaterial().GetPhysicalMaterialProperty( class'GGPhysicalMaterialProperty' ) );
        if( physicalProperty != none && LinkedKActor(kAct) == none)
        {
            //myMut.WorldInfo.Game.Broadcast(myMut, "[" $ kAct $ "]=" $ physicalProperty.MaterialType);
			if(physicalProperty.MaterialType == 'Metal' || physicalProperty.MaterialType == 'Road' || physicalProperty.MaterialType == 'Dirt')
			{
				if(!kAct.Destroy())
				{
					kAct.ShutDown();
				}
				materialCount++;

				if(materialCount == (mTurretLimit + 1)*mMaterialsRequired - 1)
			}
        }
	}

	if(materialCount >= mMaterialsRequired)
	{
		materialCount -= mMaterialsRequired;
		if(mCreateDrone)
		{
			SpawnDrone();
		}
		else
		{
			SpawnTurret();
		}
	}
	DisplayMaterialCount(craftLocation);
}

function SpawnDrone()
{
	local vector spawnLocation;
	local Drone newDrone, oldDrone;

	gMe.mesh.GetSocketWorldLocationAndRotation( 'Demonic', spawnLocation );
	if(IsZero(spawnLocation))
	{
		spawnLocation=gMe.Location + (Normal(vector(gMe.Rotation)) * (gMe.GetCollisionRadius() + 30.f));
	}
	newDrone = gMe.Spawn( class'Drone',,, spawnLocation,gMe.Rotation,, true);
	newDrone.InitDrone(self);
	if(myDrones.Length < mDroneLimit)
	{
		myDrones.AddItem(newDrone);
	}
	else
	{
		oldDrone=myDrones[oldestDroneIndex];
		myDrones[oldestDroneIndex]=newDrone;
		oldestDroneIndex++;
		if(oldestDroneIndex >= myDrones.Length)
		{
			oldestDroneIndex=0;
		}
		oldDrone.TryDestroy();
	}
	newDrone.CollisionComponent.WakeRigidBody();
}

function SpawnTurret()
{
	local vector spawnLocation;
	local Turret newTurret, oldTurret;

	gMe.mesh.GetSocketWorldLocationAndRotation( 'Demonic', spawnLocation );
	if(IsZero(spawnLocation))
	{
		spawnLocation=gMe.Location + (Normal(vector(gMe.Rotation)) * (gMe.GetCollisionRadius() + 30.f));
	}
	newTurret = gMe.Spawn( class'Turret',,, spawnLocation,gMe.Rotation,, true);
	newTurret.InitTurret(self);
	if(myTurrets.Length < mTurretLimit)
	{
		myTurrets.AddItem(newTurret);
	}
	else
	{
		oldTurret=myTurrets[oldestTurretIndex];
		myTurrets[oldestTurretIndex]=newTurret;
		oldestTurretIndex++;
		if(oldestTurretIndex >= myTurrets.Length)
		{
			oldestTurretIndex=0;
		}
		oldTurret.TryDestroy();
	}
	newTurret.CollisionComponent.WakeRigidBody();
}

function TickMutatorComponent( float deltaTime )
{
	if(ac == none || ac.IsPendingKill())
	{
		ac=gMe.CreateAudioComponent(mBuildSound, isBuilding);
	}
	if(isBuilding && !ac.IsPlaying())
	{
		ac.Play();
	}

	if(isBuilding && !IsZero(gMe.Velocity))
	{
		gMe.ClearTimer(NameOf( CraftTurret ), self);
		StopCraftingEffect();
	}
}

function RecycleRobot()
{
	local Turret t;
	local Drone d;
	local vector loc;

	foreach myTurrets(t)
	{
		loc = t.Location;
		if(t.RecycleTurret(gMe))
		{
			materialCount += mMaterialsRequired;
			DisplayMaterialCount(loc);
			break;
		}
	}
	foreach myDrones(d)
	{
		loc = d.Location;
		if(d.RecycleDrone(gMe))
		{
			materialCount += mMaterialsRequired;
			DisplayMaterialCount(loc);
			break;
		}
	}
}

function DisplayMaterialCount(vector loc)
{
	EngineerGoat(myMut).mCachedCombatTextManager.AddCombatTextString(materialCount @ "/" @ mMaterialsRequired, loc-gMe.Location, TC_XP, gMe.Controller);
}

/**
 * Called when an actor begins to ragdoll
 */
function OnRagdoll( Actor ragdolledActor, bool isRagdoll )
{
	local Turret t;
	local Drone d;

	foreach myTurrets(t)
	{
		t.OnRagdoll( ragdolledActor, isRagdoll );
	}
	foreach myDrones(d)
	{
		d.OnRagdoll( ragdolledActor, isRagdoll );
	}
}

defaultproperties
{
	mTurretLimit=10
	mDroneLimit=10
	mBuildTime=3.5f
	mMaterialsRequired=10
	mCraftForceRadius=300.f

	mBuildSound=SoundCue'MMO_SFX_SOUND.Cue.SFX_Anvil_Hit_Small_1_Cue'
	mBuildEffectTemplate=ParticleSystem'Goat_Effects.Effects.Effects_Skid_01'
}