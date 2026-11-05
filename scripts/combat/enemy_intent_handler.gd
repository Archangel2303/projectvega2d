extends RefCounted


static func assign(game: Control) -> void:
	for index in range(game.enemies.size()):
		var enemy: Dictionary = game.enemies[index]
		if int(enemy["hp"]) <= 0:
			continue
		var enemy_type := String(enemy["type"])
		var intent: Dictionary = {}
		match enemy_type:
			"bellhop":
				intent = {"kind": "attack", "label": "Double Strike", "damage": 8, "hits": 2} if game.turn_number % 3 == 0 else {"kind": "attack", "label": "Single Strike", "damage": int(enemy["damage"]), "hits": 1}
				if int(enemy["hp"]) * 2 < int(enemy["max_hp"]) and game.turn_number % 4 == 0:
					intent = {"kind": "block", "label": "Guard", "power": 8}
			"attendant":
				var hurt_ally := _lowest_hp_ally(game, index)
				if hurt_ally >= 0 and int(game.enemies[hurt_ally]["hp"]) < int(game.enemies[hurt_ally]["max_hp"]) - 4:
					intent = {"kind": "heal", "label": "Tend the Wounded", "target": hurt_ally, "power": 8}
				elif game.turn_number % 3 == 0:
					intent = {"kind": "mark", "label": "Gospel Mark", "damage": 4}
				else:
					intent = {"kind": "attack", "label": "Mark-Strike", "damage": int(enemy["damage"]), "hits": 1}
			"mascot":
				intent = {"kind": "block", "label": "Brace", "power": 12} if int(enemy["hp"]) * 2 < int(enemy["max_hp"]) and game.turn_number % 2 == 0 else {"kind": "attack", "label": "Haymaker", "damage": int(enemy["damage"]), "hits": 1}
			"drone":
				intent = {"kind": "weaken", "label": "Dissonant Chant", "damage": 4} if game.turn_number % 2 == 1 else {"kind": "attack", "label": "Screech", "damage": int(enemy["damage"]), "hits": 1}
			"staff":
				intent = {"kind": "mark", "label": "Echoed Trauma", "damage": 7} if game.turn_number % 2 == 1 else {"kind": "attack", "label": "Staff Strike", "damage": int(enemy["damage"]), "hits": 1}
			"butler":
				match (game.turn_number - 1) % 4:
					0: intent = {"kind": "attack", "label": "Rustbrand Slash", "damage": 16, "hits": 1}
					1: intent = {"kind": "block", "label": "Metallic Poise", "power": 18}
					2: intent = {"kind": "attack", "label": "Tray Slam", "damage": 7, "hits": 1}
					_: intent = {"kind": "block", "label": "Serve & Guard", "power": 12}
				if int(enemy["hp"]) * 2 < int(enemy["max_hp"]) and game.turn_number % 3 == 0:
					intent = {"kind": "block", "label": "Crown's Favor", "power": 18}
			"node":
				intent = {"kind": "block", "label": "Echo Screen", "power": 10} if game.turn_number % 3 == 0 else {"kind": "attack", "label": "Piercing Note", "damage": 6, "hits": 1}
			"mycelial_node":
				intent = {"kind": "attack", "label": "Mycelial Strike", "damage": 6, "hits": 1}
			"acolyte":
				intent = {"kind": "attack", "label": "Servile Strike", "damage": 5, "hits": 1}
			"boss_matron":
				intent = _matron_intent(game, enemy)
			"boss_choir":
				intent = {"kind": "aoe", "label": "Cacophony", "damage": 16} if game.turn_number % 4 == 0 else {"kind": "aoe", "label": "Parasite Wave", "damage": 10}
			"boss_concierge":
				intent = _concierge_intent(game, enemy)
			"boss_challenger":
				intent = _challenger_intent(game, enemy)
			"boss_mycelial":
				intent = _mycelial_intent(game, enemy)
		enemy["intent"] = intent
		game.enemies[index] = enemy


static func _matron_intent(game: Control, enemy: Dictionary) -> Dictionary:
	if int(enemy["hp"]) <= int(enemy["max_hp"]) * 0.2:
		return {"kind": "multi", "label": "Enraged Coronation Lash", "damage": 8, "hits": 4}
	match (game.turn_number - 1) % 4:
		0: return {"kind": "mark", "label": "Royal Decree", "damage": 0}
		1: return {"kind": "block", "label": "Royal Aegis", "power": 18}
		2: return {"kind": "multi", "label": "Coronation Lash", "damage": 7, "hits": 3}
		_:
			if int(enemy["hp"]) <= int(enemy["max_hp"]) * 0.7 and game.matron_summons < 2 and game._count_alive_type("acolyte") == 0:
				return {"kind": "summon", "label": "Summon Acolyte"}
			return {"kind": "multi", "label": "Coronation Lash", "damage": 7, "hits": 3}


static func _concierge_intent(game: Control, enemy: Dictionary) -> Dictionary:
	if int(enemy["hp"]) * 2 <= int(enemy["max_hp"]) and not game.concierge_respawned and game._count_alive_type("bellhop") == 0:
		return {"kind": "summon", "label": "Bellhop Summon"}
	match (game.turn_number - 1) % 3:
		0: return {"kind": "block", "label": "Front-Desk Bulwark", "power": 12}
		1: return {"kind": "steal", "label": "Check-In, Please", "damage": 10, "steal": 6}
		_: return {"kind": "attack", "label": "Room Charge", "damage": 12, "hits": 1}


static func _challenger_intent(game: Control, enemy: Dictionary) -> Dictionary:
	if int(enemy["hp"]) <= int(enemy["max_hp"]) * 0.2:
		return {"kind": "attack", "label": "Haymaker", "damage": 20, "hits": 1}
	match (game.turn_number - 1) % 3:
		0: return {"kind": "multi", "label": "Spasm Flurry", "damage": 4, "hits": 4}
		1: return {"kind": "block", "label": "Spasm Guard", "power": 10}
		_: return {"kind": "attack", "label": "Haymaker", "damage": 14, "hits": 1}


static func _mycelial_intent(game: Control, enemy: Dictionary) -> Dictionary:
	if game.turn_number == 2:
		return {"kind": "block", "label": "Fungal Carapace", "power": 16}
	if game.turn_number % 2 == 0 and game._count_alive_type("mycelial_node") < 2:
		return {"kind": "summon", "label": "Spore Bloom"}
	if game._count_alive_type("mycelial_node") > 0 and (int(enemy["hp"]) <= int(enemy["max_hp"]) * 0.7 or game._count_alive_type("mycelial_node") >= 2):
		return {"kind": "absorb", "label": "Absorb Growth"}
	return {"kind": "attack", "label": "Infectious Slam", "damage": 11, "hits": 1}


static func _lowest_hp_ally(game: Control, exclude_index: int) -> int:
	var lowest := -1
	for index in range(game.enemies.size()):
		if index == exclude_index or int(game.enemies[index]["hp"]) <= 0:
			continue
		if lowest < 0 or float(game.enemies[index]["hp"]) / float(game.enemies[index]["max_hp"]) < float(game.enemies[lowest]["hp"]) / float(game.enemies[lowest]["max_hp"]):
			lowest = index
	return lowest
