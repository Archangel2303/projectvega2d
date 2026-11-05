extends RefCounted


static func make_enemy(enemy_name: String, enemy_type: String, hp: int, damage: int, color: Color) -> Dictionary:
	return {
		"name": enemy_name,
		"type": enemy_type,
		"hp": hp,
		"max_hp": hp,
		"damage": damage,
		"block": 0,
		"intent": {},
		"color": color,
		"chrome": enemy_type in ["bellhop", "butler", "boss_concierge", "boss_challenger", "boss_matron", "boss_choir"],
		"hacked": 0,
		"burn": 0,
		"weak": 0,
		"marked": 0,
	}


static func encounters() -> Array:
	return [
		{
			"title": "Luxury Checkpoint",
			"kind": "combat",
			"enemies": [
				make_enemy("Chrome Bellhop", "bellhop", 24, 6, Color("#f0ad55")),
				make_enemy("Spa Attendant", "attendant", 20, 4, Color("#67b7a5")),
			],
		},
		{
			"title": "Cracked Promenade",
			"kind": "combat",
			"enemies": [
				make_enemy("Mascot Construct", "mascot", 40, 5, Color("#df755e")),
				make_enemy("Choir Drone", "drone", 18, 4, Color("#9b82d4")),
			],
		},
		{
			"title": "Chrome Butler",
			"kind": "elite",
			"enemies": [
				make_enemy("Chrome Butler", "butler", 120, 16, Color("#dcb972")),
			],
		},
		{
			"title": "Collapsed Bathhouse",
			"kind": "combat",
			"enemies": [
				make_enemy("Echo-Tainted Staff", "staff", 28, 7, Color("#7d9bb8")),
				make_enemy("Chrome Bellhop", "bellhop", 24, 6, Color("#f0ad55")),
			],
		},
	]


static func base_actions() -> Dictionary:
	return {
		"punch": {
			"name": "Punch",
			"cost": 1,
			"effects": [{"type": "damage", "amount": 5, "target": "selected"}],
		},
		"block": {
			"name": "Block",
			"cost": 1,
			"effects": [{"type": "block", "amount": 7}],
		},
		"hack": {
			"name": "Scrap Hack",
			"cost": 1,
			"effects": [
				{"type": "damage", "amount": 3, "target": "selected"},
				{"type": "apply_status", "status": "hacked", "duration": 2, "target": "selected"},
			],
		},
	}


