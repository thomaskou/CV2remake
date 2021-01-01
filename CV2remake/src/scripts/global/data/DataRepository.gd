extends Node

export var Enums: Dictionary

export var DataLevels: Array

export var InvArmor: Dictionary
export var InvItems: Dictionary
export var InvRelics: Dictionary
export var InvSpells: Dictionary
export var InvSubweps: Dictionary
export var InvWeapons: Dictionary

func _ready():
	var file: File = File.new()
	
	file.open("res://src/data/enums.json", File.READ)
	Enums = JSON.parse(file.get_as_text()).result
	file.close()
	
	file.open("res://src/data/data_levels.json", File.READ)
	DataLevels = JSON.parse(file.get_as_text()).result
	file.close()
	
	file.open("res://src/data/inv_armor.json", File.READ)
	InvArmor = JSON.parse(file.get_as_text()).result
	for name in InvArmor:
		var item: Dictionary = InvArmor[name]
		item["stats"] = create_default_stats(item["stats"]) if item.has("stats") else create_default_stats(Dictionary())
		for property in InvArmor["default"]:
			if !item.has(property):
				item[property] = InvArmor["default"][property]
	file.close()
	
	file.open("res://src/data/inv_items.json", File.READ)
	InvItems = JSON.parse(file.get_as_text()).result
	for name in InvItems:
		var item: Dictionary = InvItems[name]
		item["stats"] = create_default_stats(item["stats"]) if item.has("stats") else create_default_stats(Dictionary())
		for property in InvItems["default"]:
			if !item.has(property):
				item[property] = InvItems["default"][property]
	file.close()
	
	file.open("res://src/data/inv_relics.json", File.READ)
	InvRelics = JSON.parse(file.get_as_text()).result
	for name in InvRelics:
		var item: Dictionary = InvRelics[name]
		for property in InvRelics["default"]:
			if !item.has(property):
				item[property] = InvRelics["default"][property]
	file.close()
	
	file.open("res://src/data/inv_spells.json", File.READ)
	InvSpells = JSON.parse(file.get_as_text()).result
	for name in InvSpells:
		var item: Dictionary = InvSpells[name]
		for property in InvSpells["default"]:
			if !item.has(property):
				item[property] = InvSpells["default"][property]
	file.close()
	
	file.open("res://src/data/inv_subweps.json", File.READ)
	InvSubweps = JSON.parse(file.get_as_text()).result
	for name in InvSubweps:
		var item: Dictionary = InvSubweps[name]
		for property in InvSubweps["default"]:
			if !item.has(property):
				item[property] = InvSubweps["default"][property]
	file.close()
	
	file.open("res://src/data/inv_weapons.json", File.READ)
	InvWeapons = JSON.parse(file.get_as_text()).result
	for name in InvWeapons:
		var item: Dictionary = InvWeapons[name]
		item["stats"] = create_default_stats(item["stats"]) if item.has("stats") else create_default_stats(Dictionary())
		for property in InvWeapons["default"]:
			if !item.has(property):
				item[property] = InvWeapons["default"][property]
	file.close()

func create_default_stats(stats: Dictionary) -> Dictionary:
	if !stats.has("atk"): stats["atk"] = 0
	if !stats.has("def"): stats["def"] = 0
	if !stats.has("str"): stats["str"] = 0
	if !stats.has("con"): stats["con"] = 0
	if !stats.has("int"): stats["int"] = 0
	if !stats.has("mnd"): stats["mnd"] = 0
	if !stats.has("lck"): stats["lck"] = 0
	return stats
