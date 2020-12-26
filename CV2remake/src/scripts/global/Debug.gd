extends Node

onready var GameState: Node = get_node("/root/Main/GameState")
onready var debug_mode: bool = GameState.debug_mode

var input_debug1: bool
var input_debug2: bool
var input_debug3: bool
var input_debug4: bool
var input_debug5: bool
var input_debug6: bool
var input_debug7: bool
var input_debug8: bool
var input_debug9: bool
var input_debug0: bool

var input_debug1_pressed: bool
var input_debug2_pressed: bool
var input_debug3_pressed: bool
var input_debug4_pressed: bool
var input_debug5_pressed: bool
var input_debug6_pressed: bool
var input_debug7_pressed: bool
var input_debug8_pressed: bool
var input_debug9_pressed: bool
var input_debug0_pressed: bool

func _process(_delta):
	if debug_mode:
		set_debug_keys()
		hp_hotkeys()
		mp_hotkeys()

func set_debug_keys() -> void:
	input_debug1 = Input.is_action_pressed("input_debug1")
	input_debug2 = Input.is_action_pressed("input_debug2")
	input_debug3 = Input.is_action_pressed("input_debug3")
	input_debug4 = Input.is_action_pressed("input_debug4")
	input_debug5 = Input.is_action_pressed("input_debug5")
	input_debug6 = Input.is_action_pressed("input_debug6")
	input_debug7 = Input.is_action_pressed("input_debug7")
	input_debug8 = Input.is_action_pressed("input_debug8")
	input_debug9 = Input.is_action_pressed("input_debug9")
	input_debug0 = Input.is_action_pressed("input_debug0")
	input_debug1_pressed = Input.is_action_just_pressed("input_debug1")
	input_debug2_pressed = Input.is_action_just_pressed("input_debug2")
	input_debug3_pressed = Input.is_action_just_pressed("input_debug3")
	input_debug4_pressed = Input.is_action_just_pressed("input_debug4")
	input_debug5_pressed = Input.is_action_just_pressed("input_debug5")
	input_debug6_pressed = Input.is_action_just_pressed("input_debug6")
	input_debug7_pressed = Input.is_action_just_pressed("input_debug7")
	input_debug8_pressed = Input.is_action_just_pressed("input_debug8")
	input_debug9_pressed = Input.is_action_just_pressed("input_debug9")
	input_debug0_pressed = Input.is_action_just_pressed("input_debug0")

func hp_hotkeys() -> void:
	if input_debug7:
		GameState.hp -= 1
	if input_debug8:
		GameState.hp += 1

func mp_hotkeys() -> void:
	if input_debug9:
		GameState.mp -= 1
	if input_debug0:
		GameState.mp += 1
