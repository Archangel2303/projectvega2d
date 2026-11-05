extends RefCounted

const DamageHandler = preload("res://scripts/combat/damage_effect_handler.gd")
const StatHandler = preload("res://scripts/combat/stat_effect_handler.gd")
const StatusHandler = preload("res://scripts/combat/status_effect_handler.gd")
const UtilityHandler = preload("res://scripts/combat/utility_effect_handler.gd")
const EffectConditions = preload("res://scripts/combat/effect_conditions.gd")

var handlers: Dictionary = {}


func _init() -> void:
	var damage := DamageHandler.new()
	var stats := StatHandler.new()
	var statuses := StatusHandler.new()
	var utility := UtilityHandler.new()
	handlers = {
		"damage": damage,
		"damage_bonus_percent": stats,
		"block": stats,
		"heal": stats,
		"heal_target": stats,
		"focus": stats,
		"damage_buff": stats,
		"self_damage": stats,
		"corruption": stats,
		"turn_end_damage": stats,
		"apply_status": statuses,
		"reduce_all_cooldowns": utility,
		"reset_all_cooldowns": utility,
		"deploy_drone": utility,
		"refresh_used_consumables": utility,
	}


func execute(effects: Array, context: Dictionary) -> bool:
	for effect in effects:
		if not effect is Dictionary:
			push_error("Combat ability effect entries must be Dictionaries.")
			return false
		var condition: Dictionary = effect.get("condition", {})
		if not EffectConditions.passes(context, condition):
			continue
		var effect_type := String(effect.get("type", ""))
		if not handlers.has(effect_type):
			push_error("No effect handler registered for type: %s" % effect_type)
			return false
		var handler: Object = handlers[effect_type]
		handler.call("execute", context, effect)
	return true


static func supports(effect_type: String) -> bool:
	return [
		"damage", "block", "heal", "heal_target", "focus", "damage_buff", "self_damage",
		"corruption", "turn_end_damage", "apply_status", "reduce_all_cooldowns",
		"reset_all_cooldowns", "deploy_drone", "refresh_used_consumables",
	].has(effect_type)