static func augments() -> Array:
	return [
		{
			"name": "Jury-Rigged Exo-Arm",
			"slot": "Arm",
			"rarity": "Common",
			"archetype": "Meatbag",
			"brand": "Riskrunner",
			"extra": "At less than 50% HP, deal +10% damage.",
			"softcap": 0,
			"passives": [
				{"trigger": "damage", "effects": [{"type": "damage_bonus_percent", "amount": 10, "condition": {"actor_hp_below": 50}}]},
			],
			"abilities": [
				_ability("Scrap Bash", 1, 1, [
					{"type": "damage", "amount": 10, "target": "selected"},
					{"type": "damage", "amount": 5, "target": "selected", "condition": {"actor_hp_below": 50}},
				]),
				_ability("Welded Guard", 1, 2, [
					{"type": "block", "amount": 12},
					{"type": "self_damage", "amount": 3},
				]),
			],
		},
		{
			"name": "Rusted Sidearm",
			"slot": "Arm",
			"rarity": "Common",
			"archetype": "Meatbag",
			"brand": "Riskrunner",
			"extra": "Deal +10% damage while below 50% HP.",
			"softcap": 0,
			"passives": [
				{"trigger": "damage", "effects": [{"type": "damage_bonus_percent", "amount": 10, "condition": {"actor_hp_below": 50}}]},
			],
			"abilities": [
				_ability("Last Shot", 1, 1, [
					{"type": "damage", "amount": 10, "target": "selected"},
					{"type": "damage", "amount": 5, "target": "selected", "condition": {"actor_hp_below": 50}},
				]),
				_ability("Desperate Reload", 0, 3, [
					{"type": "focus", "amount": 1, "timing": "next_turn"},
					{"type": "self_damage", "amount": 5},
				]),
			],
		},
		{
			"name": "Jury-Rigged Exosleeve",
			"slot": "Torso",
			"rarity": "Common",
			"archetype": "Meatbag",
			"brand": "Riskrunner",
			"extra": "+5 Max HP.",
			"max_hp_bonus": 5,
			"softcap": 0,
			"abilities": [
				_ability("Adrenal Surge", 1, 3, [
					{"type": "damage_buff", "amount": 25, "duration": 2},
					{"type": "self_damage", "amount": 5},
				]),
				_ability("Patchwork Guard", 0, 2, [{"type": "block", "amount": 8}]),
			],
		},
		{
			"name": "Burnout Goggles",
			"slot": "Head",
			"rarity": "Common",
			"archetype": "Meatbag",
			"brand": "Riskrunner",
			"extra": "+5% critical chance below 50% HP.",
			"softcap": 0,
			"abilities": [
				_ability("Clarity Under Fire", 0, 3, [
					{"type": "focus", "amount": 1, "duration": 2, "condition": {"actor_hp_below": 50}},
				]),
				_ability("Bloodshot Glare", 1, 2, [
					{"type": "damage", "amount": 6, "target": "all"},
					{"type": "self_damage", "amount": 4},
				]),
			],
		},
		{
			"name": "Rusted Runner Boots",
			"slot": "Legs",
			"rarity": "Rare",
			"archetype": "Meatbag",
			"brand": "Riskrunner",
			"extra": "+10% damage while below 50% HP.",
			"softcap": 0,
			"passives": [
				{"trigger": "damage", "effects": [{"type": "damage_bonus_percent", "amount": 10, "condition": {"actor_hp_below": 50}}]},
			],
			"abilities": [
				_ability("Blood Rush", 0, 3, [
					{"type": "focus", "amount": 2, "timing": "next_turn"},
					{"type": "self_damage", "amount": 8},
				]),
				_ability("Charge Kick", 1, 1, [
					{"type": "damage", "amount": 12, "target": "selected"},
					{"type": "block", "amount": 5, "condition": {"actor_hp_below": 50}},
				]),
			],
		},
		{
			"name": "Iron Will Plating",
			"slot": "Torso",
			"rarity": "Uncommon",
			"archetype": "Meatbag",
			"brand": "Meatpurist",
			"extra": "+4 Max HP.",
			"max_hp_bonus": 4,
			"softcap": 0,
			"abilities": [
				_ability("Grit Bash", 1, 1, [
					{"type": "damage", "amount": 7, "target": "selected"},
					{"type": "block", "amount": 4},
				]),
				_ability("Fortify", 1, 2, [{"type": "block", "amount": 12}]),
				_ability("Unbreakable Stance", 2, 4, [
					{"type": "block", "amount": 20},
					{"type": "apply_status", "operation": "remove_all_debuffs"},
				], {"herculean": true, "requires_max_hp_percent": 20}),
			],
		},
		{
			"name": "Pulse-Bound Gauntlet",
			"slot": "Arm",
			"rarity": "Uncommon",
			"archetype": "Meatbag",
			"brand": "Meatpurist",
			"extra": "+3 Max HP.",
			"max_hp_bonus": 3,
			"softcap": 0,
			"abilities": [
				_ability("Meat Hook", 1, 1, [
					{"type": "damage", "amount": 8, "target": "selected"},
					{"type": "heal", "amount": 4, "condition": {"target_hp_below": 50, "before_action": true}},
				]),
				_ability("Guard Breaker", 1, 2, [
					{"type": "damage", "amount": 10, "target": "selected", "block_pierce_percent": 50},
				]),
				_ability("Crushing Resolve", 2, 4, [
					{"type": "damage", "amount": 15, "target": "selected"},
					{"type": "heal", "amount": 10, "mode": "max_hp_percent"},
				], {"herculean": true, "requires_max_hp_percent": 20}),
			],
		},
		{
			"name": "Juggernaut Greaves",
			"slot": "Legs",
			"rarity": "Uncommon",
			"archetype": "Meatbag",
			"brand": "Meatpurist",
			"extra": "+3 Max HP.",
			"max_hp_bonus": 3,
			"softcap": 0,
			"abilities": [
				_ability("Stomp", 1, 1, [{"type": "damage", "amount": 6, "target": "all"}]),
				_ability("Brace for Impact", 0, 2, [{"type": "block", "amount": 8}]),
				_ability("March of Flesh", 2, 5, [
					{"type": "damage", "amount": 10, "target": "all"},
					{"type": "block", "amount": 10},
				], {"herculean": true, "requires_max_hp_percent": 20}),
			],
		},
		{
			"name": "Jury-Rigged Signal Jammer",
			"slot": "Head",
			"rarity": "Common",
			"archetype": "Meatbag",
			"brand": "Netrunner",
			"extra": "First Hacked application each combat grants 5 Block.",
			"softcap": 4,
			"passives": [
				{"trigger": "first_hack", "effects": [{"type": "block", "amount": 5}]},
			],
			"abilities": [
				_ability("Pulse Scramble", 1, 2, [
					{"type": "damage", "amount": 6, "target": "selected"},
					{"type": "apply_status", "status": "hacked", "duration": 2, "target": "selected"},
				]),
				_ability("Manual Override", 0, 3, [
					{"type": "focus", "amount": 1, "timing": "next_turn"},
					{"type": "self_damage", "amount": 5},
				]),
			],
		},
		{
			"name": "Rusted Data Spike",
			"slot": "Arm",
			"rarity": "Common",
			"archetype": "Meatbag",
			"brand": "Netrunner",
			"extra": "+10% damage vs Hacked targets.",
			"softcap": 5,
			"passives": [
				{"trigger": "damage", "effects": [{"type": "damage_bonus_percent", "amount": 10, "condition": {"target_status": "hacked"}}]},
			],
			"abilities": [
				_ability("Data Puncture", 1, 1, [
					{"type": "damage", "amount": 8, "target": "selected"},
					{"type": "apply_status", "status": "hacked", "duration": 1, "target": "selected"},
				]),
				_ability("Rust Reverb", 1, 3, [
					{"type": "damage", "amount": 10, "target": "selected"},
					{"type": "damage", "amount": 5, "target": "selected", "condition": {"target_status": "hacked"}},
				]),
			],
		},
		{
			"name": "Scrap Signal Router",
			"slot": "Torso",
			"rarity": "Uncommon",
			"archetype": "Meatbag",
			"brand": "Netrunner",
			"extra": "Start combat by applying Hacked to a random enemy.",
			"softcap": 3,
			"passives": [
				{"trigger": "combat_start", "effects": [{"type": "apply_status", "status": "hacked", "duration": 1, "target": "random_enemy"}]},
			],
			"abilities": [
				_ability("Router Surge", 0, 4, [
					{"type": "apply_status", "status": "hacked", "duration": 1, "target": "all"},
				]),
				_ability("Echo Shield", 1, 3, [
					{"type": "block", "amount": 12, "bonus_if_hacked": 6},
				]),
			],
		},
		{
			"name": "Blackout Harness",
			"slot": "Torso",
			"rarity": "Rare",
			"archetype": "Meatbag",
			"brand": "Netrunner",
			"extra": "Signal Blackout deals 10 bonus damage to enemies that are already Hacked.",
			"softcap": 6,
			"abilities": [
				_ability("Flash Overload", 1, 3, [
					{"type": "damage", "amount": 10, "target": "selected"},
					{"type": "apply_status", "status": "hacked", "duration": 2, "target": "selected"},
				]),
				_ability("Feedback Barrier", 1, 3, [
					{"type": "block", "amount": 15},
					{"type": "heal", "amount": 5, "condition": {"actor_hp_below": 50}},
				]),
				_ability("Signal Blackout", 2, 5, [
					{"type": "damage", "amount": 20, "target": "all", "bonus_if_target_status": {"status": "hacked", "amount": 10}},
					{"type": "apply_status", "status": "hacked", "duration": 2, "target": "all"},
				], {"overdrive": true}),
			],
		},
		{
			"name": "Chrome Spine Stabilizer",
			"slot": "Torso",
			"rarity": "Uncommon",
			"archetype": "Meatbag",
			"brand": "Chrome Titan",
			"extra": "Start combat with 5 Block.",
			"softcap": 5,
			"passives": [
				{"trigger": "combat_start", "effects": [{"type": "block", "amount": 0, "block_per_chrome_augment": 5}]},
			],
			"abilities": [
				_ability("Reflex Clamp", 1, 3, [
					{"type": "block", "amount": 15, "bonus_if_high_hp": 10},
				]),
				_ability("Adrenal Surge", 0, 4, [
					{"type": "heal", "amount": 10, "mode": "missing_hp_percent"},
					{"type": "damage_buff", "amount": 15, "duration": 2},
				]),
			],
		},
		{
			"name": "Meat Crown Implant",
			"slot": "Head",
			"rarity": "Rare",
			"archetype": "Meatbag",
			"brand": "Meatpurist",
			"extra": "+5 Max HP.",
			"max_hp_bonus": 5,
			"softcap": 0,
			"abilities": [
				_ability("Battle Focus", 0, 3, [{"type": "damage_buff", "amount": 25, "duration": 2}]),
				_ability("Shout of Defiance", 1, 3, [{"type": "block", "amount": 5}]),
				_ability("Titan's Roar", 2, 5, [
					{"type": "block", "amount": 20},
					{"type": "damage_buff", "amount": 25, "duration": 2},
					{"type": "apply_status", "operation": "remove_all_debuffs"},
				], {"herculean": true, "requires_max_hp_percent": 20}),
			],
		},
	]


