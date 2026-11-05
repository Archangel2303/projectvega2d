extends Control

const FloorData = preload("res://scripts/floor_one_data.gd")
const FloorMapGenerator = preload("res://scripts/floor_map_generator.gd")
const CombatActionHandler = preload("res://scripts/combat/combat_action_handler.gd")
const ConsumableHandler = preload("res://scripts/combat/consumable_handler.gd")
const PassiveHandler = preload("res://scripts/combat/passive_handler.gd")
const EnemyIntentHandler = preload("res://scripts/combat/enemy_intent_handler.gd")
const EnemyActionExecutor = preload("res://scripts/combat/enemy_action_executor.gd")
const ContentValidator = preload("res://scripts/combat/content_validator.gd")

const BG := Color("#10151d")
const PANEL := Color("#1a222d")
const PANEL_ALT := Color("#202b38")
const BORDER := Color("#3d5361")
const TEXT := Color("#edf0dc")
const MUTED := Color("#9ba9a5")
const CYAN := Color("#65d7c0")
const GOLD := Color("#f0c978")
const RED := Color("#e87b6c")
const GREEN := Color("#89d49e")
const SLOT_NAMES := ["Head", "Torso", "Arm", "Legs"]

var rng := RandomNumberGenerator.new()
var state := "battle"
var player: Dictionary = {}
var loadout: Dictionary = {}
var cooldowns: Dictionary = {}
var passive_triggers: Dictionary = {}
var inventory_container: Dictionary = {}
var consumable_inventory: Array = []
var augment_inventory: Array = []
var echo_inventory: Array = []
var used_consumables: Array = []
var enemies: Array = []
var floor_map: Dictionary = {}
var current_node: Dictionary = {}
var current_map_node_id := ""
var accessible_node_ids: Array[String] = []
var visited_node_ids: Array[String] = []
var turn_number := 1
var selected_target := 0
var item_used_this_turn := false
var reward_container: Dictionary = {}
var selected_reward_augment := -1
var battle_menu := "Abilities"
var previous_state := "map"
var combat_log: Array[String] = []
var run_points := 0
var run_finished := false
var current_boss: Dictionary = {}
var concierge_respawned := false
var matron_summons := 0
var metal_level := 1
var metal_xp := 0
var run_summary := ""
var pending_focus := 0
var drone_turns := 0
var drone_damage := 0
var singularity_used := false


func _ready() -> void:
	var content_errors := ContentValidator.validate(FloorData.augments(), FloorData.consumables(), FloorData.base_actions())
	if not content_errors.is_empty():
		for message in content_errors:
			push_error(message)
		return
	rng.randomize()
	_load_profile()
	_start_new_run()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	for x in range(0, int(size.x), 32):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color("#1a2229"), 1.0)
	for y in range(0, int(size.y), 32):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color("#1a2229"), 1.0)
	for x in range(16, 1280, 64):
		for y in range(16, 720, 64):
			draw_rect(Rect2(Vector2(x, y), Vector2(2, 2)), Color("#34414a"))

	if state == "map":
		_draw_map_connections()
	if state != "battle":
		return

	_draw_player_sprite()
	for index in range(enemies.size()):
		if int(enemies[index]["hp"]) > 0:
			_draw_enemy_sprite(index)


func _draw_player_sprite() -> void:
	var x := 113.0
	var y := 213.0
	var coat := Color("#8a634a")
	var skin := Color("#e5b58b")
	var steel := Color("#8aa7ae")
	draw_rect(Rect2(Vector2(x + 16, y), Vector2(22, 18)), skin)
	draw_rect(Rect2(Vector2(x + 12, y - 5), Vector2(31, 8)), Color("#d2b37d"))
	draw_rect(Rect2(Vector2(x + 11, y + 18), Vector2(32, 34)), coat)
	draw_rect(Rect2(Vector2(x + 5, y + 22), Vector2(9, 27)), steel)
	draw_rect(Rect2(Vector2(x + 40, y + 21), Vector2(9, 28)), coat)
	draw_rect(Rect2(Vector2(x + 14, y + 50), Vector2(12, 24)), Color("#384754"))
	draw_rect(Rect2(Vector2(x + 29, y + 50), Vector2(12, 24)), Color("#384754"))
	draw_rect(Rect2(Vector2(x + 3, y + 43), Vector2(13, 9)), Color("#cca55e"))
	draw_rect(Rect2(Vector2(x + 40, y + 42), Vector2(16, 5)), steel)
	draw_rect(Rect2(Vector2(x + 55, y + 40), Vector2(25, 4)), Color("#536876"))


func _draw_enemy_sprite(index: int) -> void:
	var count := enemies.size()
	var card_width := minf(278.0, 930.0 / maxf(1.0, float(count)))
	var gap := 14.0
	var total_width := float(count) * card_width + float(count - 1) * gap
	var start_x := 288.0 + (950.0 - total_width) / 2.0
	var center_x := start_x + float(index) * (card_width + gap) + card_width / 2.0
	var base_y := 266.0
	var accent: Color = enemies[index]["color"]
	var width := 40.0 if String(enemies[index]["type"]).begins_with("boss_") else 30.0
	var height := 55.0 if String(enemies[index]["type"]).begins_with("boss_") else 42.0
	draw_rect(Rect2(Vector2(center_x - width / 2.0, base_y - height), Vector2(width, height)), accent)
	draw_rect(Rect2(Vector2(center_x - width / 2.0 - 8, base_y - height + 12), Vector2(8, 24)), accent.darkened(0.18))
	draw_rect(Rect2(Vector2(center_x + width / 2.0, base_y - height + 12), Vector2(8, 24)), accent.darkened(0.18))
	draw_rect(Rect2(Vector2(center_x - width / 2.0 - 5, base_y), Vector2(12, 20)), accent.darkened(0.28))
	draw_rect(Rect2(Vector2(center_x + width / 2.0 - 7, base_y), Vector2(12, 20)), accent.darkened(0.28))
	draw_rect(Rect2(Vector2(center_x - 8, base_y - height + 15), Vector2(5, 5)), Color("#111820"))
	draw_rect(Rect2(Vector2(center_x + 4, base_y - height + 15), Vector2(5, 5)), Color("#111820"))
	draw_rect(Rect2(Vector2(center_x - 5, base_y - 9), Vector2(10, 4)), Color("#10151d"))


func _load_profile() -> void:
	var profile := ConfigFile.new()
	var error := profile.load("user://profile.cfg")
	if error == OK:
		metal_level = int(profile.get_value("meta", "metal_level", 1))
		metal_xp = int(profile.get_value("meta", "metal_xp", 0))


func _save_profile() -> void:
	var profile := ConfigFile.new()
	profile.set_value("meta", "metal_level", metal_level)
	profile.set_value("meta", "metal_xp", metal_xp)
	var error := profile.save("user://profile.cfg")
	if error != OK:
		push_error("Could not save Metal Level profile: %s" % error_string(error))


func _start_new_run() -> void:
	state = "map"
	run_finished = false
	run_points = 0
	reward_container.clear()
	selected_reward_augment = -1
	floor_map.clear()
	current_node.clear()
	current_map_node_id = ""
	accessible_node_ids.clear()
	visited_node_ids.clear()
	augment_inventory.clear()
	echo_inventory.clear()
	turn_number = 1
	pending_focus = 0
	drone_turns = 0
	drone_damage = 0
	singularity_used = false
	used_consumables.clear()
	player = {
		"hp": 100,
		"max_hp": 100,
		"base_max_hp": 100,
		"block": 0,
		"focus": 3,
		"focus_cap": 3,
		"damage_buff": 0,
		"damage_buff_turns": 0,
		"weak_turns": 0,
		"marked_turns": 0,
		"viral_percent": 0.0,
		"turn_end_damage": 0,
		"corruption": 0,
		"nanites": 0,
	}
	loadout = {"Head": {}, "Torso": {}, "Arm": {}, "Legs": {}}
	_carry_augment(FloorData.augments()[0])
	cooldowns.clear()
	used_consumables.clear()
	singularity_used = false
	consumable_inventory = [FloorData.consumables()[0].duplicate(true)]
	inventory_container = {
		"augments": augment_inventory,
		"consumables": consumable_inventory,
		"echoes": echo_inventory,
	}
	player["inventory"] = inventory_container
	combat_log.clear()
	current_boss = FloorData.weighted_boss(rng)
	floor_map = FloorMapGenerator.generate(rng, current_boss)
	accessible_node_ids = [String(floor_map["start_id"])]
	concierge_respawned = false
	matron_summons = 0
	run_summary = ""
	_refresh_ui()


