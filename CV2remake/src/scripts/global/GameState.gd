extends Node


################################################################################
# Constants
################################################################################

const BASE_HP: int = 128
const BASE_MP: int = 80

const BASE_STR: int = 5
const BASE_CON: int = 4
const BASE_INT: int = 5
const BASE_MND: int = 3
const BASE_LCK: int = 2

const HP_PER_LEVEL: int = 8
const MP_PER_LEVEL: int = 6
const HP_PER_PLUS: int = 20
const MP_PER_PLUS: int = 10
const STR_PER_LEVEL: float = 0.7
const CON_PER_LEVEL: float = 0.5
const INT_PER_LEVEL: float = 0.6
const MND_PER_LEVEL: float = 0.4
const LCK_PER_LEVEL: float = 0.3

const MAX_LEVEL: int = 99


################################################################################
# Variables
################################################################################

onready var DataRepository: Node = get_node("/root/Main/DataRepository")

# Game flags
export var debug_mode: bool

# UI flags
export onready var pause_menu: bool = false setget set_pause_menu
export onready var map_screen: bool = false setget set_map_screen
export onready var room_transitioning: bool = false setget set_room_transitioning
export onready var area_transitioning: bool = false setget set_area_transitioning

# Upgrade flags/variables
export var has_djumps: bool
export var has_slide: bool
export var numjumps: int setget ,get_numjumps

# Main stats
export var xp: int setget set_xp
export var hp: int setget set_hp
export var mp: int setget set_mp
export var gold: int
export var status: int
export var max_rp: int

# Derived stats
export var level: int
export var xp_for_this_level: int
export var xp_for_next_level: int
export var max_hp: int setget ,get_max_hp
export var max_mp: int setget ,get_max_mp
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
export var inv_relics: Dictionary
export var inv_weapons: Dictionary
export var inv_subweps: Dictionary
export var inv_armor: Dictionary
export var inv_spells: Dictionary
export var inv_items: Dictionary


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
	
	debug_mode = json["debug"]["debug_mode"]
	
	set_xp(json["stats"]["xp"])
	
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
	
	if debug_mode and json["debug"]["debug_all_relics"]:
		load_all_relics()
	else:
		equip_relics = json["equipped"]["relics"]
		inv_relics = json["inventory"]["relics"]
	
	if debug_mode and json["debug"]["debug_all_weapons"]:
		load_all_weapons()
	else:
		inv_weapons = json["inventory"]["weapons"]
	equip_weapon = json["equipped"]["weapon"]
	
	if debug_mode and json["debug"]["debug_all_subweps"]:
		load_all_subweps()
	else:
		inv_subweps = json["inventory"]["subweps"]
	equip_subwep = json["equipped"]["subwep"]
	
	if debug_mode and json["debug"]["debug_all_armor"]:
		load_all_armor()
	else:
		inv_armor = json["inventory"]["armor"]
	equip_armor = json["equipped"]["armor"]
	
	if debug_mode and json["debug"]["debug_all_spells"]:
		load_all_spells()
	else:
		inv_spells = json["inventory"]["spells"]
	equip_spell = json["equipped"]["spell"]
	
	if debug_mode and json["debug"]["debug_all_items"]:
		load_all_items()
	else:
		inv_items = json["inventory"]["items"]
	
	set_hp(json["stats"]["hp"])
	set_mp(json["stats"]["mp"])
	
	file.close()

func load_all_relics() -> void:
	for key in DataRepository.InvRelics:
		equip_relics.append(key)
		inv_relics[key] = Dictionary()

func load_all_weapons() -> void:
	for key in DataRepository.InvWeapons:
		inv_weapons[key] = Dictionary()
		inv_weapons[key]["count"] = 1

func load_all_subweps() -> void:
	for key in DataRepository.InvSubweps:
		inv_subweps[key] = Dictionary()
		inv_subweps[key]["count"] = 1

func load_all_armor() -> void:
	for key in DataRepository.InvArmor:
		inv_armor[key] = Dictionary()
		inv_armor[key]["count"] = 1

func load_all_spells() -> void:
	for key in DataRepository.InvSpells:
		inv_spells[key] = Dictionary()
		inv_spells[key]["count"] = 1

func load_all_items() -> void:
	for key in DataRepository.InvItems:
		inv_items[key] = Dictionary()
		inv_items[key]["count"] = 99


################################################################################
# UI flag methods
################################################################################

func is_game_paused() -> bool:
	return pause_menu or map_screen or room_transitioning or area_transitioning

