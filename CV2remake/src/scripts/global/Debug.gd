extends CanvasLayer

const PLAYER_STATE_TO_STRING: Array = [
	"DEFAULT",
	"GROUND", "GROUND_ATK", "GROUND_ATK_STUN", "GROUND_DASH", "HURT_GROUND",
	"AIR", "AIR_ATK", "AIR_ATK_STUN", "AIR_DASH", "SJUMP", "HURT_AIR",
	"CROUCH", "CROUCH_ATK", "CROUCH_ATK_STUN", "SLIDE", "HURT_CROUCH", "CROUCH_STUN",
]

onready var GameState: Node = get_node("/root/Main/GameState")
onready var Player: Node = get_node("/root/Main/Gameplay/Player")
onready var debug_mode: bool = GameState.debug_mode

func _process(delta):
	if debug_mode:
		update_debug_text(delta)
		toggle_debug_menu("input_debug1")
		xp_hotkeys("input_debug5", "input_debug6")
		hp_hotkeys("input_debug7", "input_debug8")
		mp_hotkeys("input_debug9", "input_debug0")

func toggle_debug_menu(input: String) -> void:
	if Input.is_action_just_pressed(input):
		$Background.visible = !$Background.visible

func update_debug_text(delta) -> void:
	var text: String = ""
	text += PLAYER_STATE_TO_STRING[Player.state]
	text += "\nDELTA*60: " + String(delta*60)
	if delta > 0: text += "\nFPS: " + String(1.0/delta)
	get_node("Background/Text").text = text

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
	if Input.is_action_pressed(down):
		GameState.xp -= 5
	if Input.is_action_pressed(up):
		GameState.xp += 5

func xp_skip_hotkeys(down: String, up: String) -> void:
	if Input.is_action_just_pressed(down):
		GameState.skip_to_previous_level()
	if Input.is_action_just_pressed(up):
		GameState.skip_to_next_level()