func _carry_augment(augment: Dictionary, store_replaced: bool = false) -> void:
	var slot := String(augment["slot"])
	var previous: Dictionary = loadout.get(slot, {})
	if not previous.is_empty():
		if store_replaced:
			augment_inventory.append(previous.duplicate(true))
	loadout[slot] = augment.duplicate(true)
	_recalculate_max_hp()


func _equipped_softcap() -> int:
	var total := 0
	for slot in SLOT_NAMES:
		var augment: Dictionary = loadout.get(slot, {})
		total += int(augment.get("softcap", 0))
	return total


func _recalculate_max_hp() -> void:
	var max_hp_bonus := 0
	for slot in SLOT_NAMES:
		var augment: Dictionary = loadout.get(slot, {})
		max_hp_bonus += int(augment.get("max_hp_bonus", 0))
	var unsoftened_max_hp := int(player.get("base_max_hp", 100)) + max_hp_bonus
	var hp_loss := roundi(float(unsoftened_max_hp) * float(_equipped_softcap()) / 100.0)
	player["max_hp"] = maxi(1, unsoftened_max_hp - hp_loss)
	player["hp"] = mini(int(player["hp"]), int(player["max_hp"]))


func _max_hp_increase_percent() -> int:
	var base_max_hp := int(player.get("base_max_hp", 100))
	return maxi(0, roundi(float(int(player["max_hp"]) - base_max_hp) * 100.0 / float(base_max_hp)))


func _overdrive_unlocked() -> bool:
	return _equipped_softcap() >= 60


func _ability_requirement_met(ability: Dictionary) -> bool:
	if bool(ability.get("overdrive", false)) and not _overdrive_unlocked():
		return false
	return _max_hp_increase_percent() >= int(ability.get("requires_max_hp_percent", 0))


func _open_inventory() -> void:
	if state == "inventory":
		return
	previous_state = state
	inventory_container["augments"] = augment_inventory
	inventory_container["consumables"] = consumable_inventory
	inventory_container["echoes"] = echo_inventory
	state = "inventory"
	_refresh_ui()


func _close_inventory() -> void:
	if state != "inventory":
		return
	state = previous_state
	_refresh_ui()


func _enter_map_node(node_id: String) -> void:
	if state != "map" or not accessible_node_ids.has(node_id):
		return
	var nodes: Dictionary = floor_map.get("nodes", {})
	if not nodes.has(node_id):
		push_error("Floor map references unknown node: %s" % node_id)
		return
	current_node = nodes[node_id]
	current_map_node_id = node_id
	visited_node_ids.append(node_id)
	accessible_node_ids.clear()
	match String(current_node["type"]):
		"combat", "elite":
			var encounter_index := int(current_node["encounter_index"])
			var encounters := FloorData.encounters()
			if encounter_index < 0 or encounter_index >= encounters.size():
				push_error("Map node %s has invalid encounter index %d." % [node_id, encounter_index])
				return
			_start_encounter(encounters[encounter_index])
		"rest":
			state = "rest"
			_refresh_ui()
		"event":
			state = "event"
			_refresh_ui()
		"shop":
			state = "shop"
			_refresh_ui()
		"boss":
			var boss_encounter := {
				"title": String(current_boss["name"]),
				"kind": "boss",
				"enemies": [],
			}
			_start_encounter(boss_encounter)
		_:
			push_error("Unsupported floor map node type: %s" % current_node["type"])


func _advance_to_map() -> void:
	accessible_node_ids.clear()
	for next_id in current_node.get("connections", []):
		if not visited_node_ids.has(String(next_id)):
			accessible_node_ids.append(String(next_id))
	state = "map"
	_refresh_ui()


func _draw_map_connections() -> void:
	var rows: Array = floor_map.get("rows", [])
	for row_index in range(rows.size() - 1):
		for node in rows[row_index]:
			var start := _map_node_position(node)
			for next_id in node.get("connections", []):
				var next_node: Dictionary = floor_map["nodes"].get(String(next_id), {})
				if not next_node.is_empty():
					draw_line(start, _map_node_position(next_node), Color("#536471"), 3.0, true)


func _map_node_position(node: Dictionary) -> Vector2:
	var row_nodes: Array = floor_map["rows"][int(node["row"])]
	var node_count := row_nodes.size()
	var spacing := 390.0
	var center_x := 640.0 + (float(int(node["column"])) - float(node_count - 1) / 2.0) * spacing
	var center_y := 637.0 - float(int(node["row"])) * 87.0
	return Vector2(center_x, center_y)


func _map_node_label(node: Dictionary, visited: bool = false) -> String:
	var kind := String(node.get("type", ""))
	if kind == "event":
		return "CLEARED\n?" if visited else "?\nRANDOM ENCOUNTER"
	if visited:
		return "CLEARED\n%s" % String(node.get("title", ""))
	return "%s\n%s" % [kind.to_upper(), String(node.get("title", ""))]


func _start_encounter(encounter: Dictionary) -> void:
	state = "battle"
	turn_number = 1
	player["block"] = 0
	player["focus"] = int(player["focus_cap"])
	player["damage_buff"] = 0
	player["damage_buff_turns"] = 0
	player["weak_turns"] = 0
	player["marked_turns"] = 0
	player["viral_percent"] = 0.0
	player["turn_end_damage"] = 0
	drone_turns = 0
	drone_damage = 0
	item_used_this_turn = false
	battle_menu = "Abilities"
	cooldowns.clear()
	enemies = encounter["enemies"].duplicate(true)
	selected_target = 0
	combat_log.clear()
	concierge_respawned = false
	matron_summons = 0

	passive_triggers.clear()
	_trigger_passives("combat_start")

	if encounter.get("kind", "") == "boss":
		_set_boss_intro_enemies()
		_log("BOSS ENCOUNTER // %s" % encounter["title"])
	else:
		_log("%s // Floor 1" % encounter["title"])
	_assign_intents()
	_refresh_ui()


func _set_boss_intro_enemies() -> void:
	var boss_type := String(current_boss["type"])
	var boss: Dictionary = FloorData.make_enemy(
		String(current_boss["name"]),
		boss_type,
		int(current_boss["hp"]),
		int(current_boss["damage"]),
		current_boss["color"]
	)
	enemies = [boss]
	match boss_type:
		"boss_choir":
			enemies.append(FloorData.make_enemy("Parasite Node", "node", 80, 6, Color("#9e78bb")))
			enemies.append(FloorData.make_enemy("Parasite Node", "node", 80, 6, Color("#9e78bb")))
		"boss_concierge":
			enemies.append(FloorData.make_enemy("Chrome Bellhop", "bellhop", 28, 5, Color("#f0ad55")))
			enemies.append(FloorData.make_enemy("Chrome Bellhop", "bellhop", 28, 5, Color("#f0ad55")))
		"boss_mycelial":
			enemies.append(FloorData.make_enemy("Mycelial Node", "mycelial_node", 20, 6, Color("#97bd82")))


func _begin_player_turn() -> void:
	turn_number += 1
	player["focus"] = int(player["focus_cap"]) + pending_focus
	pending_focus = 0
	item_used_this_turn = false
	for key in cooldowns.keys():
		cooldowns[key] = maxi(0, int(cooldowns[key]) - 1)
	if int(player["weak_turns"]) > 0:
		player["weak_turns"] = int(player["weak_turns"]) - 1
	if int(player["marked_turns"]) > 0:
		player["marked_turns"] = int(player["marked_turns"]) - 1
	if int(player["damage_buff_turns"]) > 0:
		player["damage_buff_turns"] = int(player["damage_buff_turns"]) - 1
		if int(player["damage_buff_turns"]) == 0:
			player["damage_buff"] = 0
	if float(player["viral_percent"]) > 0.0:
		_player_take_damage(maxi(1, roundi(float(player["max_hp"]) * float(player["viral_percent"]))), true)
		_log("Viral Bloom costs %d HP." % maxi(1, roundi(float(player["max_hp"]) * float(player["viral_percent"]))))
	if int(player["hp"]) <= 0:
		_finish_run(false)
		return
	_assign_intents()
	_refresh_ui()


func _assign_intents() -> void:
	EnemyIntentHandler.assign(self)


func _count_alive_type(enemy_type: String) -> int:
	var total := 0
	for enemy in enemies:
		if String(enemy["type"]) == enemy_type and int(enemy["hp"]) > 0:
			total += 1
	return total


