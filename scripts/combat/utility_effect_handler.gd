extends RefCounted


func execute(context: Dictionary, effect: Dictionary) -> void:
	var game: Control = context["game"]
	var operation := String(effect.get("operation", effect.get("type", "")))
	match operation:
		"reduce_all_cooldowns":
			for key in game.cooldowns.keys():
				game.cooldowns[key] = maxi(0, int(game.cooldowns[key]) - int(effect.get("amount", 1)))
		"reset_all_cooldowns":
			game.cooldowns.clear()
		"deploy_drone":
			game.drone_turns = int(effect.get("duration", 3))
			game.drone_damage = int(effect.get("damage", 8))
		"refresh_used_consumables":
			if game.singularity_used:
				context["log"].call("Alchemical Singularity has already refreshed this combat.")
				return
			for item in game.used_consumables:
				game.consumable_inventory.append(item.duplicate(true))
			game.singularity_used = true
		_:
			push_error("UtilityEffectHandler received unsupported operation: %s" % operation)
			return
	context["log"].call("%s resolves %s." % [
		String(context.get("source_name", "Effect")),
		operation.replace("_", " "),
	])
