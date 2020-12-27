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
	file.close()
	
	file.open("res://src/data/inv_items.json", File.READ)
	InvItems = JSON.parse(file.get_as_text()).result
	file.close()
	
	file.open("res://src/data/inv_relics.json", File.READ)
	InvRelics = JSON.parse(file.get_as_text()).result
	file.close()
	
	file.open("res://src/data/inv_spells.json", File.READ)
	InvSpells = JSON.parse(file.get_as_text()).result
	file.close()
	
	file.open("res://src/data/inv_subweps.json", File.READ)
	InvSubweps = JSON.parse(file.get_as_text()).result
	file.close()
	
	file.open("res://src/data/inv_weapons.json", File.READ)
	InvWeapons = JSON.parse(file.get_as_text()).result
	file.close()