func _perform_action(action_key: String) -> void:
	if state != "battle":
		return
	if action_key == "end_turn":
		_end_player_turn()
		return
	if action_key == "item" or action_key.begins_with("item:"):
		var item_index := int(action_key.get_slice(":", 1)) if action_key.contains(":") else 0
		_use_consumable(item_index)
		return
	if CombatActionHandler.perform(self, action_key):
		_check_combat_state()
		_refresh_ui()


func _deal_damage_to_target(damage: int, block_pierce_percent: int = 0, target_override: int = -1) -> void:
	var target_index := selected_target if target_override < 0 else target_override
	if target_index < 0 or target_index >= enemies.size():
		return
	if int(enemies[target_index]["hp"]) <= 0:
		return
	var final_damage := damage
	if int(player["weak_turns"]) > 0:
		final_damage = maxi(1, roundi(float(final_damage) * 0.95))
	if int(player["damage_buff_turns"]) > 0:
		final_damage = roundi(float(final_damage) * (1.0 + float(player["damage_buff"]) / 100.0))
	if int(player["marked_turns"]) > 0:
		final_damage = roundi(float(final_damage) * 1.25)
	var passive_bonus := PassiveHandler.damage_bonus_percent(self, target_index)
	if passive_bonus > 0:
		final_damage = roundi(float(final_damage) * (1.0 + float(passive_bonus) / 100.0))
	if int(enemies[target_index]["marked"]) > 0:
		final_damage = roundi(float(final_damage) * 1.25)
	var enemy: Dictionary = enemies[target_index]
	var block_damage := int(enemy["block"])
	if block_pierce_percent > 0:
		block_damage = ceili(float(block_damage) * (100.0 - float(block_pierce_percent)) / 100.0)
	var absorbed := mini(block_damage, final_damage)
	enemy["block"] = maxi(0, int(enemy["block"]) - absorbed)
	enemy["hp"] = maxi(0, int(enemy["hp"]) - (final_damage - absorbed))
	enemies[target_index] = enemy
	if enemy["type"] == "butler" and int(enemy["block"]) > 0:
		var reflected := maxi(1, roundi(float(absorbed) * 0.25))
		_player_take_damage(reflected, true)
		_log("Metallic Poise reflects %d true damage." % reflected)
	if int(enemy["hp"]) <= 0:
		_log("%s is defeated." % enemy["name"])


func _deal_aoe_damage(damage: int) -> void:
	for index in range(enemies.size()):
		if int(enemies[index]["hp"]) > 0:
			_deal_damage_to_target(damage, 0, index)


func _any_enemy_hacked() -> bool:
	for enemy in enemies:
		if int(enemy["hp"]) > 0 and int(enemy["hacked"]) > 0:
			return true
	return false


func _effect_context(source_name: String) -> Dictionary:
	return {
		"game": self,
		"actor": player,
		"targets": enemies,
		"source_name": source_name,
		"damage_target": Callable(self, "_deal_damage_to_target"),
		"heal": Callable(self, "_heal"),
		"take_damage": Callable(self, "_player_take_damage"),
		"log": Callable(self, "_log"),
		"gain_focus": Callable(self, "_gain_focus"),
	}


func _gain_focus(amount: int, timing: String) -> void:
	if timing == "next_turn":
		pending_focus += amount
	else:
		player["focus"] = int(player["focus"]) + amount
	_log("Gain %d Focus%s." % [amount, " next turn" if timing == "next_turn" else ""])


func _trigger_passives(trigger_name: String) -> void:
	PassiveHandler.trigger(self, trigger_name)


func _count_chrome_augments() -> int:
	var count := 0
	for slot in SLOT_NAMES:
		var augment: Dictionary = loadout.get(slot, {})
		if String(augment.get("archetype", "")) == "Chrome Titan" or String(augment.get("brand", "")) == "Chrome Titan":
			count += 1
	return count


func _use_consumable(item_index: int = 0) -> void:
	if ConsumableHandler.use(self, item_index):
		_check_combat_state()
		_refresh_ui()


func _end_player_turn() -> void:
	if state != "battle":
		return
	var end_damage := int(player["turn_end_damage"])
	if end_damage > 0:
		player["turn_end_damage"] = 0
		_player_take_damage(end_damage, true)
		_log("End-of-turn cost: %d HP." % end_damage)
		if int(player["hp"]) <= 0:
			_finish_run(false)
			return
	_log("Turn %d ends. Enemies act in initiative order." % turn_number)
	var action_count := enemies.size()
	for index in range(action_count):
		if index >= enemies.size() or int(enemies[index]["hp"]) <= 0:
			continue
		_resolve_enemy_intent(index)
		if int(player["hp"]) <= 0:
			_finish_run(false)
			return
		if _all_enemies_defeated():
			_on_combat_won()
			return

	if drone_turns > 0:
		var drone_targets: Array[int] = []
		for index in range(enemies.size()):
			if int(enemies[index]["hp"]) > 0:
				drone_targets.append(index)
		if not drone_targets.is_empty():
			selected_target = drone_targets[rng.randi_range(0, drone_targets.size() - 1)]
			_deal_damage_to_target(drone_damage)
			_log("Ghostwave Drone deals %d damage." % drone_damage)
			if _all_enemies_defeated():
				_on_combat_won()
				return
		drone_turns -= 1

	_tick_enemy_statuses()
	player["block"] = 0
	if int(player["hp"]) <= 0:
		_finish_run(false)
		return
	_begin_player_turn()


func _resolve_enemy_intent(index: int) -> void:
	EnemyActionExecutor.execute(self, index)


func _resolve_summon(enemy: Dictionary) -> void:
	var enemy_type := String(enemy["type"])
	match enemy_type:
		"boss_matron":
			enemies.append(FloorData.make_enemy("Crown Acolyte", "acolyte", 40, 5, Color("#d8c88e")))
			matron_summons += 1
			_log("The Matron summons a Crown Acolyte.")
		"boss_concierge":
			if not concierge_respawned:
				enemies.append(FloorData.make_enemy("Chrome Bellhop", "bellhop", 28, 5, Color("#f0ad55")))
				concierge_respawned = true
				_log("The Concierge calls in a Bellhop.")
		"boss_mycelial":
			if _count_alive_type("mycelial_node") < 2:
				enemies.append(FloorData.make_enemy("Mycelial Node", "mycelial_node", 20, 6, Color("#97bd82")))
				_log("A Mycelial Node sprouts from the floor.")


func _resolve_absorb_growth(host_index: int) -> void:
	var node_count := _count_alive_type("mycelial_node")
	for index in range(enemies.size()):
		if enemies[index]["type"] == "mycelial_node" and int(enemies[index]["hp"]) > 0:
			enemies[index]["hp"] = 0
	var host: Dictionary = enemies[host_index]
	host["hp"] = mini(int(host["max_hp"]), int(host["hp"]) + node_count * 12)
	host["damage"] = int(host["damage"]) + node_count * 2
	enemies[host_index] = host
	_log("The Host absorbs %d Node(s), restoring HP and growing stronger." % node_count)


func _tick_enemy_statuses() -> void:
	for index in range(enemies.size()):
		var enemy: Dictionary = enemies[index]
		if int(enemy["hp"]) <= 0:
			continue
		if int(enemy["burn"]) > 0:
			enemy["hp"] = maxi(0, int(enemy["hp"]) - int(enemy["burn"]))
			enemy["burn"] = maxi(0, int(enemy["burn"]) - 1)
		if int(enemy["hacked"]) > 0:
			enemy["hacked"] = int(enemy["hacked"]) - 1
		if int(enemy["marked"]) > 0:
			enemy["marked"] = int(enemy["marked"]) - 1
		enemies[index] = enemy


func _player_take_damage(amount: int, ignore_block: bool = false) -> void:
	if amount <= 0:
		return
	var remaining := amount
	if not ignore_block:
		var absorbed := mini(int(player["block"]), remaining)
		player["block"] = int(player["block"]) - absorbed
		remaining -= absorbed
	player["hp"] = maxi(0, int(player["hp"]) - remaining)


func _heal(amount: int) -> void:
	if amount <= 0:
		return
	var before := int(player["hp"])
	player["hp"] = mini(int(player["max_hp"]), before + amount)
	_log("Recover %d HP." % (int(player["hp"]) - before))


