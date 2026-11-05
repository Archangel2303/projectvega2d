extends RefCounted

const EffectExecutor = preload("res://scripts/combat/effect_executor.gd")
const EffectConditions = preload("res://scripts/combat/effect_conditions.gd")


static func trigger(game: Control, trigger_name: String) -> void:
	var executor := EffectExecutor.new()
	for slot in game.SLOT_NAMES:
		var augment: Dictionary = game.loadout.get(slot, {})
		for passive in augment.get("passives", []):
			if String(passive.get("trigger", "")) != trigger_name:
				continue
			var passive_key := "%s:%s" % [String(augment.get("name", "")), trigger_name]
			if bool(passive.get("once_per_combat", true)) and game.passive_triggers.has(passive_key):
				continue
			var context: Dictionary = game._effect_context(String(augment.get("name", "Passive")))
			if not executor.execute(passive.get("effects", []), context):
				return
			game.passive_triggers[passive_key] = true


static func damage_bonus_percent(game: Control, target_index: int) -> int:
	var bonus := 0
	var context: Dictionary = game._effect_context("Passive")
	context["target_index"] = target_index
	for slot in game.SLOT_NAMES:
		var augment: Dictionary = game.loadout.get(slot, {})
		for passive in augment.get("passives", []):
			if String(passive.get("trigger", "")) != "damage":
				continue
			for effect in passive.get("effects", []):
				if String(effect.get("type", "")) == "damage_bonus_percent" and EffectConditions.passes(context, effect.get("condition", {})):
					bonus += int(effect.get("amount", 0))
	return bonus
