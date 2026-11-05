extends RefCounted

const EffectExecutor = preload("res://scripts/combat/effect_executor.gd")


static func use(game: Control, item_index: int = 0) -> bool:
	if game.item_used_this_turn or item_index < 0 or item_index >= game.consumable_inventory.size():
		return false
	var item: Dictionary = game.consumable_inventory[item_index]
	var context := {
		"game": game,
		"actor": game.player,
		"targets": game.enemies,
		"source_name": String(item["name"]),
		"damage_target": Callable(game, "_deal_damage_to_target"),
		"heal": Callable(game, "_heal"),
		"take_damage": Callable(game, "_player_take_damage"),
		"log": Callable(game, "_log"),
		"gain_focus": Callable(game, "_gain_focus"),
		"target_hp_before": int(game.enemies[game.selected_target]["hp"]) if game.selected_target >= 0 and game.selected_target < game.enemies.size() else 0,
		"target_max_hp_before": int(game.enemies[game.selected_target]["max_hp"]) if game.selected_target >= 0 and game.selected_target < game.enemies.size() else 1,
	}
	var executor := EffectExecutor.new()
	if not executor.execute(item.get("effects", []), context):
		return false
	game.consumable_inventory.remove_at(item_index)
	game.item_used_this_turn = true
	game.used_consumables.append(item.duplicate(true))
	game._log("Used %s." % item["name"])
	return true