func _remove_one_debuff() -> void:
	var removable: Array[String] = []
	if int(player["weak_turns"]) > 0:
		removable.append("weak_turns")
	if int(player["marked_turns"]) > 0:
		removable.append("marked_turns")
	if float(player["viral_percent"]) > 0.0:
		removable.append("viral_percent")
	if removable.is_empty():
		_log("No debuff to remove.")
		return
	var effect := removable[rng.randi_range(0, removable.size() - 1)]
	if effect == "viral_percent":
		player[effect] = 0.0
	else:
		player[effect] = 0
	_log("Removed a debuff.")


func _apply_random_debuff() -> void:
	match rng.randi_range(0, 2):
		0:
			player["weak_turns"] = maxi(int(player["weak_turns"]), 2)
		1:
			player["marked_turns"] = maxi(int(player["marked_turns"]), 2)
		_:
			player["viral_percent"] = maxf(float(player["viral_percent"]), 0.03)
	_log("The Singularity applies a random debuff.")


func _check_combat_state() -> void:
	if int(player["hp"]) <= 0:
		_finish_run(false)
	elif _all_enemies_defeated():
		_on_combat_won()


func _all_enemies_defeated() -> bool:
	for enemy in enemies:
		if int(enemy["hp"]) > 0:
			return false
	return true


func _on_combat_won() -> void:
	var encounter_kind := String(current_node.get("type", "combat"))
	var points := 50 if encounter_kind == "boss" else (25 if encounter_kind == "elite" else 15)
	run_points += points
	if encounter_kind == "boss":
		_log("Floor 1 boss defeated. +%d run points." % points)
		run_summary = "Floor 1 cleared. %d nodes visited; %d run points earned." % [visited_node_ids.size(), run_points]
		_build_reward_container()
		state = "boss_reward"
		_refresh_ui()
		return
	_log("Combat won. +%d run points. Choose one reward." % points)
	_build_reward_container()
	state = "reward"
	_refresh_ui()


func _build_reward_container() -> void:
	var encounter_kind := String(current_node.get("type", "combat"))
	var nanite_payout := 100 if encounter_kind == "boss" else (50 if encounter_kind == "elite" else 25)
	var excluded_names: Array = []
	for slot in SLOT_NAMES:
		var equipped: Dictionary = loadout[slot]
		if not equipped.is_empty():
			excluded_names.append(String(equipped["name"]))
	var augment_choices: Array = []
	for index in range(3):
		var augment := FloorData.random_augment(rng, excluded_names)
		augment_choices.append(augment)
		excluded_names.append(String(augment["name"]))
	var consumable_drop: Dictionary = {}
	var drop_chance := 0.35 if encounter_kind == "combat" else (0.6 if encounter_kind == "elite" else 1.0)
	if rng.randf() < drop_chance:
		consumable_drop = FloorData.random_consumable(rng)
	reward_container = {
		"type": "combat_reward",
		"nanites": nanite_payout,
		"nanite_vial": {
			"type": "nanite_vial",
			"choices": augment_choices,
		},
		"consumable": consumable_drop,
	}
	selected_reward_augment = -1


func _select_reward_augment(index: int) -> void:
	if state != "reward" and state != "boss_reward":
		return
	var choices: Array = reward_container.get("nanite_vial", {}).get("choices", [])
	if index < 0 or index >= choices.size():
		return
	selected_reward_augment = index
	_refresh_ui()


func _claim_rewards() -> void:
	if state != "reward" and state != "boss_reward":
		return
	var choices: Array = reward_container.get("nanite_vial", {}).get("choices", [])
	if selected_reward_augment < 0 or selected_reward_augment >= choices.size():
		return
	var boss_reward := state == "boss_reward"
	var augment: Dictionary = choices[selected_reward_augment]
	var replaced: Dictionary = loadout.get(String(augment["slot"]), {})
	_carry_augment(augment, true)
	player["nanites"] = int(player.get("nanites", 0)) + int(reward_container.get("nanites", 0))
	if not replaced.is_empty():
		_log("%s replaces %s in the %s slot." % [augment["name"], replaced["name"], augment["slot"]])
	else:
		_log("Equipped %s in the %s slot." % [augment["name"], augment["slot"]])
	_log("Collected %d Nanites." % int(reward_container.get("nanites", 0)))
	var consumable: Dictionary = reward_container.get("consumable", {})
	if not consumable.is_empty():
		consumable_inventory.append(consumable.duplicate(true))
		_log("Added %s to your consumables." % consumable["name"])
	if boss_reward:
		_finish_run(true)
		return
	reward_container.clear()
	_advance_to_map()


func _resolve_event_choice(choice: String) -> void:
	if state != "event":
		return
	match choice:
		"patch":
			_heal(12)
			_log("The fractured hallway yields a medical patch.")
		"salvage":
			player["nanites"] = int(player.get("nanites", 0)) + 25
			_log("Salvaged 25 Nanites from the rift.")
		_:
			push_error("Unsupported event choice: %s" % choice)
			return
	_advance_to_map()


func _buy_shop_item(item_name: String, cost: int) -> void:
	if state != "shop":
		return
	if int(player.get("nanites", 0)) < cost:
		_log("Not enough Nanites.")
		_refresh_ui()
		return
	if item_name != "Nanite Injection Vial":
		push_error("Unknown shop item: %s" % item_name)
		return
	player["nanites"] = int(player["nanites"]) - cost
	consumable_inventory.append(FloorData.consumables()[0].duplicate(true))
	_log("Bought %s for %d Nanites." % [item_name, cost])
	_advance_to_map()


func _leave_shop() -> void:
	if state == "shop":
		_advance_to_map()


func _take_rest() -> void:
	if state != "rest":
		return
	var amount := roundi(float(int(player["max_hp"])) * 0.3)
	_heal(amount)
	_advance_to_map()


func _tune_augment(slot: String) -> void:
	if state != "rest":
		return
	var augment: Dictionary = loadout.get(slot, {})
	if augment.is_empty() or bool(augment.get("tuned", false)):
		return
	augment["tuned"] = true
	var abilities: Array = augment.get("abilities", [])
	for index in range(abilities.size()):
		var ability: Dictionary = abilities[index]
		ability["effects"] = _tune_effects(ability.get("effects", []))
		augment["abilities"][index] = ability
	loadout[slot] = augment
	_log("Tuned %s. Its active abilities are stronger for this run." % augment["name"])
	_advance_to_map()


func _tune_effects(effects: Array) -> Array:
	var tuned: Array = []
	for effect in effects:
		var updated: Dictionary = effect.duplicate(true)
		if String(updated.get("type", "")) in ["damage", "block", "heal", "focus", "damage_buff"]:
			var amount := int(updated.get("amount", 0))
			if amount > 0:
				updated["amount"] = amount + maxi(1, roundi(float(amount) * 0.2))
		tuned.append(updated)
	return tuned


func _finish_run(victory: bool) -> void:
	if run_finished:
		return
	run_finished = true
	state = "complete" if victory else "game_over"
	var earned_xp := run_points
	var threshold := metal_level * 100
	metal_xp += earned_xp
	while metal_xp >= threshold:
		metal_xp -= threshold
		metal_level += 1
		threshold = metal_level * 100
	_save_profile()
	if run_summary.is_empty():
		run_summary = "Run ended at %s. %d nodes visited; %d run points became Metal XP." % [
			String(current_node.get("title", "the Tower")),
			visited_node_ids.size(),
			earned_xp,
		]
	else:
		run_summary += " %d Metal XP banked; %d run-only Nanites collected." % [earned_xp, int(player.get("nanites", 0))]
	_refresh_ui()


func _has_augment(augment_name: String) -> bool:
	for slot in SLOT_NAMES:
		if loadout[slot].get("name", "") == augment_name:
			return true
	return false


func _log(message: String) -> void:
	combat_log.append(message)
	while combat_log.size() > 5:
		combat_log.pop_front()


func _refresh_ui() -> void:
	if DisplayServer.get_name() == "headless":
		return
	for child in get_children():
		remove_child(child)
		child.queue_free()
	queue_redraw()
	_draw_header()
	match state:
		"map": _draw_map_ui()
		"battle": _draw_battle_ui()
		"reward", "boss_reward": _draw_reward_ui()
		"rest": _draw_rest_ui()
		"event": _draw_event_ui()
		"shop": _draw_shop_ui()
		"inventory": _draw_inventory_ui()
		"complete", "game_over": _draw_end_ui()


