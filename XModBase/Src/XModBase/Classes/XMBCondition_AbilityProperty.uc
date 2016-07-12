//---------------------------------------------------------------------------------------
//  FILE:    XMBCondition_AbilityProperty.uc
//  AUTHOR:  xylthixlm
//
//
//  USAGE
//
//  EXAMPLES
//
//  The following examples in Examples.uc use this class:
//
//	ZeroIn
//
//  INSTALLATION
//
//  Install the XModBase core as described in readme.txt. Copy this file, and any files 
//  listed as dependencies, into your mod's Classes/ folder. You may edit this file.
//
//  DEPENDENCIES
//
//  None.
//---------------------------------------------------------------------------------------
class XMBCondition_AbilityProperty extends X2Condition;

var bool bRequireActivated;
var bool bExcludeActivated;
var bool bRequirePassive;
var bool bExcludePassive;
var bool bRequireMelee;
var bool bExcludeMelee;

var array<EAbilityHostility> IncludeHostility;
var array<EAbilityHostility> ExcludeHostility;

event name CallAbilityMeetsCondition(XComGameState_Ability kAbility, XComGameState_BaseObject kTarget)
{
	local int Priority;

	if (bRequireActivated && !kAbility.IsAbilityInputTriggered())
		return 'AA_InvalidAbility';  // NOTE: Nonstandard AA code
	if (bExcludeActivated && kAbility.IsAbilityInputTriggered())
		return 'AA_InvalidAbility';  // NOTE: Nonstandard AA code

	if (bRequirePassive && !kAbility.IsAbilityTriggeredOnUnitPostBeginTacticalPlay(Priority))
		return 'AA_InvalidAbility';  // NOTE: Nonstandard AA code
	if (bExcludePassive && kAbility.IsAbilityTriggeredOnUnitPostBeginTacticalPlay(Priority))
		return 'AA_InvalidAbility';  // NOTE: Nonstandard AA code

	if (bRequireMelee && !kAbility.IsMeleeAbility())
		return 'AA_InvalidAbility';  // NOTE: Nonstandard AA code
	if (bExcludeMelee && kAbility.IsMeleeAbility())
		return 'AA_InvalidAbility';  // NOTE: Nonstandard AA code

	if (IncludeHostility.Length > 0 && IncludeHostility.Find(kAbility.GetMyTemplate().Hostility) == INDEX_NONE)
		return 'AA_InvalidAbility';  // NOTE: Nonstandard AA code
	if (ExcludeHostility.Length > 0 && ExcludeHostility.Find(kAbility.GetMyTemplate().Hostility) != INDEX_NONE)
		return 'AA_InvalidAbility';  // NOTE: Nonstandard AA code

	return 'AA_Success';
}