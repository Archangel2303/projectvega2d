extends RefCounted

const EffectConditions = preload("res://scripts/combat/effect_conditions.gd")


func execute(context: Dictionary, effect: Dictionary) -> void:
	var game: Control = context["game"]
	var actor: Dictionary = context["actor"]
	var kind := String(effect.get("type", ""))
	var amount := int(effect.get("amount", 0))
	match kind:
		"block":
			var total := amount
			if int(effect.get("bonus_if_high_hp", 0)) > 0 and EffectConditions.passes(context, {"actor_hp_at_least": 75}):
				total += int(effect["bonus_if_high_hp"])
			if int(effect.get("bonus_if_hacked", 0)) > 0 and _has_hacked_enemy(game.enemies):
				total += int(effect["bonus_if_hacked"])
			if int(effect.get("bonus_if_already_blocked", 0)) > 0 and int(actor["block"]) > 0:
				total += int(effect["bonus_if_already_blocked"])
			if int(effect.get("block_per_chrome_augment", 0)) > 0:
				total += int(effect["block_per_chrome_augment"]) * game._count_chrome_augments()
			actor["block"] = int(actor["block"]) + total
			context["log"].call("%s grants %d Block." % [String(context.get("source_name", "Effect")), total])
		"heal":
			var heal_amount := amount
			match String(effect.get("mode", "flat")):
				"max_hp_percent":
					heal_amount = roundi(float(actor["max_hp"]) * float(amount) / 100.0)
				"missing_hp_percent":
					heal_amount = roundi(float(int(actor["max_hp"]) - int(actor["hp"])) * float(amount) / 100.0)
			context["heal"].call(heal_amount)
		"heal_target":
			var target_index := int(effect.get("target_index", context.get("target_index", game.selected_target)))
			if target_index < 0 or target_index >= game.enemies.size():
				push_error("heal_target effect has an invalid target index: %d" % target_index)
				return
			var target: Dictionary = game.enemies[target_index]
			if int(target["hp"]) <= 0:
				context["log"].call("%s cannot heal a defeated target." % String(context.get("source_name", "Effect")))
				return
			var hp_before := int(target["hp"])
			target["hp"] = mini(int(target["max_hp"]), int(target["hp"]) + amount)
			game.enemies[target_index] = target
			context["log"].call("%s restores %d HP to %s." % [
				String(context.get("source_name", "Effect")),
				int(target["hp"]) - hp_before,
				target["name"],
			])
		"focus":
			if int(effect.get("duration", 0)) > 1 and String(effect.get("timing", "immediate")) == "immediate":
				context["gain_focus"].call(amount, "immediate")
				context["gain_focus"].call(amount, "next_turn")
			else:
				context["gain_focus"].call(amount, String(effect.get("timing", "immediate")))
		"damage_buff":
			actor["damage_buff"] = amount
			actor["damage_buff_turns"] = int(effect.get("duration", 1))
			context["log"].call("%s grants +%d%% damage for %d turns." % [
				String(context.get("source_name", "Effect")),
				amount,
				actor["damage_buff_turns"],
			])
		"self_damage":
			context["take_damage"].call(amount, true)
			context["log"].call("%s costs %d HP." % [String(context.get("source_name", "Effect")), amount])
		"corruption":
			actor["corruption"] = int(actor["corruption"]) + amount
			context["log"].call("Corruption rises to %d." % actor["corruption"])
		"turn_end_damage":
			actor["turn_end_damage"] = int(actor["turn_end_damage"]) + amount
			context["log"].call("%s costs %d HP at turn end." % [String(context.get("source_name", "Effect")), amount])
		"damage_bonus_percent":
			return
		_:
			push_error("StatEffectHandler received unsupported effect type: %s" % kind)


func _has_hacked_enemy(enemies: Array) -> bool:
	for enemy in enemies:
		if int(enemy["hp"]) > 0 and int(enemy.get("hacked", 0)) > 0:
			return true
	return false