func _draw_header() -> void:
	_add_label("TOWER OF VEGA", Vector2(30, 18), Vector2(390, 38), 27, TEXT)
	_add_label("FLOOR 01  /  THE ROTTING RESORT", Vector2(32, 55), Vector2(520, 20), 12, CYAN)
	var node_text := "NODE MAP" if state == "map" else "INVENTORY" if state == "inventory" else String(current_node.get("title", "FLOOR 1"))
	_add_label("%s     NANITES %d  ·  METAL %d  ·  %d / %d XP" % [node_text.to_upper(), int(player.get("nanites", 0)), metal_level, metal_xp, metal_level * 100], Vector2(470, 28), Vector2(495, 26), 11, GOLD)
	if state != "inventory":
		_add_button("INVENTORY", Rect2(975, 24, 126, 38), Callable(self, "_open_inventory"), CYAN)
	else:
		_add_button("BACK", Rect2(975, 24, 126, 38), Callable(self, "_close_inventory"), CYAN)
	_add_button("NEW RUN", Rect2(1115, 24, 132, 38), Callable(self, "_start_new_run"), RED)
	_draw_progress_track()


func _draw_progress_track() -> void:
	var labels := ["ENTRY", "CROSSROADS", "DEPTHS", "ROUTE", "REST", "BOSS"]
	for row_index in range(labels.size()):
		var row_nodes: Array = floor_map.get("rows", [])[row_index] if row_index < floor_map.get("rows", []).size() else []
		var completed := false
		var active := false
		for node in row_nodes:
			completed = completed or visited_node_ids.has(String(node["id"]))
			active = active or accessible_node_ids.has(String(node["id"]))
		var tint := CYAN if completed or active else MUTED
		var marker := "◆ " if completed else "▸ " if active else "· "
		_add_label(marker + labels[row_index], Vector2(32.0 + float(row_index) * 158.0, 81), Vector2(145, 18), 11, tint)


func _draw_map_ui() -> void:
	_add_panel(Rect2(54, 117, 1172, 575), PANEL, BORDER)
	_add_label("FLOOR 1 · THE ROTTING RESORT", Vector2(82, 130), Vector2(550, 32), 23, CYAN)
	_add_label("Choose a connected node. The boss and rest are always at this floor's end.", Vector2(83, 163), Vector2(930, 24), 13, MUTED)
	var rows: Array = floor_map.get("rows", [])
	for row in rows:
		for node in row:
			var node_id := String(node["id"])
			var center := _map_node_position(node)
			var rect := Rect2(center - Vector2(100, 25), Vector2(200, 50))
			var visited := visited_node_ids.has(node_id)
			var reachable := accessible_node_ids.has(node_id)
			var kind := String(node["type"])
			var accent := _node_color(kind)
			var node_label := _map_node_label(node, visited)
			_add_button(node_label, rect, Callable(self, "_enter_map_node").bind(node_id), accent, not reachable)
	_add_label("Generated for this floor only · Route choices lead to combat, events, a trader, a rest, and the selected boss.", Vector2(83, 651), Vector2(1060, 22), 11, MUTED)


func _node_color(node_type: String) -> Color:
	match node_type:
		"combat": return RED
		"elite": return GOLD
		"event": return CYAN
		"shop": return GREEN
		"rest": return GREEN
		"boss": return RED
	return BORDER


func _draw_battle_ui() -> void:
	_add_panel(Rect2(24, 111, 230, 310), Color("#1a222dbb"), BORDER)
	_add_label("YOU / MEATBAG", Vector2(39, 124), Vector2(185, 22), 13, CYAN)
	_add_label("%d / %d HP" % [player["hp"], player["max_hp"]], Vector2(40, 302), Vector2(185, 26), 20, RED if int(player["hp"]) <= int(player["max_hp"]) * 0.35 else TEXT)
	_add_progress_bar(Vector2(40, 331), Vector2(188, 12), float(player["hp"]) / float(player["max_hp"]), RED)
	_add_label("BLOCK  %d" % player["block"], Vector2(40, 352), Vector2(90, 20), 13, CYAN)
	_add_label("FOCUS  %d / %d" % [player["focus"], player["focus_cap"]], Vector2(133, 352), Vector2(105, 20), 13, GOLD)
	var status := "CLEAR"
	if int(player["marked_turns"]) > 0:
		status = "GOSPEL MARK"
	elif int(player["weak_turns"]) > 0:
		status = "FRACTURED"
	_add_label("STATUS  " + status, Vector2(40, 378), Vector2(190, 18), 11, MUTED)
	_add_label("CORRUPTION  %d" % player["corruption"], Vector2(40, 399), Vector2(190, 16), 10, MUTED)

	var encounter_title := String(current_node.get("title", "Floor 1 Encounter"))
	_add_label("%s  /  TURN %02d" % [encounter_title.to_upper(), turn_number], Vector2(282, 111), Vector2(940, 24), 14, GOLD)
	var count := enemies.size()
	var card_width := minf(278.0, 930.0 / maxf(1.0, float(count)))
	var gap := 14.0
	var total_width := float(count) * card_width + float(count - 1) * gap
	var start_x := 288.0 + (950.0 - total_width) / 2.0
	for index in range(count):
		var enemy: Dictionary = enemies[index]
		var x := start_x + float(index) * (card_width + gap)
		var rect := Rect2(x, 143, card_width, 260)
		var is_target := selected_target == index
		_add_panel(rect, Color("#202a35bb"), GOLD if is_target else BORDER)
		var intent_text := "DEFEATED" if int(enemy["hp"]) <= 0 else String(enemy["intent"].get("label", "Choosing..."))
		var button := _make_button(
			"",
			rect,
			Callable(self, "_select_target").bind(index),
			GOLD if is_target else CYAN,
			int(enemy["hp"]) <= 0
		)
		for state_name in ["normal", "hover", "pressed", "disabled"]:
			var clear_style := StyleBoxFlat.new()
			clear_style.bg_color = Color(0, 0, 0, 0)
			clear_style.set_border_width_all(0)
			button.add_theme_stylebox_override(state_name, clear_style)
		_add_label(String(enemy["name"]), Vector2(x + 12, 151), Vector2(card_width - 24, 24), 13, TEXT)
		_add_label("%d / %d HP" % [enemy["hp"], enemy["max_hp"]], Vector2(x + 14, 178), Vector2(card_width - 28, 18), 11, MUTED)
		_add_progress_bar(Vector2(x + 14, 199), Vector2(card_width - 28, 8), float(enemy["hp"]) / float(enemy["max_hp"]), RED)
		var intent_label := _add_label("INTENT  ·  " + intent_text, Vector2(x + 12, 321), Vector2(card_width - 24, 35), 11, GOLD)
		if int(enemy["hp"]) > 0:
			intent_label.tooltip_text = _describe_enemy_intent(enemy["intent"])
			intent_label.mouse_filter = Control.MOUSE_FILTER_PASS
		var enemy_status := "HACKED %d" % enemy["hacked"] if int(enemy["hacked"]) > 0 else "—"
		if int(enemy["block"]) > 0:
			enemy_status += "   BLOCK %d" % enemy["block"]
		_add_label(enemy_status, Vector2(x + 14, 374), Vector2(card_width - 28, 16), 10, CYAN if int(enemy["hacked"]) > 0 else MUTED)

	_add_panel(Rect2(24, 435, 1232, 259), PANEL, BORDER)
	_add_label("COMBAT ACTIONS", Vector2(40, 447), Vector2(360, 20), 12, CYAN)
	_add_label("FOCUS REFRESHES EACH TURN  ·  SELECT AN ENEMY TO TARGET", Vector2(40, 467), Vector2(590, 18), 10, MUTED)
	_add_button("END TURN", Rect2(649, 446, 153, 38), Callable(self, "_perform_action").bind("end_turn"), GOLD)
	_draw_action_buttons()
	_add_panel(Rect2(819, 447, 420, 230), PANEL_ALT, BORDER)
	_add_label("COMBAT FEED", Vector2(835, 458), Vector2(380, 19), 12, GOLD)
	_add_label("\n".join(combat_log), Vector2(835, 486), Vector2(386, 179), 11, TEXT)