static func _ability(ability_name: String, focus_cost: int, cooldown: int, effect_list: Array, metadata: Dictionary = {}) -> Dictionary:
	var ability := {
		"name": ability_name,
		"cost": focus_cost,
		"cooldown": cooldown,
		"effects": effect_list,
	}
	ability.merge(metadata, true)
	return ability


static func consumables() -> Array:
	return [
		_consumable("Nanite Injection Vial", "Common", "Neutral", "Heal 15% Max HP; remove 1 random debuff.", [
			{"type": "heal", "amount": 15, "mode": "max_hp_percent"},
			{"type": "apply_status", "operation": "remove_random_debuff"},
		]),
		_consumable("Rust Grenade", "Common", "Meatbag", "Deal 12 to all; Hacked Chrome enemies for 1 turn.", [
			{"type": "damage", "amount": 12, "target": "all"},
			{"type": "apply_status", "status": "hacked", "duration": 1, "target": "all", "chrome_only": true},
		]),
		_consumable("Stabilizing Brew", "Common", "Neutral", "Remove 1 debuff and gain +10 Block.", [
			{"type": "apply_status", "operation": "remove_random_debuff"},
			{"type": "block", "amount": 10},
		]),
		_consumable("Overcharge Capsule", "Common", "Chrome Titan", "Reduce all active ability cooldowns by 1; take 4 self-damage.", [
			{"type": "reduce_all_cooldowns", "amount": 1},
			{"type": "self_damage", "amount": 4},
		]),
		_consumable("Data Spike", "Common", "Netrunner", "Deal 8 Hack damage and apply Hacked for 1 turn.", [
			{"type": "damage", "amount": 8, "target": "selected"},
			{"type": "apply_status", "status": "hacked", "duration": 1, "target": "selected"},
		]),
		_consumable("Improvised Adrenaline", "Uncommon", "Meatbag", "Gain +2 Focus immediately; take 5 damage at turn end.", [
			{"type": "focus", "amount": 2, "timing": "immediate"},
			{"type": "turn_end_damage", "amount": 5},
		]),
		_consumable("Nanite Cloud Dispersal", "Uncommon", "Neutral", "Apply Hacked to all enemies; each has a 25% chance to resist.", [
			{"type": "apply_status", "status": "hacked", "duration": 1, "target": "all", "resist_chance": 25},
		]),
		_consumable("Shock Lattice Emitter", "Uncommon", "Chrome Titan / Netrunner", "Deal 15 damage; deal another 15 if target is Hacked.", [
			{"type": "damage", "amount": 15, "target": "selected", "multiplier_if": {"condition": {"target_status": "hacked"}, "multiplier": 2}},
		]),
		_consumable("Jury-Rigged Med Patch", "Uncommon", "Meatbag", "Heal 25% Max HP and gain 1 Corruption.", [
			{"type": "heal", "amount": 25, "mode": "max_hp_percent"},
			{"type": "corruption", "amount": 1},
		]),
		_consumable("Chrome Overclock Injector", "Rare", "Chrome Titan", "Reset all active cooldowns; gain 1 temporary Corruption.", [
			{"type": "reset_all_cooldowns"},
			{"type": "corruption", "amount": 1},
		]),
		_consumable("Ghostwave Beacon", "Rare", "Netrunner", "Summon a drone for 3 turns; it deals 8 damage at turn end.", [
			{"type": "deploy_drone", "damage": 8, "duration": 3},
		]),
		_consumable("Alchemical Singularity", "Rare", "Meatbag", "Refresh used consumables once; gain a random debuff.", [
			{"type": "refresh_used_consumables"},
			{"type": "apply_status", "operation": "random_debuff"},
		]),
	]


