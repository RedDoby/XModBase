class XMBAbilityTrigger_EventListener extends X2AbilityTrigger_EventListener;

////////////////////////
// Trigger properties //
////////////////////////

var bool bSelfTarget;

//////////////////////////
// Condition properties //
//////////////////////////

var array<X2Condition> AbilityTargetConditions;		// Conditions on the target of the ability being checked.
var array<X2Condition> AbilityShooterConditions;	// Conditions on the shooter of the ability being checked.

simulated function RegisterListener(XComGameState_Ability AbilityState, Object FilterObject)
{
	local object TargetObj;
	local XMBGameState_EventTarget Target;
	local XComGameState NewGameState;
	local XComGameState_BaseObject Parent;

	NewGameState = AbilityState.GetParentGameState();

	Parent = XComGameState_BaseObject(FilterObject);
	if (Parent == none)
		Parent = `XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData');

	// Because our listener function will trigger every XMBAbilityTrigger_EventListener on the
	// unit with a given event, we need to make sure that the event manager only calls it once
	// per unit for an event even if there are several abilities with the same trigger. We
	// could put it on the unit directly, but units have a lot of listeners we might clobber.
	// Instead, create a dummy state object and attach the event listener to it. We make the
	// dummy object a component of the unit to ensure that we can find it easily when 
	// registering more events.
	Target = XMBGameState_EventTarget(Parent.FindComponentObject(class'XMBGameState_EventTarget', false));
	if (Target == none)
	{
		Target = XMBGameState_EventTarget(NewGameState.CreateStateObject(class'XMBGameState_EventTarget'));
		Parent = XComGameState_Unit(NewGameState.CreateStateObject(Parent.class, Parent.ObjectID));

		Parent.AddComponentObject(Target);

		NewGameState.AddStateObject(Parent);
		NewGameState.AddStateObject(Target);
	}
	else
	{
		Target = XMBGameState_EventTarget(NewGameState.CreateStateObject(Target.class, Target.ObjectID));

		NewGameState.AddStateObject(Target);
	}

	Target.TriggeredAbilities.AddItem(AbilityState.GetReference());

	TargetObj = Target;

	`XEVENTMGR.RegisterForEvent(TargetObj, ListenerData.EventID, class'XMBGameState_EventTarget'.static.OnEvent, ListenerData.Deferral, ListenerData.Priority, FilterObject);
}

function name ValidateAttack(XComGameState_Ability SourceAbilityState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState)
{
	local X2Condition kCondition;
	local XComGameState_Item SourceWeapon;
	local StateObjectReference ItemRef;
	local name AvailableCode;
		
	foreach AbilityTargetConditions(kCondition)
	{
		if (kCondition.IsA('XMBCondition_MatchingWeapon'))
		{
			SourceWeapon = AbilityState.GetSourceWeapon();
			if (SourceWeapon == none)
				return 'AA_UnknownError';

			ItemRef = SourceAbilityState.SourceWeapon;
			if (SourceWeapon.ObjectID != ItemRef.ObjectID && SourceWeapon.LoadedAmmo.ObjectID != ItemRef.ObjectID)
				return 'AA_UnknownError';

			continue;
		}

		AvailableCode = kCondition.AbilityMeetsCondition(AbilityState, Target);
		if (AvailableCode != 'AA_Success')
			return AvailableCode;

		AvailableCode = kCondition.MeetsCondition(Target);
		if (AvailableCode != 'AA_Success')
			return AvailableCode;
		
		AvailableCode = kCondition.MeetsConditionWithSource(Target, Attacker);
		if (AvailableCode != 'AA_Success')
			return AvailableCode;
	}

	foreach AbilityShooterConditions(kCondition)
	{
		AvailableCode = kCondition.MeetsCondition(Attacker);
		if (AvailableCode != 'AA_Success')
			return AvailableCode;
	}

	return 'AA_Success';
}