func _draw_action_buttons() -> void:
	var categories := ["Abilities", "Consumables", "Hacks", "Overdrive / Herculean"]
	for index in range(categories.size()):
		var x := 40.0 + float(index) * 188.0
		var category: String = categories[index]
		_add_button(category, Rect2(x, 476, 178, 34), Callable(self, "_set_battle_menu").bind(category), GOLD if category == battle_menu else CYAN)

	var actions: Array[Dictionary] = _actions_for_battle_menu()
	if actions.is_empty():
		_add_label("No %s available." % battle_menu.to_lower(), Vector2(43, 545), Vector2(720, 30), 13, MUTED)
		return

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(40, 518)
	scroll.size = Vector2(762, 162)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	grid.custom_minimum_size = Vector2(744, 0)
	scroll.add_child(grid)
	for action in actions:
		var button := Button.new()
		button.text = String(action["title"])
		button.custom_minimum_size = Vector2(242, 43)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = not bool(action["enabled"])
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 12)
		button.add_theme_color_override("font_color", TEXT)
		button.tooltip_text = String(action.get("description", ""))
		button.pressed.connect(Callable(self, "_perform_action").bind(String(action["key"])))
		grid.add_child(button)


func _set_battle_menu(category: String) -> void:
	battle_menu = category
	_refresh_ui()


func _actions_for_battle_menu() -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if battle_menu == "Consumables":
		for index in range(consumable_inventory.size()):
			var item: Dictionary = consumable_inventory[index]
			actions.append({
				"key": "item:%d" % index,
				"title": "%s  ·  FREE" % item["name"],
				"description": String(item.get("description", "A limited-use combat item.")),
				"enabled": not item_used_this_turn,
			})
		if consumable_inventory.is_empty():
			actions.append({"key": "", "title": "No consumables", "enabled": false})
		return actions

	if battle_menu == "Abilities":
		for action_key in ["punch", "block"]:
			var base_action: Dictionary = FloorData.base_actions()[action_key]
			actions.append({
				"key": action_key,
				"title": "%s  ·  %d F" % [base_action["name"], base_action["cost"]],
				"description": _describe_action_container(base_action),
				"enabled": int(player["focus"]) >= int(base_action["cost"]),
			})

	for slot in SLOT_NAMES:
		var augment: Dictionary = loadout.get(slot, {})
		if augment.is_empty():
			continue
		var abilities: Array = augment.get("abilities", [])
		for index in range(abilities.size()):
			var ability: Dictionary = abilities[index]
			var category := _ability_menu_category(ability)
			if category != battle_menu:
				continue
			var key := "augment:%s:%d" % [slot, index]
			var cooldown := int(cooldowns.get("%s:%d" % [slot, index], 0))
			var affordable := int(player["focus"]) >= int(ability["cost"])
			var title := "%s  ·  %d F / CD%d" % [ability["name"], ability["cost"], ability["cooldown"]]
			if cooldown > 0:
				title += "  (%d)" % cooldown
			actions.append({
				"key": key,
				"title": title,
				"description": _describe_ability(ability),
				"enabled": affordable and cooldown == 0 and _ability_requirement_met(ability),
			})
	if battle_menu == "Hacks":
		var hack: Dictionary = FloorData.base_actions()["hack"]
		actions.push_front({
			"key": "hack",
			"title": "%s  ·  %d F" % [hack["name"], hack["cost"]],
			"description": _describe_action_container(hack),
			"enabled": int(player["focus"]) >= int(hack["cost"]),
		})
	return actions


func _describe_ability(ability: Dictionary) -> String:
	var lines := ["Focus cost: %d · Cooldown: %d turns" % [int(ability.get("cost", 0)), int(ability.get("cooldown", 0))]]
	if bool(ability.get("herculean", false)):
		lines.append("Herculean: requires Max HP increased by %d%% (currently +%d%%)." % [
			int(ability.get("requires_max_hp_percent", 0)),
			_max_hp_increase_percent(),
		])
	if bool(ability.get("overdrive", false)):
		lines.append("Overdrive: %d%% softcap required (%d%% equipped)." % [60, _equipped_softcap()])
	if ability.has("description"):
		lines.append(String(ability["description"]))
	var effect_text := _describe_effects(ability.get("effects", []))
	if not effect_text.is_empty():
		lines.append(effect_text)
	return "\n".join(lines)


func _describe_action_container(action: Dictionary) -> String:
	var lines: PackedStringArray = []
	if action.has("description"):
		lines.append(String(action["description"]))
	var effect_text := _describe_effects(action.get("effects", []))
	if not effect_text.is_empty():
		lines.append(effect_text)
	return "\n".join(lines)


func _describe_effects(effects: Array) -> String:
	var descriptions: PackedStringArray = []
	for effect in effects:
		if not effect is Dictionary:
			continue
		var kind := String(effect.get("type", ""))
		var amount := int(effect.get("amount", 0))
		match kind:
			"damage":
				var target_text := "all living enemies" if String(effect.get("target", "selected")) == "all" else "the selected enemy"
				var line := "Deal %d damage to %s." % [amount, target_text]
				var status_bonus: Dictionary = effect.get("bonus_if_target_status", {})
				if not status_bonus.is_empty():
					line += " Deal %d bonus damage to targets with %s." % [
						int(status_bonus.get("amount", 0)),
						String(status_bonus.get("status", "a status")).capitalize(),
					]
				var multiplier: Dictionary = effect.get("multiplier_if", {})
				if not multiplier.is_empty():
					var condition: Dictionary = multiplier.get("condition", {})
					if condition.has("target_status"):
						line += " Damage is multiplied by %d against %s targets." % [int(multiplier.get("multiplier", 1)), String(condition["target_status"]).capitalize()]
				descriptions.append(line)
			"block":
				descriptions.append("Gain %d Block." % amount)
			"heal":
				var mode := String(effect.get("mode", "flat"))
				var heal_text := "%d HP" % amount
				if mode == "max_hp_percent":
					heal_text = "%d%% of Max HP" % amount
				elif mode == "missing_hp_percent":
					heal_text = "%d%% of missing HP" % amount
				var heal_line := "Heal %s." % heal_text
				var condition: Dictionary = effect.get("condition", {})
				if condition.has("target_hp_below"):
					heal_line += " Only if the target is below %d%% HP before the ability." % int(condition["target_hp_below"])
				descriptions.append(heal_line)
			"heal_target":
				descriptions.append("Restore up to %d HP to a living target; cannot revive defeated enemies." % amount)
			"apply_status":
				var operation := String(effect.get("operation", "apply"))
				if operation == "remove_random_debuff":
					descriptions.append("Remove one random debuff.")
				elif effect.has("status"):
					descriptions.append("Apply %s for %d turn(s)." % [String(effect["status"]).capitalize(), int(effect.get("duration", 0))])
			"self_damage":
				descriptions.append("Lose %d HP." % amount)
			"focus":
				var duration := int(effect.get("duration", 0))
				var focus_line := "Gain %d Focus%s." % [amount, " next turn" if String(effect.get("timing", "immediate")) == "next_turn" else ""]
				if duration > 1:
					focus_line = "Gain %d Focus now and next turn." % amount
				var condition: Dictionary = effect.get("condition", {})
				if condition.has("actor_hp_below"):
					focus_line += " Only while below %d%% HP." % int(condition["actor_hp_below"])
				descriptions.append(focus_line)
			"damage_buff":
				descriptions.append("Gain +%d%% damage for %d turn(s)." % [amount, int(effect.get("duration", 1))])
			"corruption":
				descriptions.append("Gain %d Corruption." % amount)
			"turn_end_damage":
				descriptions.append("Take %d damage at end of turn." % amount)
			"reduce_all_cooldowns":
				descriptions.append("Reduce all active cooldowns by %d." % amount)
			"reset_all_cooldowns":
				descriptions.append("Reset all active cooldowns.")
			"deploy_drone":
				descriptions.append("Deploy a %d-damage drone for %d turns." % [int(effect.get("damage", 8)), int(effect.get("duration", 3))])
			"refresh_used_consumables":
				descriptions.append("Refresh consumables already used this combat.")
	return "\n".join(descriptions)


func _describe_enemy_intent(intent: Dictionary) -> String:
	var label := String(intent.get("label", "Unknown action"))
	match String(intent.get("kind", "attack")):
		"attack", "multi", "steal":
			var hits := int(intent.get("hits", 1))
			var damage := int(intent.get("damage", 0))
			var text := "%s: %d damage" % [label, damage]
			if hits > 1:
				text += " per hit × %d hits (%d total before Block)." % [hits, damage * hits]
			else:
				text += " before Block."
			if String(intent.get("kind", "")) == "steal":
				text += " Steals up to %d Block and adds it to the attack." % int(intent.get("steal", 0))
			return text
		"aoe":
			return "%s: deal %d damage to you." % [label, int(intent.get("damage", 0))]
		"block":
			return "%s: gain %d Block." % [label, int(intent.get("power", 0))]
		"heal":
			return "%s: restore up to %d HP to a living ally. Defeated allies cannot be revived by healing." % [label, int(intent.get("power", 0))]
		"mark":
			return "%s: %s and apply Gospel Mark." % [label, "%d damage" % int(intent.get("damage", 0)) if int(intent.get("damage", 0)) > 0 else "no direct damage"]
		"weaken":
			return "%s: deal %d damage and weaken your attacks." % [label, int(intent.get("damage", 0))]
		"summon":
			return "%s: summon an ally." % label
		"absorb":
			return "%s: absorb living Mycelial Nodes to recover HP and grow stronger." % label
		_:
			return "%s." % label


