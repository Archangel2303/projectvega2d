extends RefCounted


static func passes(context: Dictionary, condition: Dictionary) -> bool:
	var game: Control = context["game"]
	var actor: Dictionary = context["actor"]
	var enemies: Array = context["targets"]
	var target_index := int(context.get("target_index", game.selected_target))
	var target: Dictionary = {}
	if target_index >= 0 and target_index < enemies.size():
		target = enemies[target_index]

	if condition.has("actor_hp_below"):
		if int(actor["hp"]) * 100 >= int(actor["max_hp"]) * int(condition["actor_hp_below"]):
			return false
	if condition.has("actor_hp_at_least"):
		if int(actor["hp"]) * 100 < int(actor["max_hp"]) * int(condition["actor_hp_at_least"]):
			return false
	if condition.has("target_hp_below"):
		var target_hp := int(target.get("hp", 0))
		var target_max_hp := int(target.get("max_hp", 1))
		if bool(condition.get("before_action", false)):
			target_hp = int(context.get("target_hp_before", target_hp))
			target_max_hp = int(context.get("target_max_hp_before", target_max_hp))
		if target.is_empty() or target_hp * 100 >= target_max_hp * int(condition["target_hp_below"]):
			return false
	if condition.has("target_status"):
		if target.is_empty() or int(target.get(String(condition["target_status"]), 0)) <= 0:
			return false
	if condition.has("target_status_absent"):
		if target.is_empty() or int(target.get(String(condition["target_status_absent"]), 0)) > 0:
			return false
	if condition.has("enemy_count_equals"):
		if _living_enemy_count(enemies) != int(condition["enemy_count_equals"]):
			return false
	if condition.has("enemy_count_at_least"):
		if _living_enemy_count(enemies) < int(condition["enemy_count_at_least"]):
			return false
	if condition.has("target_chrome"):
		if target.is_empty() or not bool(target.get("chrome", false)):
			return false
	return true


static func _living_enemy_count(enemies: Array) -> int:
	var count := 0
	for enemy in enemies:
		if int(enemy["hp"]) > 0:
			count += 1
	return count
