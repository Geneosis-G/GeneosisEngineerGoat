class LinkedKActor extends GGKActor;

var bool triedToDestroy;
var LinkedKActor mParent;
var array<LinkedKActor> linkedActors;

var vector mPosOffset;
var float mRotationInterpSpeed;

function InitLinkedKActor(LinkedKActor l)
{
	mParent=l;
	linkedActors.AddItem(mParent);
}

function TryDestroy()
{
	if(!triedToDestroy && !bDeleteMe && !bPendingDelete)
	{
		triedToDestroy=true;
		if(!Destroy())
		{
			ShutDown();
		}
	}
}

simulated event ShutDown()
{
	OnDestruction();
	super.ShutDown();
}

simulated event Destroyed()
{
	OnDestruction();
	Super.Destroyed();
}

function OnDestruction()
{
	local LinkedKActor la;

	foreach linkedActors(la)
	{
		la.TryDestroy();
	}
}

function SetLocationAndRotation( float deltaTime )
{
	local vector newLocation;
	local rotator newRotation;

	newRotation = mParent.Rotation;
	newLocation = TransformVectorByRotation(mParent.Rotation, mPosOffset) + mParent.Location;

	SetLocation(newLocation);
	SetRotation(newRotation);
}

function LinkedKActor GetRoot()
{
	if(mParent == none)
	{
		return self;
	}
	else
	{
		return mParent.GetRoot();
	}
}

DefaultProperties
{
	bNoDelete=false
	bStatic=false
}