func _ability_menu_category(ability: Dictionary) -> String:
	var category := String(ability.get("menu_category", ""))
	if category in ["Overdrive / Herculean", "Hacks"]:
		return category
	var ability_name := String(ability.get("name", "")).to_lower()
	if bool(ability.get("overdrive", false)) or bool(ability.get("herculean", false)) or ability_name.begins_with("overdrive") or ability_name.begins_with("herculean"):
		return "Overdrive / Herculean"
	for effect in ability.get("effects", []):
		if String(effect.get("status", "")) == "hacked":
			return "Hacks"
	return "Abilities"


func _draw_reward_ui() -> void:
	var title := String(current_node.get("title", "Floor 1 Encounter"))
	_add_panel(Rect2(42, 137, 1196, 510), PANEL, BORDER)
	var heading := "BOSS DEFEATED" if state == "boss_reward" else "ENCOUNTER CLEARED"
	_add_label(heading, Vector2(77, 165), Vector2(480, 36), 25, GREEN)
	_add_label("%s  ·  reward container" % title, Vector2(79, 207), Vector2(660, 24), 15, TEXT)
	_add_label("NANITES  +%d" % int(reward_container.get("nanites", 0)), Vector2(855, 204), Vector2(310, 28), 18, GOLD)
	_add_label("NANITE VIAL  ·  choose 1 augment", Vector2(79, 245), Vector2(520, 22), 13, CYAN)
	var choices: Array = reward_container.get("nanite_vial", {}).get("choices", [])
	for index in range(choices.size()):
		var x := 77.0 + float(index) * 383.0
		var augment: Dictionary = choices[index]
		var selected := selected_reward_augment == index
		var rect := Rect2(x, 273, 355, 255)
		_add_panel(rect, PANEL_ALT, GOLD if selected else BORDER)
		var subtitle := "%s  ·  %s  ·  %s" % [augment["slot"], augment["rarity"], augment.get("brand", augment.get("archetype", "Augment"))]
		_add_label(String(augment["name"]), Vector2(x + 16, 290), Vector2(323, 45), 17, TEXT)
		_add_label(subtitle, Vector2(x + 16, 339), Vector2(323, 25), 11, GOLD)
		_add_label(String(augment.get("extra", "Equips to the " + String(augment["slot"]) + " slot.")), Vector2(x + 16, 371), Vector2(323, 68), 11, MUTED)
		var abilities: Array = augment.get("abilities", [])
		var ability_summary := ""
		for ability_index in range(mini(abilities.size(), 2)):
			ability_summary += "%s%s" % ["\n" if ability_index > 0 else "", abilities[ability_index]["name"]]
		var ability_label := _add_label(ability_summary, Vector2(x + 16, 440), Vector2(323, 38), 11, CYAN)
		ability_label.tooltip_text = _augment_tooltip(augment)
		ability_label.mouse_filter = Control.MOUSE_FILTER_PASS
		var choice_button := _add_button("SELECTED" if selected else "SELECT AUGMENT", Rect2(x + 16, 485, 323, 34), Callable(self, "_select_reward_augment").bind(index), GOLD if selected else CYAN)
		choice_button.tooltip_text = _augment_tooltip(augment)
	var consumable: Dictionary = reward_container.get("consumable", {})
	var consumable_text := "CONSUMABLE DROP  ·  %s" % consumable.get("name", "None this time")
	_add_label(consumable_text, Vector2(79, 541), Vector2(650, 22), 12, CYAN if not consumable.is_empty() else MUTED)
	if not consumable.is_empty():
		_add_label(String(consumable.get("description", "")), Vector2(79, 559), Vector2(650, 18), 10, MUTED)
	_add_label("Run Nanites: %d  ·  Run points: %d  ·  Metal Level %d" % [int(player.get("nanites", 0)), run_points, metal_level], Vector2(80, 576), Vector2(720, 23), 12, MUTED)
	_add_button("CLAIM REWARD CONTAINER", Rect2(854, 566, 310, 48), Callable(self, "_claim_rewards"), GREEN, selected_reward_augment < 0)


func _augment_tooltip(augment: Dictionary) -> String:
	var slot := String(augment.get("slot", "Unknown"))
	var equipped: Dictionary = loadout.get(slot, {})
	var replaces := "Empty slot"
	if not equipped.is_empty():
		replaces = "Replaces: %s" % String(equipped.get("name", "Unknown augment"))
	var lines := [
		"%s · %s · %s" % [
			String(augment.get("name", "Augment")),
			String(augment.get("rarity", "Common")),
			slot,
		],
		"Softcap: %d%% Max HP cost." % int(augment.get("softcap", 0)),
		"Max HP bonus: %+d." % int(augment.get("max_hp_bonus", 0)),
		replaces,
	]
	for ability in augment.get("abilities", []):
		lines.append("%s: %s" % [String(ability.get("name", "Ability")), _describe_ability(ability)])
	return "\n".join(lines)


func _draw_inventory_ui() -> void:
	_add_panel(Rect2(36, 112, 1208, 586), PANEL, BORDER)
	_add_label("RUN INVENTORY", Vector2(58, 124), Vector2(340, 32), 22, CYAN)
	var softcap := _equipped_softcap()
	var max_hp_loss := int(player.get("base_max_hp", 100)) + _total_max_hp_bonus()
	max_hp_loss -= int(player.get("max_hp", 100))
	var od_text := "UNLOCKED" if _overdrive_unlocked() else "LOCKED"
	_add_label(
		"HP %d / %d  ·  Max HP cost %d%% (−%d)  ·  Max HP bonus +%d  ·  Softcap %d%% / 60%%  ·  Overdrive %s  ·  Herculean requires +20%% Max HP" % [
			int(player.get("hp", 0)),
			int(player.get("max_hp", 0)),
			softcap,
			max_hp_loss,
			_total_max_hp_bonus(),
			softcap,
			od_text,
		],
		Vector2(58, 160),
		Vector2(1150, 38),
		12,
		GOLD
	)
	var titles := ["EQUIPPED AUGMENTS", "UNEQUIPPED AUGMENTS", "CONSUMABLES", "ECHOES OF ELYSIUM"]
	var columns := [
		_equipped_inventory_entries(),
		_augment_inventory_entries(),
		_consumable_inventory_entries(),
		_echo_inventory_entries(),
	]
	for index in range(titles.size()):
		var x := 52.0 + float(index) * 298.0
		_add_panel(Rect2(x, 207, 284, 467), PANEL_ALT, BORDER)
		_add_label(titles[index], Vector2(x + 13, 216), Vector2(258, 28), 12, CYAN)
		var scroll := ScrollContainer.new()
		scroll.position = Vector2(x + 10, 250)
		scroll.size = Vector2(264, 407)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		add_child(scroll)
		var list := VBoxContainer.new()
		list.custom_minimum_size = Vector2(246, 0)
		list.add_theme_constant_override("separation", 8)
		scroll.add_child(list)
		var entries: Array[String] = columns[index]
		if entries.is_empty():
			entries.append("None carried.")
		for entry in entries:
			var label := Label.new()
			label.text = entry
			label.custom_minimum_size = Vector2(240, 56)
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.add_theme_font_size_override("font_size", 11)
			label.add_theme_color_override("font_color", TEXT)
			list.add_child(label)


func _total_max_hp_bonus() -> int:
	var total := 0
	for slot in SLOT_NAMES:
		var augment: Dictionary = loadout.get(slot, {})
		total += int(augment.get("max_hp_bonus", 0))
	return total


func _equipped_inventory_entries() -> Array[String]:
	var entries: Array[String] = []
	for slot in SLOT_NAMES:
		var augment: Dictionary = loadout.get(slot, {})
		if augment.is_empty():
			entries.append("%s\nEmpty slot" % slot)
			continue
		entries.append("%s\n%s · %s\nSoftcap %d%% · Max HP %+d\n%s" % [
			slot,
			String(augment.get("name", "Augment")),
			String(augment.get("rarity", "Common")),
			int(augment.get("softcap", 0)),
			int(augment.get("max_hp_bonus", 0)),
			_ability_names(augment),
		])
	return entries


