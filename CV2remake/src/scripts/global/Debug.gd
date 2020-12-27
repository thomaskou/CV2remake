extends Node

onready var GameState: Node = get_node("/root/Main/GameState")
onready var debug_mode: bool = GameState.debug_mode

func _process(_delta):
	if debug_mode:
		xp_hotkeys("input_debug5", "input_debug6")
		hp_hotkeys("input_debug7", "input_debug8")
		mp_hotkeys("input_debug9", "input_debug0")

func hp_hotkeys(down: String, up: String) -> void:
	if Input.is_action_pressed(down):
		GameState.hp -= 1
	if Input.is_action_pressed(up):
		GameState.hp += 1

func mp_hotkeys(down: String, up: String) -> void:
	if Input.is_action_pressed(down):
		GameState.mp -= 1
	if Input.is_action_pressed(up):
		GameState.mp += 1

func xp_hotkeys(down: String, up: String) -> void:
	if Input.is_action_just_pressed(down):
		GameState.skip_to_previous_level()
	if Input.is_action_just_pressed(up):
		GameState.skip_to_next_level()
