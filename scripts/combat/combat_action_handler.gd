extends RefCounted

const EffectExecutor = preload("res://scripts/combat/effect_executor.gd")
const FloorData = preload("res://scripts/floor_one_data.gd")


static func perform(game: Control, action_key: String) -> bool:
	var ability: Dictionary = {}
	var effects: Array = []
	var cost := 1
	var cooldown_key := ""
	var cooldown := 0
	var source_name := action_key.capitalize()

	if action_key.begins_with("augment:"):
		var parts := action_key.split(":")
		if parts.size() != 3:
			push_error("Invalid augment action key: %s" % action_key)
			return false
		var slot := String(parts[1])
		var ability_index := int(parts[2])
		var augment: Dictionary = game.loadout.get(slot, {})
		if augment.is_empty() or ability_index < 0 or ability_index >= augment.get("abilities", []).size():
			return false
		ability = augment["abilities"][ability_index]
		if not game._ability_requirement_met(ability):
			game._log("%s requires +%d%% Max HP." % [
				String(ability.get("name", "Ability")),
				int(ability.get("requires_max_hp_percent", 0)),
			])
			return false
		effects = ability.get("effects", [])
		cost = int(ability.get("cost", 0))
		cooldown = int(ability.get("cooldown", 0))
		cooldown_key = "%s:%d" % [slot, ability_index]
		source_name = String(ability.get("name", augment.get("name", "Ability")))
		if int(game.cooldowns.get(cooldown_key, 0)) > 0:
			return false
	else:
		var base_action: Dictionary = FloorData.base_actions().get(action_key, {})
		if base_action.is_empty():
			push_error("Unknown combat action: %s" % action_key)
			return false
		source_name = String(base_action["name"])
		cost = int(base_action["cost"])
		effects = base_action["effects"]

	if int(game.player["focus"]) < cost:
		game._log("Not enough Focus.")
		return false
	game.player["focus"] = int(game.player["focus"]) - cost
	if not cooldown_key.is_empty() and cooldown > 0:
		game.cooldowns[cooldown_key] = cooldown

	var context := {
		"game": game,
		"actor": game.player,
		"targets": game.enemies,
		"source_name": source_name,
		"damage_target": Callable(game, "_deal_damage_to_target"),
		"heal": Callable(game, "_heal"),
		"take_damage": Callable(game, "_player_take_damage"),
		"log": Callable(game, "_log"),
		"gain_focus": Callable(game, "_gain_focus"),
		"target_hp_before": int(game.enemies[game.selected_target]["hp"]) if game.selected_target >= 0 and game.selected_target < game.enemies.size() else 0,
		"target_max_hp_before": int(game.enemies[game.selected_target]["max_hp"]) if game.selected_target >= 0 and game.selected_target < game.enemies.size() else 1,
	}
	var executor := EffectExecutor.new()
	return executor.execute(effects, context)