static func _consumable(item_name: String, item_rarity: String, item_archetype: String, item_description: String, item_effects: Array) -> Dictionary:
	return {
		"name": item_name,
		"rarity": item_rarity,
		"archetype": item_archetype,
		"description": item_description,
		"effects": item_effects,
	}


static func boss_pool() -> Array:
	return [
		{"name": "Matron of the Crown", "type": "boss_matron", "hp": 240, "damage": 14, "weight": 24, "color": Color("#e0c47c")},
		{"name": "Choir of Parasites", "type": "boss_choir", "hp": 160, "damage": 10, "weight": 21, "color": Color("#bb82d5")},
		{"name": "The Concierge Revenant", "type": "boss_concierge", "hp": 260, "damage": 10, "weight": 20, "color": Color("#8ab4c9")},
		{"name": "Chrome-Rotted Challenger", "type": "boss_challenger", "hp": 200, "damage": 14, "weight": 18, "color": Color("#cb6b5b")},
		{"name": "Mycelial Host", "type": "boss_mycelial", "hp": 195, "damage": 11, "weight": 17, "color": Color("#81ad79")},
	]


static func random_consumable(rng: RandomNumberGenerator) -> Dictionary:
	var pool := consumables()
	var rarity_roll := rng.randi_range(1, 100)
	var desired_rarity := "Common" if rarity_roll <= 60 else ("Uncommon" if rarity_roll <= 90 else "Rare")
	var rarity_pool: Array = []
	for item in pool:
		if item["rarity"] == desired_rarity:
			rarity_pool.append(item)
	var selected: Dictionary = rarity_pool[rng.randi_range(0, rarity_pool.size() - 1)]
	return selected.duplicate(true)


static func random_augment(rng: RandomNumberGenerator, excluded_names: Array = []) -> Dictionary:
	var pool := augments()
	var available: Array = []
	for item in pool:
		if not excluded_names.has(item["name"]):
			available.append(item)
	if available.is_empty():
		available = pool
	var rarity_roll := rng.randi_range(1, 100)
	var desired_rarity := "Common" if rarity_roll <= 60 else ("Uncommon" if rarity_roll <= 90 else "Rare")
	var rarity_pool: Array = []
	for item in available:
		if item["rarity"] == desired_rarity:
			rarity_pool.append(item)
	if rarity_pool.is_empty():
		rarity_pool = available
	var selected: Dictionary = rarity_pool[rng.randi_range(0, rarity_pool.size() - 1)]
	return selected.duplicate(true)


static func weighted_boss(rng: RandomNumberGenerator) -> Dictionary:
	var pool := boss_pool()
	var total_weight := 0
	for boss in pool:
		total_weight += int(boss["weight"])
	var roll := rng.randi_range(1, total_weight)
	for boss in pool:
		roll -= int(boss["weight"])
		if roll <= 0:
			return boss.duplicate(true)
	return pool[0].duplicate(true)
