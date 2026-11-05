extends SceneTree

const MAIN_SCENE = preload("res://scenes/main.tscn")
const FloorData = preload("res://scripts/floor_one_data.gd")
const ContentValidator = preload("res://scripts/combat/content_validator.gd")
const CombatActionHandler = preload("res://scripts/combat/combat_action_handler.gd")
const ConsumableHandler = preload("res://scripts/combat/consumable_handler.gd")
const EnemyActionExecutor = preload("res://scripts/combat/enemy_action_executor.gd")
const EffectExecutor = preload("res://scripts/combat/effect_executor.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors := ContentValidator.validate(FloorData.augments(), FloorData.consumables(), FloorData.base_actions())
	if not _expect(errors.is_empty(), "All data containers should validate."):
		return

	var game: Variant = MAIN_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	print("Architecture test instantiated combat scene.")
	for augment in FloorData.augments():
		var slot := String(augment["slot"])
		print("Testing augment " + String(augment["name"]))
		var loadout: Dictionary = game.get("loadout")
		loadout[slot] = augment.duplicate(true)
		for ability_index in range(augment["abilities"].size()):
			if bool(augment["abilities"][ability_index].get("overdrive", false)):
				for other_slot in ["Head", "Torso", "Arm", "Legs"]:
					if other_slot != slot:
						loadout[other_slot] = {"softcap": 18}
			game.set("enemies", FloorData.encounters()[0]["enemies"].duplicate(true))
			game.set("selected_target", 0)
			var player: Dictionary = game.get("player")
			player["base_max_hp"] = 100
			player["max_hp"] = 150
			player["hp"] = int(player["max_hp"])
			player["focus"] = 100
			player["damage_buff"] = 0
			player["damage_buff_turns"] = 0
			var cooldowns: Dictionary = game.get("cooldowns")
			cooldowns.clear()
			var action_key := "augment:%s:%d" % [slot, ability_index]
			if not _expect(CombatActionHandler.perform(game, action_key), "Ability should resolve from its effect data: %s." % augment["abilities"][ability_index]["name"]):
				return

	for item in FloorData.consumables():
		print("Testing consumable " + String(item["name"]))
		game.set("enemies", FloorData.encounters()[0]["enemies"].duplicate(true))
		game.set("selected_target", 0)
		var player: Dictionary = game.get("player")
		player["hp"] = 50
		player["focus"] = 3
		player["damage_buff"] = 0
		player["damage_buff_turns"] = 0
		game.set("consumable_inventory", [item.duplicate(true)])
		var used_consumables: Array = game.get("used_consumables")
		used_consumables.clear()
		game.set("item_used_this_turn", false)
		game.set("singularity_used", false)
		if not _expect(ConsumableHandler.use(game), "Consumable should resolve from its effect data: %s." % item["name"]):
			return
		print("Resolved consumable " + String(item["name"]))
		if not _expect(game.get("consumable_inventory").is_empty(), "Single-use consumable should be removed after resolving."):
			return
	print("All listed consumables resolved.")

	var enemies: Array = FloorData.encounters()[0]["enemies"].duplicate(true)
	enemies[0]["hacked"] = 1
	enemies[0]["hp"] = 100
	enemies[0]["max_hp"] = 100
	enemies[0]["marked"] = 0
	game.set("enemies", enemies)
	game.set("loadout", {"Head": {}, "Torso": {}, "Arm": {}, "Legs": {}})
	game.set("consumable_inventory", [FloorData.consumables()[7].duplicate(true)])
	var player_state: Dictionary = game.get("player")
	player_state["hp"] = 100
	player_state["damage_buff"] = 0
	player_state["damage_buff_turns"] = 0
	player_state["weak_turns"] = 0
	player_state["marked_turns"] = 0
	game.get("used_consumables").clear()
	game.set("item_used_this_turn", false)
	var hp_before := int(game.get("enemies")[0]["hp"])
	ConsumableHandler.use(game)
	var hp_after := int(game.get("enemies")[0]["hp"])
	if not _expect(hp_after == hp_before - 30, "Shock Lattice should deal 30 to a Hacked target; before=%d after=%d." % [hp_before, hp_after]):
		return

	var heal_targets: Array = FloorData.encounters()[0]["enemies"].duplicate(true)
	heal_targets[0]["hp"] = 0
	heal_targets[1]["intent"] = {"kind": "heal", "target": 0, "power": 8}
	game.set("enemies", heal_targets)
	EnemyActionExecutor.execute(game, 1)
	if not _expect(int(game.get("enemies")[0]["hp"]) == 0, "Enemy healing must not revive a target at zero HP."):
		return
	game.set("selected_target", 0)
	var heal_effect_context: Dictionary = game.call("_effect_context", "Heal Test")
	if not _expect(EffectExecutor.new().execute([{"type": "heal_target", "amount": 8}], heal_effect_context), "Target-heal effect should execute successfully."):
		return
	if not _expect(int(game.get("enemies")[0]["hp"]) == 0, "The data-driven target-heal effect must not revive a corpse."):
		return
	heal_targets[0]["hp"] = 10
	heal_targets[1]["intent"] = {"kind": "heal", "target": 0, "power": 8}
	game.set("enemies", heal_targets)
	EnemyActionExecutor.execute(game, 1)
	if not _expect(int(game.get("enemies")[0]["hp"]) == 18, "Enemy healing should still affect a living target."):
		return
	heal_effect_context = game.call("_effect_context", "Heal Test")
	if not _expect(EffectExecutor.new().execute([{"type": "heal_target", "amount": 8}], heal_effect_context), "Target-heal effect should execute for a living target."):
		return
	if not _expect(int(game.get("enemies")[0]["hp"]) == 24, "Target-heal effects should clamp living targets to Max HP."):
		return

	game.set("battle_menu", "Hacks")
	var hack_actions: Array = game.call("_actions_for_battle_menu")
	if not _expect(not hack_actions.is_empty() and String(hack_actions[0]["key"]) == "hack", "Hack actions should be in the Hacks submenu."):
		return
	game.set("consumable_inventory", [FloorData.consumables()[0].duplicate(true)])
	game.set("battle_menu", "Consumables")
	var consumable_actions: Array = game.call("_actions_for_battle_menu")
	if not _expect(not consumable_actions.is_empty() and String(consumable_actions[0]["key"]).begins_with("item:"), "Consumables should be listed in their own submenu."):
		return
	if not _expect(not String(consumable_actions[0].get("description", "")).is_empty(), "Consumable submenu entries should expose hover descriptions."):
		return
	game.set("battle_menu", "Abilities")
	var ability_actions: Array = game.call("_actions_for_battle_menu")
	if not _expect(not ability_actions.is_empty() and not String(ability_actions[0].get("description", "")).is_empty(), "Ability submenu entries should expose effect descriptions."):
		return
	var intent_description := String(game.call("_describe_enemy_intent", {"kind": "multi", "label": "Coronation Lash", "damage": 7, "hits": 3}))
	if not _expect(intent_description.contains("7 damage per hit") and intent_description.contains("3 hits"), "Multi-hit enemy intents should describe hit count and damage."):
		return

	var clarity: Dictionary = {}
	var meat_hook: Dictionary = {}
	var iron_will: Dictionary = {}
	var blackout_harness: Dictionary = {}
	for augment in FloorData.augments():
		match String(augment["name"]):
			"Burnout Goggles":
				clarity = augment
			"Pulse-Bound Gauntlet":
				meat_hook = augment
			"Iron Will Plating":
				iron_will = augment
			"Blackout Harness":
				blackout_harness = augment
	game.set("loadout", {"Head": clarity.duplicate(true), "Torso": {}, "Arm": {}, "Legs": {}})
	game.set("enemies", FloorData.encounters()[0]["enemies"].duplicate(true))
	game.set("selected_target", 0)
	player_state = game.get("player")
	player_state["hp"] = 49
	player_state["max_hp"] = 100
	player_state["base_max_hp"] = 100
	player_state["focus"] = 3
	game.set("pending_focus", 0)
	game.get("cooldowns").clear()
	if not _expect(CombatActionHandler.perform(game, "augment:Head:0"), "Clarity Under Fire should resolve below 50% HP."):
		return
	if not _expect(int(player_state["focus"]) == 4 and int(game.get("pending_focus")) == 1, "Clarity should grant one Focus now and one next turn."):
		return
	game.call("_begin_player_turn")
	if not _expect(int(player_state["focus"]) == 4, "Clarity's second Focus should be granted at the next turn refresh."):
		return
	player_state["hp"] = 50
	player_state["focus"] = 3
	game.set("pending_focus", 0)
	game.get("cooldowns").clear()
	if not _expect(CombatActionHandler.perform(game, "augment:Head:0"), "Clarity should remain activatable at 50% HP."):
		return
	if not _expect(int(player_state["focus"]) == 3 and int(game.get("pending_focus")) == 0, "Clarity should not grant Focus at or above 50% HP."):
		return

	game.set("loadout", {"Head": {}, "Torso": {}, "Arm": meat_hook.duplicate(true), "Legs": {}})
	game.set("enemies", FloorData.encounters()[0]["enemies"].duplicate(true))
	game.get("enemies")[0]["hp"] = 10
	player_state["hp"] = 60
	game.get("cooldowns").clear()
	if not _expect(CombatActionHandler.perform(game, "augment:Arm:0"), "Meat Hook should resolve against a target below 50% HP."):
		return
	if not _expect(int(player_state["hp"]) == 64, "Meat Hook should heal its caster for 4 HP when its target was below 50% HP."):
		return
	game.get("enemies")[0]["hp"] = 15
	player_state["hp"] = 60
	game.get("cooldowns").clear()
	if not _expect(CombatActionHandler.perform(game, "augment:Arm:0"), "Meat Hook should resolve against a target at or above 50% HP."):
		return
	if not _expect(int(player_state["hp"]) == 60, "Meat Hook should not heal when its target was at or above 50% HP."):
		return

	game.set("loadout", {"Head": {}, "Torso": iron_will.duplicate(true), "Arm": {}, "Legs": {}})
	game.set("battle_menu", "Overdrive / Herculean")
	player_state["base_max_hp"] = 100
	player_state["max_hp"] = 115
	player_state["hp"] = 115
	player_state["focus"] = 100
	var herculean_actions: Array = game.call("_actions_for_battle_menu")
	var herculean_enabled := false
	for action in herculean_actions:
		if String(action["key"]) == "augment:Torso:2":
			herculean_enabled = bool(action["enabled"])
	if not _expect(not herculean_enabled, "Herculean abilities should remain locked below the required Max HP increase."):
		return
	if not _expect(not CombatActionHandler.perform(game, "augment:Torso:2"), "The action handler must reject a locked Herculean ability."):
		return
	player_state["max_hp"] = 120
	player_state["hp"] = 120
	if not _expect(CombatActionHandler.perform(game, "augment:Torso:2"), "Herculean abilities should unlock at the required Max HP increase."):
		return

	game.set("loadout", {
		"Head": {"softcap": 18},
		"Torso": blackout_harness.duplicate(true),
		"Arm": {"softcap": 18},
		"Legs": {"softcap": 18},
	})
	player_state["max_hp"] = 40
	player_state["hp"] = 40
	game.set("battle_menu", "Overdrive / Herculean")
	game.get("cooldowns").clear()
	var overdrive_actions: Array = game.call("_actions_for_battle_menu")
	var overdrive_enabled := false
	for action in overdrive_actions:
		if String(action["key"]) == "augment:Torso:2":
			overdrive_enabled = bool(action["enabled"])
	if not _expect(overdrive_enabled, "An Overdrive ability should unlock at 60% equipped softcap."):
		return
	game.set("enemies", FloorData.encounters()[0]["enemies"].duplicate(true))
	game.get("enemies")[0]["hp"] = 100
	game.get("enemies")[0]["hacked"] = 1
	game.get("enemies")[1]["hp"] = 100
	game.get("cooldowns").clear()
	if not _expect(CombatActionHandler.perform(game, "augment:Torso:2"), "Signal Blackout should execute once Overdrive is unlocked."):
		return
	if not _expect(int(game.get("enemies")[0]["hp"]) == 70 and int(game.get("enemies")[1]["hp"]) == 80, "Signal Blackout should deal bonus damage to enemies already Hacked."):
		return

	game.set("loadout", {"Head": {}, "Torso": {}, "Arm": {}, "Legs": {}})
	player_state["base_max_hp"] = 100
	player_state["max_hp"] = 100
	player_state["hp"] = 100
	game.get("augment_inventory").clear()
	var jammer: Dictionary = {}
	var meat_crown: Dictionary = {}
	for augment in FloorData.augments():
		if String(augment["name"]) == "Jury-Rigged Signal Jammer":
			jammer = augment
		elif String(augment["name"]) == "Meat Crown Implant":
			meat_crown = augment
	game.call("_carry_augment", jammer)
	if not _expect(int(player_state["max_hp"]) == 96, "Four percent softcap should reduce available Max HP by four percent while equipped."):
		return
	game.call("_carry_augment", meat_crown, true)
	if not _expect(int(player_state["max_hp"]) == 105, "Replacing a softcap augment should restore its HP cost and apply the new Max HP bonus."):
		return
	if not _expect(game.get("augment_inventory").size() == 1, "Replacing an augment should preserve it in unequipped inventory."):
		return
	var augment_tooltip := String(game.call("_augment_tooltip", jammer))
	if not _expect(augment_tooltip.contains("Replaces: Meat Crown Implant"), "Augment hover details should identify the equipped augment in its slot."):
		return
	game.call("_open_inventory")
	if not _expect(String(game.get("state")) == "inventory", "Inventory should open without leaving the prior run state."):
		return
	var inventory: Dictionary = game.get("inventory_container")
	if not _expect(inventory.has("augments") and inventory.has("consumables") and inventory.has("echoes"), "The player inventory container should expose augments, consumables, and Echoes."):
		return
	if not _expect(str(game.call("_equipped_inventory_entries")[0]).contains("Meat Crown Implant"), "Inventory should list equipped augments."):
		return
	if not _expect(game.call("_augment_inventory_entries").size() == 1, "Inventory should list replaced augments as unequipped."):
		return
	game.call("_close_inventory")
	var event_node := {"type": "event", "title": "Fractured Hallway"}
	if not _expect(String(game.call("_map_node_label", event_node)).contains("?") and not String(game.call("_map_node_label", event_node)).contains("Fractured"), "Random encounter map labels should hide their names behind a question mark."):
		return

	game.free()
	print("Combat architecture smoke test passed: data-driven effects, Focus duration, conditional healing, Herculean gating, softcap Max HP, inventories, and hover descriptions.")
	quit()


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		print("FAILED: " + message)
		push_error(message)
		quit(1)
		return false
	return true
