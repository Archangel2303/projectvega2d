extends SceneTree

const MAIN_SCENE = preload("res://scenes/main.tscn")
const FloorData = preload("res://scripts/floor_one_data.gd")
const FloorMapGenerator = preload("res://scripts/floor_map_generator.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _test_generated_floor_maps():
		return

	var game := MAIN_SCENE.instantiate() as Control
	root.add_child(game)
	await process_frame
	if not _expect(String(game.get("state")) == "map", "A new run should begin at the generated floor map."):
		return
	var first_position: Vector2 = game.call("_map_node_position", {"row": 0, "column": 0})
	var boss_position: Vector2 = game.call("_map_node_position", {"row": 5, "column": 0})
	if not _expect(first_position.y > boss_position.y, "Floor map positions should ascend toward the boss."):
		return
	var event_label := str(game.call("_map_node_label", {"type": "event", "title": "Fractured Hallway"}))
	if not _expect(event_label.contains("?") and not event_label.contains("Fractured Hallway"), "Random encounters should be shown as ? on the map."):
		return

	var floor_map: Dictionary = game.get("floor_map")
	var start_id := String(floor_map["start_id"])
	game.call("_enter_map_node", start_id)
	if not _expect(String(game.get("state")) == "battle", "The map's start node should enter combat."):
		return
	var enemies: Array = game.get("enemies")
	if not _expect(enemies.size() == 2, "The opening map node should use its encounter template."):
		return
	if not _expect(not enemies[0]["intent"].is_empty() and not enemies[1]["intent"].is_empty(), "Opening enemies should forecast their actions."):
		return
	var first_hp := int(enemies[0]["hp"])
	game.call("_perform_action", "punch")
	enemies = game.get("enemies")
	if not _expect(int(enemies[0]["hp"]) == first_hp - 5, "Punch should deal 5 damage."):
		return
	game.call("_perform_action", "augment:Arm:0")
	enemies = game.get("enemies")
	if not _expect(int(enemies[0]["hp"]) == first_hp - 15, "Scrap Bash should deal 10 damage."):
		return
	game.call("_perform_action", "augment:Arm:1")
	var player_state: Dictionary = game.get("player")
	if not _expect(int(player_state["focus"]) == 0, "Combat actions should spend Focus."):
		return
	if not _expect(int(player_state["block"]) == 12 and int(player_state["hp"]) == 97, "Welded Guard should Block and apply its HP cost."):
		return
	var hp_before_enemy_turn := int(player_state["hp"])
	game.call("_perform_action", "end_turn")
	if not _expect(int(game.get("turn_number")) == 2, "Ending the turn should advance the round."):
		return
	if not _expect(int(player_state["block"]) < 12 or int(player_state["hp"]) < hp_before_enemy_turn, "Enemy actions should resolve at end of turn."):
		return
	game.call("_perform_action", "item")
	player_state = game.get("player")
	var remaining_items: Array = game.get("consumable_inventory")
	if not _expect(int(player_state["hp"]) == 100 and remaining_items.is_empty(), "Healing consumable should apply and be consumed."):
		return

	var node_visits := 1
	while String(game.get("state")) != "complete" and node_visits < 7:
		var current_state := String(game.get("state"))
		if current_state == "map":
			var next_id := _choose_reachable_node(game)
			if not _expect(not next_id.is_empty(), "Every non-boss path should expose a connected next node."):
				return
			game.call("_enter_map_node", next_id)
			node_visits += 1
		elif current_state == "battle":
			var current_node: Dictionary = game.get("current_node")
			var is_boss := String(current_node.get("type", "")) == "boss"
			_defeat_all_enemies(game)
			var expected_state := "boss_reward" if is_boss else "reward"
			if not _expect(String(game.get("state")) == expected_state, "Combat victory should open the correct reward container."):
				return
			var container: Dictionary = game.get("reward_container")
			var vial: Dictionary = container.get("nanite_vial", {})
			var choices: Array = vial.get("choices", [])
			if not _expect(int(container.get("nanites", 0)) > 0 and choices.size() == 3, "Reward container should include Nanites and three augment choices."):
				return
			var chosen_names: Array[String] = []
			for augment in choices:
				chosen_names.append(String(augment["name"]))
			if not _expect(chosen_names[0] != chosen_names[1] and chosen_names[1] != chosen_names[2] and chosen_names[0] != chosen_names[2], "Nanite Vial choices should be distinct."):
				return
			var nanites_before := int(player_state.get("nanites", 0))
			game.call("_select_reward_augment", 0)
			game.call("_claim_rewards")
			if is_boss:
				if not _expect(String(game.get("state")) == "complete", "Claiming the boss reward should complete the floor."):
					return
				if not _expect(int(player_state["nanites"]) > nanites_before, "Claiming the boss container should grant Nanites."):
					return
			elif not _expect(String(game.get("state")) == "map", "Claiming a regular reward should return to the floor map."):
				return
		elif current_state == "event":
			game.call("_resolve_event_choice", "salvage")
			if not _expect(String(game.get("state")) == "map", "Resolving an event should return to the map."):
				return
		elif current_state == "shop":
			game.call("_leave_shop")
			if not _expect(String(game.get("state")) == "map", "Leaving the shop should return to the map."):
				return
		elif current_state == "rest":
			game.call("_take_rest")
			if not _expect(String(game.get("state")) == "map", "Resting should return to the map before the boss node."):
				return
		else:
			if not _expect(false, "Unexpected floor traversal state: %s." % current_state):
				return

	if not _expect(String(game.get("state")) == "complete", "The generated map should lead to its boss."):
		return
	player_state["nanites"] = 40
	var inventory_before: int = game.get("consumable_inventory").size()
	game.set("current_node", {"connections": []})
	game.set("state", "shop")
	game.call("_buy_shop_item", "Nanite Injection Vial", 40)
	if not _expect(int(player_state["nanites"]) == 0 and game.get("consumable_inventory").size() == inventory_before + 1, "The trader should exchange run Nanites for a consumable."):
		return
	player_state["nanites"] = 0
	game.set("state", "event")
	game.call("_resolve_event_choice", "salvage")
	if not _expect(int(player_state["nanites"]) == 25, "The salvage event should grant run-local Nanites."):
		return
	print("Floor 1 smoke test passed: generated branching map, combat, events/shops/rest, rewards, and boss.")
	game.free()
	quit()


func _choose_reachable_node(game: Control) -> String:
	var accessible: Array = game.get("accessible_node_ids")
	var nodes: Dictionary = game.get("floor_map")["nodes"]
	var preferred_types := ["event", "combat", "elite", "shop", "rest", "boss"]
	for preferred in preferred_types:
		for node_id in accessible:
			if String(nodes[String(node_id)]["type"]) == preferred:
				return String(node_id)
	return ""


func _defeat_all_enemies(game: Control) -> void:
	var enemies: Array = game.get("enemies")
	for index in range(enemies.size()):
		var enemy: Dictionary = enemies[index]
		enemy["hp"] = 0
		enemies[index] = enemy
	game.set("enemies", enemies)
	game.call("_check_combat_state")


func _test_generated_floor_maps() -> bool:
	var rng := RandomNumberGenerator.new()
	var layout_ids: Dictionary = {}
	for seed in range(20):
		rng.seed = seed + 1
		var boss: Dictionary = FloorData.boss_pool()[seed % FloorData.boss_pool().size()]
		var generated := FloorMapGenerator.generate(rng, boss)
		layout_ids[int(generated["layout_id"])] = true
		var rows: Array = generated["rows"]
		if not _expect(rows.size() == 6, "Each generated map should contain six rows for one floor."):
			return false
		var node_types: Dictionary = {}
		for row_index in range(rows.size()):
			var row: Array = rows[row_index]
			for node in row:
				node_types[String(node["type"])] = true
				if row_index < rows.size() - 1:
					if not _expect(not node["connections"].is_empty(), "Every non-final node should connect to the next map row."):
						return false
					for next_id in node["connections"]:
						var next_node: Dictionary = generated["nodes"][String(next_id)]
						if not _expect(int(next_node["row"]) == row_index + 1, "Map connections should only advance one row at a time."):
							return false
		if not _expect(rows[4][0]["type"] == "rest" and rows[5][0]["type"] == "boss", "Every floor map should end with a guaranteed rest and boss."):
			return false
		for row_index in range(rows.size() - 1):
			for node in rows[row_index]:
				for next_id in node["connections"]:
					var next_node: Dictionary = generated["nodes"][String(next_id)]
					if not _expect(not (String(node["type"]) == "rest" and String(next_node["type"]) == "rest"), "A floor map must never place two rest sites back to back."):
						return false
		for required_type in ["combat", "elite", "event", "shop", "rest", "boss"]:
			if not _expect(node_types.has(required_type), "Generated floor maps should include %s nodes." % required_type):
				return false
		var reachable: Dictionary = {}
		var frontier: Array[String] = [String(generated["start_id"])]
		while not frontier.is_empty():
			var node_id: String = frontier.pop_front()
			if reachable.has(node_id):
				continue
			reachable[node_id] = true
			var node: Dictionary = generated["nodes"][node_id]
			for next_id in node["connections"]:
				frontier.append(String(next_id))
		if not _expect(reachable.size() == generated["nodes"].size(), "Every generated node should be reachable from the floor start."):
			return false
	if not _expect(layout_ids.size() > 1, "The generator should select among multiple predefined path layouts."):
		return false
	return true


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
		return false
	return true
