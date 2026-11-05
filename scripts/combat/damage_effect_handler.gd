extends RefCounted


func execute(context: Dictionary, effect: Dictionary) -> void:
	var game: Control = context["game"]
	var callback: Callable = context["damage_target"]
	var amount := int(effect.get("amount", 0))
	var multiplier_if: Dictionary = effect.get("multiplier_if", {})
	if not multiplier_if.is_empty() and EffectConditions.passes(context, multiplier_if.get("condition", {})):
		amount *= int(multiplier_if.get("multiplier", 1))
	var status_bonus: Dictionary = effect.get("bonus_if_target_status", {})
	var target_mode := String(effect.get("target", "selected"))
	var pierce_percent := int(effect.get("block_pierce_percent", 0))
	if target_mode == "all":
		for index in range(game.enemies.size()):
			if int(game.enemies[index]["hp"]) > 0:
				callback.call(amount + _status_bonus(game.enemies[index], status_bonus), pierce_percent, index)
	else:
		var target_index := int(game.get("selected_target"))
		if target_index >= 0 and target_index < game.enemies.size():
			callback.call(amount + _status_bonus(game.enemies[target_index], status_bonus), pierce_percent, target_index)


func _status_bonus(target: Dictionary, bonus: Dictionary) -> int:
	if bonus.is_empty():
		return 0
	var status := String(bonus.get("status", ""))
	if status.is_empty() or int(target.get(status, 0)) <= 0:
		return 0
	return int(bonus.get("amount", 0))


const EffectConditions = preload("res://scripts/combat/effect_conditions.gd")
