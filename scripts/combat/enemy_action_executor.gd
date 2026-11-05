extends RefCounted


static func execute(game: Control, index: int) -> void:
	if index < 0 or index >= game.enemies.size():
		push_error("Enemy action index is out of range: %d" % index)
		return
	var enemy: Dictionary = game.enemies[index]
	var intent: Dictionary = enemy["intent"]
	var kind := String(intent.get("kind", "attack"))
	var label := String(intent.get("label", "Attack"))
	match kind:
		"attack", "multi", "steal":
			var hits := int(intent.get("hits", 1))
			var damage := int(intent.get("damage", int(enemy["damage"])))
			if kind == "steal":
				var stolen := mini(int(game.player["block"]), int(intent.get("steal", 0)))
				game.player["block"] = int(game.player["block"]) - stolen
				damage += stolen
			for hit in range(hits):
				var hit_damage := damage
				if int(game.player["marked_turns"]) > 0:
					hit_damage = roundi(float(hit_damage) * 1.3)
				if enemy["type"] == "boss_concierge" and label == "Room Charge":
					hit_damage += maxi(1, roundi(float(int(game.player["hp"])) * 0.02))
				game._player_take_damage(hit_damage)
			game._log("%s uses %s (%d × %d)." % [enemy["name"], label, hits, damage])
		"aoe":
			var aoe_damage := int(intent.get("damage", 10))
			if int(game.player["marked_turns"]) > 0:
				aoe_damage = roundi(float(aoe_damage) * 1.3)
			game._player_take_damage(aoe_damage)
			game._log("%s uses %s for %d." % [enemy["name"], label, aoe_damage])
		"block":
			enemy["block"] = int(enemy["block"]) + int(intent.get("power", 10))
			game._log("%s uses %s and gains %d Block." % [enemy["name"], label, intent.get("power", 10)])
		"heal":
			var target_index := int(intent.get("target", -1))
			if target_index >= 0 and target_index < game.enemies.size() and int(game.enemies[target_index]["hp"]) > 0:
				var healed := mini(int(intent.get("power", 8)), int(game.enemies[target_index]["max_hp"]) - int(game.enemies[target_index]["hp"]))
				game.enemies[target_index]["hp"] += healed
				game._log("%s restores %d HP to %s." % [enemy["name"], healed, game.enemies[target_index]["name"]])
			else:
				game._log("%s cannot heal a defeated target." % enemy["name"])
		"mark":
			if int(intent.get("damage", 0)) > 0:
				game._player_take_damage(int(intent["damage"]))
			game.player["marked_turns"] = 2
			game._log("%s applies Gospel Mark; you take more damage and deal more." % enemy["name"])
		"weaken":
			game._player_take_damage(int(intent.get("damage", 0)))
			game.player["weak_turns"] = 2
			game._log("%s applies Fractured; your attacks are weakened." % enemy["name"])
		"summon":
			game._resolve_summon(enemy)
		"absorb":
			game._resolve_absorb_growth(index)
		_:
			push_error("Unsupported enemy action kind: %s" % kind)
	enemy = game.enemies[index]
	enemy["intent"] = {}
	game.enemies[index] = enemy