func set_game_paused() -> void:
	get_tree().paused = is_game_paused()

func set_pause_menu(value: bool) -> void:
	pause_menu = !is_game_paused() and value
	set_game_paused()

func set_map_screen(value: bool) -> void:
	map_screen = !is_game_paused() and value
	set_game_paused()

func set_room_transitioning(value: bool) -> void:
	room_transitioning = !is_game_paused() and value
	set_game_paused()

func set_area_transitioning(value: bool) -> void:
	area_transitioning = !is_game_paused() and value
	set_game_paused()


################################################################################
# Upgrade flag/variable methods
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

func set_xp(value: int) -> void:
	xp = int(max(0, value))
	if (xp >= xp_for_next_level and xp_for_next_level != -1) or xp < xp_for_this_level:
		level = xp_to_level(xp)
		xp_for_this_level = level_to_xp(level)
		xp_for_next_level = -1 if level == MAX_LEVEL else level_to_xp(level+1)

func set_hp(value: int) -> void:
	hp = int(clamp(value, 0, get_max_hp()))

func set_mp(value: int) -> void:
	mp = int(clamp(value, 0, get_max_mp()))

func level_to_xp(value: int) -> int:
	# xp = 2L + 5L^2 +3L^3
	return DataRepository.DataLevels[value]

func xp_to_level(value: int) -> int:
	for i in range(MAX_LEVEL+1):
		if DataRepository.DataLevels[i+1] > value:
			return i
	return -1

func skip_to_previous_level() -> void:
	set_xp(xp_for_this_level - 1)
	set_xp(xp_for_this_level)

func skip_to_next_level() -> void:
	if level < MAX_LEVEL:
		set_xp(xp_for_next_level)


################################################################################
# Stat accessors
################################################################################

func get_max_hp() -> int:
	return HP_PER_LEVEL*(level-1) + HP_PER_PLUS*plus_hp_max + BASE_HP

func get_max_mp() -> int:
	return MP_PER_LEVEL*(level-1) + MP_PER_PLUS*plus_mp_max + BASE_MP

func get_atk() -> int:
	var value: int = int(floor(get_str()/2.0))
	if equip_weapon != "": value += DataRepository.InvWeapons[equip_weapon]["stats"]["atk"]
	if equip_armor != "": value += DataRepository.InvArmor[equip_armor]["stats"]["atk"]
	return value

func get_def() -> int:
	var value: int = int(floor(get_con()/2.0))
	if equip_weapon != "": value += DataRepository.InvWeapons[equip_weapon]["stats"]["def"]
	if equip_armor != "": value += DataRepository.InvArmor[equip_armor]["stats"]["def"]
	return value

func get_str() -> int:
	var value: int = int(round(STR_PER_LEVEL*(level-1))) + plus_str + BASE_STR
	if equip_weapon != "": value += DataRepository.InvWeapons[equip_weapon]["stats"]["str"]
	if equip_armor != "": value += DataRepository.InvArmor[equip_armor]["stats"]["str"]
	return value

func get_con() -> int:
	var value: int = int(round(CON_PER_LEVEL*(level-1))) + plus_con + BASE_CON
	if equip_weapon != "": value += DataRepository.InvWeapons[equip_weapon]["stats"]["con"]
	if equip_armor != "": value += DataRepository.InvArmor[equip_armor]["stats"]["con"]
	return value

func get_int() -> int:
	var value: int = int(round(INT_PER_LEVEL*(level-1))) + plus_int + BASE_INT
	if equip_weapon != "": value += DataRepository.InvWeapons[equip_weapon]["stats"]["int"]
	if equip_armor != "": value += DataRepository.InvArmor[equip_armor]["stats"]["int"]
	return value

func get_mnd() -> int:
	var value: int = int(round(MND_PER_LEVEL*(level-1))) + plus_mnd + BASE_MND
	if equip_weapon != "": value += DataRepository.InvWeapons[equip_weapon]["stats"]["mnd"]
	if equip_armor != "": value += DataRepository.InvArmor[equip_armor]["stats"]["mnd"]
	return value

func get_lck() -> int:
	var value: int = int(round(LCK_PER_LEVEL*(level-1))) + plus_lck + BASE_LCK
	if equip_weapon != "": value += DataRepository.InvWeapons[equip_weapon]["stats"]["lck"]
	if equip_armor != "": value += DataRepository.InvArmor[equip_armor]["stats"]["lck"]
	return value
