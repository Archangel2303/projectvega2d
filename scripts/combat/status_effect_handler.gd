extends RefCounted


func execute(context: Dictionary, effect: Dictionary) -> void:
	var game: Control = context["game"]
	var actor: Dictionary = context["actor"]
	var operation := String(effect.get("operation", "apply"))
	if operation == "remove_random_debuff":
		game._remove_one_debuff()
		return
	if operation == "remove_all_debuffs":
		while _has_debuff(actor):
			game._remove_one_debuff()
		return
	if operation == "random_debuff":
		game._apply_random_debuff()
		return

	var status := String(effect.get("status", ""))
	var duration := int(effect.get("duration", 1))
	var target_mode := String(effect.get("target", "selected"))
	if target_mode == "self":
		_apply_status(actor, status, duration)
		return

	var targets: Array = []
	if target_mode == "all":
		for enemy in game.enemies:
			targets.append(enemy)
	elif target_mode == "random_enemy":
		var living_targets: Array = []
		for enemy in game.enemies:
			if int(enemy["hp"]) > 0:
				living_targets.append(enemy)
		if not living_targets.is_empty():
			targets.append(living_targets[game.rng.randi_range(0, living_targets.size() - 1)])
	else:
		if game.selected_target >= 0 and game.selected_target < game.enemies.size():
			targets.append(game.enemies[game.selected_target])

	var status_applied := false
	for target in targets:
		if int(target["hp"]) <= 0:
			continue
		if bool(effect.get("chrome_only", false)) and not bool(target.get("chrome", false)):
			continue
		if int(effect.get("resist_chance", 0)) > 0 and game.rng.randi_range(1, 100) <= int(effect["resist_chance"]):
			continue
		_apply_status(target, status, duration)
		status_applied = true
	if status == "hacked" and status_applied:
		game._trigger_passives("first_hack")
	context["log"].call("%s applies %s." % [String(context.get("source_name", "Effect")), status.capitalize()])


func _apply_status(container: Dictionary, status: String, duration: int) -> void:
	if not container.has(status):
		push_error("StatusEffectHandler received unknown status field: %s" % status)
		return
	container[status] = maxi(int(container[status]), duration)


func _has_debuff(actor: Dictionary) -> bool:
	return int(actor.get("weak_turns", 0)) > 0 or int(actor.get("marked_turns", 0)) > 0 or float(actor.get("viral_percent", 0.0)) > 0.0
