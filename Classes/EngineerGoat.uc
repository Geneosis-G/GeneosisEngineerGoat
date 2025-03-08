class EngineerGoat extends GGMutator;
/** The MMO combat text. */
var instanced GGCombatTextManager mCachedCombatTextManager;

/**
 * See super.
 */
function ModifyPlayer(Pawn Other)
{
	local GGGameInfoMMO gameInfoMMO;

	super.ModifyPlayer( other );

	if(mCachedCombatTextManager == none)
	{
		gameInfoMMO = GGGameInfoMMO( WorldInfo.Game );
		if( gameInfoMMO != none )
		{
			mCachedCombatTextManager = gameInfoMMO.mCombatTextManager;
		}
		else
		{
			mCachedCombatTextManager = Spawn( class'GGCombatTextManager' );
		}
	}
}

DefaultProperties
{
	mMutatorComponentClass=class'EngineerGoatComponent'
}