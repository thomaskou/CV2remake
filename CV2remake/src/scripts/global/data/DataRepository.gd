extends Node

export var DataEnums: Dictionary
export var DataTextures: Dictionary
export var DataLevels: Array

export var TemplateWeapons: Dictionary

export var InvArmor: Dictionary
export var InvItems: Dictionary
export var InvRelics: Dictionary
export var InvSpells: Dictionary
export var InvSubweps: Dictionary
export var InvWeapons: Dictionary


func _ready():
	var file: File = File.new()
	
	file.open("res://src/data/data_enums.json", File.READ)
	DataEnums = JSON.parse(file.get_as_text()).result
	file.close()
	
	file.open("res://src/data/data_textures.json", File.READ)
	DataTextures = JSON.parse(file.get_as_text()).result
	file.close()
	
	file.open("res://src/data/data_levels.json", File.READ)
	DataLevels = JSON.parse(file.get_as_text()).result
	file.close()
	
	file.open("res://src/data/template_weapons.json", File.READ)
	TemplateWeapons = JSON.parse(file.get_as_text()).result
	file.close()
	
	file.open("res://src/data/inv_armor.json", File.READ)
	InvArmor = JSON.parse(file.get_as_text()).result
	for name in InvArmor:
		var item: Dictionary = InvArmor[name]
		deep_copy_properties(item, InvArmor["_default"])
	file.close()
	
	file.open("res://src/data/inv_items.json", File.READ)
	InvItems = JSON.parse(file.get_as_text()).result
	for name in InvItems:
		var item: Dictionary = InvItems[name]
		deep_copy_properties(item, InvItems["_default"])
	file.close()
	
	file.open("res://src/data/inv_relics.json", File.READ)
	InvRelics = JSON.parse(file.get_as_text()).result
	for name in InvRelics:
		var item: Dictionary = InvRelics[name]
		deep_copy_properties(item, InvRelics["_default"])
	file.close()
	
	file.open("res://src/data/inv_spells.json", File.READ)
	InvSpells = JSON.parse(file.get_as_text()).result
	for name in InvSpells:
		var item: Dictionary = InvSpells[name]
		deep_copy_properties(item, InvSpells["_default"])
	file.close()
	
	file.open("res://src/data/inv_subweps.json", File.READ)
	InvSubweps = JSON.parse(file.get_as_text()).result
	for name in InvSubweps:
		var item: Dictionary = InvSubweps[name]
		deep_copy_properties(item, InvSubweps["_default"])
	file.close()
	
	file.open("res://src/data/inv_weapons.json", File.READ)
	InvWeapons = JSON.parse(file.get_as_text()).result
	for name in InvWeapons:
		var item: Dictionary = InvWeapons[name]
		deep_copy_properties(item, InvWeapons["_default"])
		generate_weapon_sprite_data(item)
	file.close()


func deep_copy_properties(to: Dictionary, from: Dictionary, force: bool = false) -> Dictionary:
	for property in from:
		if from[property] is Dictionary:
			to[property] = deep_copy_properties(to[property] if to.has(property) else Dictionary(), from[property], force)
		elif force or !to.has(property):
			to[property] = from[property]
	return to


func generate_weapon_sprite_data(weapon: Dictionary) -> void:
	# Load from template
	if weapon.has("template") and TemplateWeapons.has(weapon["template"]):
		deep_copy_properties(weapon, TemplateWeapons[weapon["template"]], true)
	
	# Fields to add to the weapon data
	var total_frames: int = 0
	var total_sprites: int = 0
	var frame_to_sprite: Array = []
	var frame_to_portion: Array = []
	
	# Iterate through all animation portions in the current weapon
	for portion_index in weapon["sprite"]["frames"].size():
		
		# Get frame data for the current animation portion
		# Set each portion's cumulative time, sprite index, and portion time
		var portion: Dictionary = weapon["sprite"]["frames"][portion_index]
		portion["cumulative_time"] = total_frames
		portion["cumulative_sprites"] = total_sprites
		if !portion.has("time"):
			var portion_time: int = 0
			for time_sprite in portion["time_sprite"]: portion_time += time_sprite
			portion["time"] = portion_time
		
		# Point frame->sprite and frame->portion maps
		var helper_index: int = -1
		var helper_increment: int = 0
		for frame in range(portion["time"]):
			if helper_increment == 0:
				helper_index = (helper_index + 1) % portion["time_sprite"].size()
				helper_increment = portion["time_sprite"][helper_index]
			helper_increment -= 1
			if portion.has("images"):
				frame_to_sprite.append(portion["images"][helper_index])
			else:
				frame_to_sprite.append(total_sprites + helper_index)
			frame_to_portion.append(portion_index)
		
		# Increase cumulative time & sprite index
		total_frames += portion["time"]
		total_sprites += portion["time_sprite"].size()
	
	# Add fields to the weapon data
	weapon["sprite"]["total_frames"] = total_frames
	weapon["sprite"]["frame_to_sprite"] = frame_to_sprite
	weapon["sprite"]["frame_to_portion"] = frame_to_portion
