//---------------------------------------------------------------------------------------
//  FILE:    XMBEffect_AddAbilityCharges.uc
//  AUTHOR:  xylthixlm
//
//  An effect which adds additional charges to a limited-use ability.
//
//  EXAMPLES
//
//  The following examples in Examples.uc use this class:
//
//  InspireAgility
//
//  INSTALLATION
//
//  Install the XModBase core as described in readme.txt. Copy this file, and any files 
//  listed as dependencies, into your mod's Classes/ folder. You may edit this file.
//
//  DEPENDENCIES
//
//  XMBEffectUtilities.uc
//---------------------------------------------------------------------------------------
class XMBEffect_AddAbilityCharges extends X2Effect;

var Array<name> AbilityNames;				// List of ability template names that will have charges added
var int BonusCharges;						// Number of bonus charges to add
var int MaxCharges;							// Maximum number of charges after adding bonus. A negative 
											// value means no limit.
var bool bAllowUseAmmoAsCharges;			// Some abilities display the amount of ammo left in place of
											// the ability charges, for example LaunchGrenade. If this is
											// true, this effect will give those abilities extra ammo
											// instead of extra charges.


simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit NewUnit;
	local XComGameState_Ability AbilityState;
	local XComGameStateHistory History;
	local StateObjectReference ObjRef;
	local XComGameState_BattleData BattleData;
	local int Charges;
	
	NewUnit = XComGameState_Unit(kNewTargetState);
	if (NewUnit == none)
		return;

	History = `XCOMHISTORY;

	// Don't add the extra item if this is a direct mission transfer. It will have been already 
	// added in the first non-transfer mission.
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if (BattleData.DirectTransferInfo.IsDirectMissionTransfer && class'XMBEffectUtilities'.static.IsPostBeginPlayTrigger(ApplyEffectParameters))
		return;

	foreach NewUnit.Abilities(ObjRef)
	{
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(ObjRef.ObjectID));
		if (AbilityNames.Find(AbilityState.GetMyTemplateName()) != INDEX_NONE)
		{
			Charges = bAllowUseAmmoAsCharges ? AbilityState.GetCharges() : AbilityState.iCharges;
			if (MaxCharges < 0 || Charges < MaxCharges)
			{
				Charges += BonusCharges;
				if (MaxCharges >= 0 && Charges > MaxCharges)
					Charges = MaxCharges;

				SetCharges(AbilityState, Charges, NewGameState);
			}
		}
	}
}

simulated function SetCharges(XComGameState_Ability Ability, int Charges, XComGameState NewGameState)
{
	local XComGameState_Item Weapon;
	local X2AbilityTemplate Template;

	Template = Ability.GetMyTemplate();
	if (Template != None && Template.bUseAmmoAsChargesForHUD && bAllowUseAmmoAsCharges)
	{
		if (Ability.SourceAmmo.ObjectID > 0)
		{
			Weapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Ability.SourceAmmo.ObjectID));
			if (Weapon != none)
			{
				Weapon = XComGameState_Item(NewGameState.CreateStateObject(Weapon.class, Weapon.ObjectID));
				Weapon.Ammo += Charges * Template.iAmmoAsChargesDivisor;
				NewGameState.AddStateObject(Weapon);
			}
		}
		else
		{
			Weapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Ability.SourceWeapon.ObjectID));
			if (Weapon != none)
			{
				Weapon = XComGameState_Item(NewGameState.CreateStateObject(Weapon.class, Weapon.ObjectID));
				Weapon.Ammo += Charges * Template.iAmmoAsChargesDivisor;
				NewGameState.AddStateObject(Weapon);
			}
		}
	}
	else
	{
		Ability = XComGameState_Ability(NewGameState.CreateStateObject(Ability.class, Ability.ObjectID));
		Ability.iCharges = Charges;
		NewGameState.AddStateObject(Ability);
	}
}


defaultproperties
{
	BonusCharges = 1
	MaxCharges = -1
	bAllowUseAmmoAsCharges = true;
}