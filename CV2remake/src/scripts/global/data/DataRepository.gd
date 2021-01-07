extends Node

export var DataEnums: Dictionary
export var DataTextures: Dictionary
export var DataLevels: Array

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
	
	file.open("res://src/data/inv_armor.json", File.READ)
	InvArmor = JSON.parse(file.get_as_text()).result
	for name in InvArmor:
		var item: Dictionary = InvArmor[name]
		item["stats"] = create_default_stats(item["stats"]) if item.has("stats") else create_default_stats(Dictionary())
		for property in InvArmor["_default"]:
			if !item.has(property):
				item[property] = InvArmor["_default"][property]
	file.close()
	
	file.open("res://src/data/inv_items.json", File.READ)
	InvItems = JSON.parse(file.get_as_text()).result
	for name in InvItems:
		var item: Dictionary = InvItems[name]
		item["stats"] = create_default_stats(item["stats"]) if item.has("stats") else create_default_stats(Dictionary())
		for property in InvItems["_default"]:
			if !item.has(property):
				item[property] = InvItems["_default"][property]
	file.close()
	
	file.open("res://src/data/inv_relics.json", File.READ)
	InvRelics = JSON.parse(file.get_as_text()).result
	for name in InvRelics:
		var item: Dictionary = InvRelics[name]
		for property in InvRelics["_default"]:
			if !item.has(property):
				item[property] = InvRelics["_default"][property]
	file.close()
	
	file.open("res://src/data/inv_spells.json", File.READ)
	InvSpells = JSON.parse(file.get_as_text()).result
	for name in InvSpells:
		var item: Dictionary = InvSpells[name]
		item["stats"] = create_default_stats(item["stats"]) if item.has("stats") else create_default_stats(Dictionary())
		for property in InvSpells["_default"]:
			if !item.has(property):
				item[property] = InvSpells["_default"][property]
	file.close()
	
	file.open("res://src/data/inv_subweps.json", File.READ)
	InvSubweps = JSON.parse(file.get_as_text()).result
	for name in InvSubweps:
		var item: Dictionary = InvSubweps[name]
		item["stats"] = create_default_stats(item["stats"]) if item.has("stats") else create_default_stats(Dictionary())
		for property in InvSubweps["_default"]:
			if !item.has(property):
				item[property] = InvSubweps["_default"][property]
	file.close()
	
	file.open("res://src/data/inv_weapons.json", File.READ)
	InvWeapons = JSON.parse(file.get_as_text()).result
	for name in InvWeapons:
		var item: Dictionary = InvWeapons[name]
		item["stats"] = create_default_stats(item["stats"]) if item.has("stats") else create_default_stats(Dictionary())
		for property in InvWeapons["_default"]:
			if !item.has(property):
				item[property] = InvWeapons["_default"][property]
		generate_weapon_sprite_data(item)
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


func generate_weapon_sprite_data(weapon: Dictionary) -> void:
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
	if weapon["sprite"].has("effects"):
		weapon["sprite"]["effects"] = create_default_weapon_sprite_effects(weapon["sprite"]["effects"])
	else:
		weapon["sprite"]["effects"] = create_default_weapon_sprite_effects(Dictionary())


func create_default_weapon_sprite_effects(effects: Dictionary) -> Dictionary:
	if !effects.has("ghost_frames"): effects["ghost_frames"] = -1
	return effects
