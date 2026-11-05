extends RefCounted

const EffectExecutor = preload("res://scripts/combat/effect_executor.gd")

const PASSIVE_ONLY_EFFECTS := ["damage_bonus_percent"]


static func validate(augments: Array, consumables: Array, base_actions: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var names: Dictionary = {}
	for augment in augments:
		_validate_container(augment, "augment", names, errors)
		if not augment.has("slot") or not augment.has("archetype") or not augment.has("brand"):
			errors.append("Augment %s is missing slot, archetype, or brand metadata." % augment.get("name", "<unnamed>"))
		for ability in augment.get("abilities", []):
			_validate_ability(ability, String(augment.get("name", "<unnamed>")), errors)
		for passive in augment.get("passives", []):
			_validate_effects(passive.get("effects", []), String(augment.get("name", "<unnamed>")) + " passive", errors, true)

	for item in consumables:
		_validate_container(item, "consumable", names, errors)
		_validate_effects(item.get("effects", []), String(item.get("name", "<unnamed>")), errors)

	for action_name in base_actions:
		var action: Dictionary = base_actions[action_name]
		_validate_effects(action.get("effects", []), String(action.get("name", action_name)), errors)
	return errors


static func _validate_container(container: Dictionary, container_type: String, names: Dictionary, errors: Array[String]) -> void:
	var name := String(container.get("name", ""))
	if name.is_empty():
		errors.append("%s container is missing a name." % container_type)
	elif names.has(name):
		errors.append("Duplicate content container name: %s." % name)
	else:
		names[name] = true


static func _validate_ability(ability: Dictionary, augment_name: String, errors: Array[String]) -> void:
	if not ability.has("name") or not ability.has("cost") or not ability.has("cooldown"):
		errors.append("Ability on %s is missing name, cost, or cooldown." % augment_name)
	_validate_effects(ability.get("effects", []), String(ability.get("name", augment_name)), errors)


static func _validate_effects(effects: Array, container_name: String, errors: Array[String], allow_passive_only: bool = false) -> void:
	if effects.is_empty():
		errors.append("%s has no effects." % container_name)
		return
	for effect in effects:
		if not effect is Dictionary:
			errors.append("%s contains a non-Dictionary effect." % container_name)
			continue
		var effect_type := String(effect.get("type", ""))
		if not EffectExecutor.supports(effect_type) and not (allow_passive_only and PASSIVE_ONLY_EFFECTS.has(effect_type)):
			errors.append("%s uses unregistered effect type '%s'." % [container_name, effect_type])
		if effect_type == "apply_status":
			var operation := String(effect.get("operation", "apply"))
			if operation == "apply" and not effect.has("status"):
				errors.append("%s applies a status without naming one." % container_name)
