extends RefCounted

const PATH_TEMPLATES := [
	{
		"first_to_middle": [[0, 1], [1, 2]],
		"middle_to_late": [[0], [0, 1], [1]],
	},
	{
		"first_to_middle": [[0], [1, 2]],
		"middle_to_late": [[0, 1], [1], [1]],
	},
	{
		"first_to_middle": [[0, 1], [2]],
		"middle_to_late": [[0], [0, 1], [1]],
	},
]


static func generate(rng: RandomNumberGenerator, boss: Dictionary) -> Dictionary:
	var regular_encounters := [1, 3]
	_shuffle(regular_encounters, rng)
	var middle_choices: Array[Dictionary] = [
		_make_node("combat", "Cracked Promenade", regular_encounters[1]),
		_make_node("elite", "Chrome Butler", 2),
		_make_node("shop", "Rogue AI Trader"),
	]
	_shuffle(middle_choices, rng)
	var first_branch: Array[Dictionary] = [
		_make_node("combat", "Resort Service Hall", regular_encounters[0]),
		_make_node("event", "Fractured Hallway"),
	]
	_shuffle(first_branch, rng)
	var late_branch: Array[Dictionary] = [
		_make_node("combat", "Collapsed Bathhouse", regular_encounters[0]),
		_make_node("event", "Echoing Guest Wing"),
	]
	_shuffle(late_branch, rng)

	var rows: Array = [
		[_make_node("combat", "Luxury Checkpoint", 0)],
		first_branch,
		middle_choices,
		late_branch,
		[_make_node("rest", "Broken Reception")],
		[_make_node("boss", String(boss.get("name", "Floor Boss")))],
	]
	var layout_index := rng.randi_range(0, PATH_TEMPLATES.size() - 1)
	var path_template: Dictionary = PATH_TEMPLATES[layout_index]
	var node_by_id: Dictionary = {}
	for row_index in range(rows.size()):
		var row_nodes: Array = rows[row_index]
		for column in range(row_nodes.size()):
			var node: Dictionary = row_nodes[column]
			node["row"] = row_index
			node["column"] = column
			node["id"] = "r%dn%d" % [row_index, column]
			row_nodes[column] = node
			node_by_id[node["id"]] = node
	for row_index in range(rows.size() - 1):
		var current_row: Array = rows[row_index]
		var next_row: Array = rows[row_index + 1]
		for node_index in range(current_row.size()):
			var destinations: Array = []
			match row_index:
				0:
					for next_index in range(next_row.size()):
						destinations.append(next_index)
				1:
					destinations = path_template["first_to_middle"][node_index]
				2:
					destinations = path_template["middle_to_late"][node_index]
				_:
					for next_index in range(next_row.size()):
						destinations.append(next_index)
			var connections: Array[String] = []
			for next_index in destinations:
				connections.append(String(next_row[int(next_index)]["id"]))
			current_row[node_index]["connections"] = connections

	return {
		"floor": 1,
		"layout_id": layout_index,
		"rows": rows,
		"nodes": node_by_id,
		"start_id": String(rows[0][0]["id"]),
	}


static func _make_node(node_type: String, title: String, encounter_index: int = -1) -> Dictionary:
	return {
		"id": "",
		"type": node_type,
		"title": title,
		"row": -1,
		"column": 0,
		"encounter_index": encounter_index,
		"connections": [],
	}


static func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var other_index := rng.randi_range(0, index)
		var value: Variant = values[index]
		values[index] = values[other_index]
		values[other_index] = value