func _augment_inventory_entries() -> Array[String]:
	var entries: Array[String] = []
	for augment in augment_inventory:
		entries.append("%s · %s\n%s · Softcap %d%%\n%s" % [
			String(augment.get("name", "Augment")),
			String(augment.get("slot", "Unknown slot")),
			String(augment.get("rarity", "Common")),
			int(augment.get("softcap", 0)),
			_ability_names(augment),
		])
	return entries


func _ability_names(augment: Dictionary) -> String:
	var names: PackedStringArray = []
	for ability in augment.get("abilities", []):
		names.append(String(ability.get("name", "Ability")))
	return ", ".join(names)


func _consumable_inventory_entries() -> Array[String]:
	var entries: Array[String] = []
	for item in consumable_inventory:
		entries.append("%s · %s\n%s" % [
			String(item.get("name", "Consumable")),
			String(item.get("rarity", "Common")),
			String(item.get("description", "No description.")),
		])
	return entries


func _echo_inventory_entries() -> Array[String]:
	var entries: Array[String] = []
	for echo in echo_inventory:
		entries.append("%s · %s\n%s" % [
			String(echo.get("name", "Echo")),
			String(echo.get("rarity", "Common")),
			String(echo.get("description", "No description.")),
		])
	return entries


func _draw_rest_ui() -> void:
	_add_panel(Rect2(75, 141, 1130, 488), PANEL, BORDER)
	_add_label("REST NODE", Vector2(115, 177), Vector2(500, 35), 25, CYAN)
	_add_label("Recover or tune, then return to the floor map and choose the next connected node.", Vector2(117, 220), Vector2(920, 25), 15, TEXT)
	_add_label("Current HP: %d / %d    ·    Equipped augments: %d" % [player["hp"], player["max_hp"], _equipped_augment_count()], Vector2(117, 272), Vector2(800, 25), 14, GOLD)
	_add_panel(Rect2(117, 321, 450, 221), PANEL_ALT, BORDER)
	_add_label("REST", Vector2(140, 343), Vector2(350, 28), 18, TEXT)
	_add_label("Recover 30% of Max HP before the boss.", Vector2(140, 383), Vector2(390, 43), 13, MUTED)
	_add_button("REST  ·  HEAL %d HP" % roundi(float(int(player["max_hp"])) * 0.3), Rect2(140, 480, 396, 42), Callable(self, "_take_rest"), GREEN)
	_add_panel(Rect2(600, 321, 450, 221), PANEL_ALT, BORDER)
	_add_label("TUNE", Vector2(623, 343), Vector2(350, 28), 18, TEXT)
	_add_label("Choose an untuned augment. Its active abilities gain power.", Vector2(623, 383), Vector2(390, 47), 13, MUTED)
	for index in range(SLOT_NAMES.size()):
		var slot: String = SLOT_NAMES[index]
		var augment: Dictionary = loadout[slot]
		var x := 623.0 + float(index) * 98.0
		var label_text := "EMPTY" if augment.is_empty() else String(augment["name"])
		_add_label(label_text, Vector2(x, 444), Vector2(92, 31), 9, MUTED)
		var can_tune := not augment.is_empty() and not bool(augment.get("tuned", false))
		_add_button("TUNE" if can_tune else ("TUNED" if not augment.is_empty() else "—"), Rect2(x, 480, 92, 42), Callable(self, "_tune_augment").bind(slot), GOLD, not can_tune)
	_add_label("The boss is waiting at the end of the current floor map.", Vector2(837, 570), Vector2(322, 38), 11, MUTED)


func _draw_event_ui() -> void:
	_add_panel(Rect2(150, 165, 980, 420), PANEL, BORDER)
	_add_label(String(current_node.get("title", "Unknown Encounter")), Vector2(195, 205), Vector2(850, 44), 28, CYAN)
	_add_label("A corridor splits like a cracked mirror. Static hums behind the walls; something valuable is caught in the fracture.", Vector2(198, 270), Vector2(870, 80), 16, TEXT)
	_add_label("Choose one outcome:", Vector2(198, 376), Vector2(500, 25), 14, GOLD)
	_add_button("SCAVENGE · RECOVER 12 HP", Rect2(198, 421, 360, 56), Callable(self, "_resolve_event_choice").bind("patch"), GREEN)
	_add_button("SALVAGE · GAIN 25 NANITES", Rect2(594, 421, 360, 56), Callable(self, "_resolve_event_choice").bind("salvage"), GOLD)


func _draw_shop_ui() -> void:
	_add_panel(Rect2(150, 165, 980, 420), PANEL, BORDER)
	_add_label(String(current_node.get("title", "Trader")), Vector2(195, 205), Vector2(850, 44), 28, GREEN)
	_add_label("A rogue service terminal offers one sealed Nanite Injection Vial.", Vector2(198, 270), Vector2(870, 36), 16, TEXT)
	_add_label("Your Nanites: %d" % int(player.get("nanites", 0)), Vector2(198, 343), Vector2(500, 25), 15, GOLD)
	_add_button("BUY NANITE INJECTION VIAL · 40 NANITES", Rect2(198, 400, 440, 56), Callable(self, "_buy_shop_item").bind("Nanite Injection Vial", 40), CYAN, int(player.get("nanites", 0)) < 40)
	_add_button("LEAVE TRADER", Rect2(666, 400, 288, 56), Callable(self, "_leave_shop"), MUTED)


func _draw_end_ui() -> void:
	var won := state == "complete"
	_add_panel(Rect2(97, 140, 1086, 474), PANEL, BORDER)
	_add_label("FLOOR 1 CLEARED" if won else "RUN OVER", Vector2(150, 191), Vector2(720, 48), 32, GREEN if won else RED)
	_add_label(run_summary, Vector2(153, 260), Vector2(940, 59), 16, TEXT)
	_add_label("METAL LEVEL  %d" % metal_level, Vector2(153, 357), Vector2(400, 28), 20, GOLD)
	_add_label("%d / %d XP" % [metal_xp, metal_level * 100], Vector2(153, 398), Vector2(300, 24), 15, CYAN)
	_add_progress_bar(Vector2(153, 431), Vector2(560, 16), float(metal_xp) / float(metal_level * 100), GOLD)
	_add_label("Your run-specific augments and consumables reset. Metal Level persists; there is no between-run currency.", Vector2(153, 479), Vector2(900, 42), 13, MUTED)
	_add_button("START ANOTHER RUN", Rect2(153, 539, 280, 44), Callable(self, "_start_new_run"), CYAN)


func _equipped_augment_count() -> int:
	var total := 0
	for slot in SLOT_NAMES:
		if not loadout[slot].is_empty():
			total += 1
	return total


func _select_target(index: int) -> void:
	if index >= 0 and index < enemies.size() and int(enemies[index]["hp"]) > 0:
		selected_target = index
		_refresh_ui()


func _add_panel(rect: Rect2, fill: Color, outline: Color) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = outline
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	return panel


func _make_button(text: String, rect: Rect2, action: Callable, accent: Color, disabled: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.disabled = disabled
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_disabled_color", MUTED.darkened(0.2))
	for state_name in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#283744") if state_name == "normal" else Color("#344852") if state_name == "hover" else Color("#1b252e") if state_name == "pressed" else Color("#20252b")
		style.border_color = accent if state_name != "disabled" else BORDER.darkened(0.3)
		style.set_border_width_all(2)
		style.set_corner_radius_all(0)
		button.add_theme_stylebox_override(state_name, style)
	if action.is_valid():
		button.pressed.connect(action)
	add_child(button)
	return button


func _add_button(text: String, rect: Rect2, action: Callable, accent: Color, disabled: bool = false) -> Button:
	return _make_button(text, rect, action, accent, disabled)


func _add_label(text: String, label_position: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = label_position
	label.size = label_size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _add_progress_bar(bar_position: Vector2, bar_size: Vector2, ratio: float, color: Color) -> void:
	var background := ColorRect.new()
	background.position = bar_position
	background.size = bar_size
	background.color = Color("#0c1118")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var foreground := ColorRect.new()
	foreground.position = bar_position
	foreground.size = Vector2(bar_size.x * clampf(ratio, 0.0, 1.0), bar_size.y)
	foreground.color = color
	foreground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(foreground)
