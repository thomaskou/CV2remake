extends Node


################################################################################
# Variables
################################################################################

# UI flags
export onready var pause_menu: bool = false
export onready var map_screen: bool = false

# Upgrade flags/variables
export var has_djumps: bool
export var has_slide: bool
export var numjumps: int setget ,get_numjumps

# Main stats
export var hp: int setget set_hp
export var mp: int setget set_mp
export var xp: int setget set_xp
export var gold: int
export var status: int
export var max_rp: int

# Derived stats
export var level: int
export var max_hp: int
export var max_mp: int
export var atk: int setget ,get_atk
export var def: int setget ,get_def

# Other stats
export var stat_str: int setget ,get_str
export var stat_con: int setget ,get_con
export var stat_int: int setget ,get_int
export var stat_mnd: int setget ,get_mnd
export var stat_lck: int setget ,get_lck

# Other stat increases
var plus_hp_max: int
var plus_mp_max: int
var plus_str: int
var plus_con: int
var plus_int: int
var plus_mnd: int
var plus_lck: int

# Equipped items
export var equip_relics: Array
export var equip_weapon: String
export var equip_subwep: String
export var equip_armor: String
export var equip_spell: String

# Inventory
export var inv_relics: Array
export var inv_weapons: Array
export var inv_subweps: Array
export var inv_armor: Array
export var inv_spells: Array
export var inv_items: Array


################################################################################
# Ready
################################################################################

func _ready():
	load_default_save()
	update_has_djumps()
	update_has_slide()


################################################################################
# Saves
################################################################################

func load_default_save() -> void:
	var file: File = File.new()
	file.open("res://src/data/default_save.json", File.READ)
	var json: Dictionary = JSON.parse(file.get_as_text()).result
	
	hp = json["stats"]["hp"]
	mp = json["stats"]["mp"]
	xp = json["stats"]["xp"]
	gold = json["stats"]["gold"]
	status = json["stats"]["status"]
	max_rp = json["stats"]["max_rp"]
	
	plus_hp_max = json["stats"]["+hp_max"]
	plus_mp_max = json["stats"]["+mp_max"]
	plus_str = json["stats"]["+str"]
	plus_con = json["stats"]["+con"]
	plus_int = json["stats"]["+int"]
	plus_mnd = json["stats"]["+mnd"]
	plus_lck = json["stats"]["+lck"]
	
	equip_relics = json["equipped"]["relics"]
	equip_weapon = json["equipped"]["weapon"]
	equip_subwep = json["equipped"]["subwep"]
	equip_armor = json["equipped"]["armor"]
	equip_spell = json["equipped"]["spell"]
	
	inv_relics = json["inventory"]["relics"]
	inv_weapons = json["inventory"]["weapons"]
	inv_subweps = json["inventory"]["subweps"]
	inv_armor = json["inventory"]["armor"]
	inv_spells = json["inventory"]["spells"]
	inv_items = json["inventory"]["items"]
	
	file.close()


################################################################################
# Upgrade flag/variable accessors
################################################################################

func update_has_djumps() -> void:
	has_djumps = "u_djump" in equip_relics

func update_has_slide() -> void:
	has_slide = "u_slide" in equip_relics

func get_numjumps() -> int:
	return 2 if has_djumps else 1


################################################################################
# Stat mutators
################################################################################

func set_hp(value: int) -> void:
	hp = int(clamp(value, 0, max_hp))

func set_mp(value: int) -> void:
	mp = int(clamp(value, 0, max_mp))

func set_xp(value: int) -> void:
	xp = value
	update_level()

func update_level() -> void:
	if xp < 10:
		level = 1
	else:
		var factor: float = 9*sqrt(3*(xp*(243*xp+40)-4))-243*xp-20
		level = int(floor(-1*(pow(factor/2,1/3)-7*pow(2/factor,1/3)-5)/9))


################################################################################
# Stat accessors
################################################################################

func get_atk() -> int:
	return int(floor(stat_str/2.0))

func get_def() -> int:
	return int(floor(stat_con/2.0))

func get_str() -> int:
	return int(round(0.7*level)) + plus_str + 5

func get_con() -> int:
	return int(round(0.5*level)) + plus_con + 4

func get_int() -> int:
	return int(round(0.6*level)) + plus_int + 5

func get_mnd() -> int:
	return int(round(0.4*level)) + plus_mnd + 3

func get_lck() -> int:
	return int(round(0.3*level)) + plus_lck + 2