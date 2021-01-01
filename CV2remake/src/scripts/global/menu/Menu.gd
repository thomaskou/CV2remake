extends CanvasLayer


################################################################################
# Constants
################################################################################

const SCREEN_WIDTH: int = 320

const FADE_GAME_FRAMES: int = 2
const FADE_WAIT_FRAMES: int = 2
const FADE_MENU_FRAMES: int = 2

const TAB_COLOR_INACTIVE: Color = Color(96.0/255,96.0/255,96.0/255)
const TAB_COLOR_ACTIVE: Color = Color(252.0/255, 248.0/255, 252.0/255)
const TAB_TRANSITION_FRAMES: int = 12


################################################################################
# Variables
################################################################################

onready var GameState: Node = get_node("/root/Main/GameState")
onready var ScreenShaders: Node = get_node("/root/Main/ScreenShaders")
export onready var transitioning: bool = false

export onready var tab: int = 0
onready var Screens: Node = get_node("Display/Screens")
onready var Labels: Node = get_node("Display/Tabs/Center/Labels")

var input_pause: bool
var input_tab_left: bool
var input_tab_right: bool


################################################################################
# Ready
################################################################################

func _ready():
	$Display.visible = false
	highlight_current_tab()


################################################################################
# Process
################################################################################

func _process(_delta):
	check_pause_input()
	if GameState.pause_menu:
		get_inputs()
		check_bumper_input()


################################################################################
# Input checking
################################################################################

func get_inputs() -> void:
	input_tab_left = Input.is_action_just_pressed("input_bumper_left")
	input_tab_right = Input.is_action_just_pressed("input_bumper_right")

func check_bumper_input() -> void:
	if input_tab_left and !input_tab_right:
		var previous_tab: int = tab
		tab = (tab+Labels.get_child_count()-1) % Labels.get_child_count()
		tween_from_previous_tab(previous_tab)
	if input_tab_right and !input_tab_left:
		var previous_tab: int = tab
		tab = (tab+1) % Labels.get_child_count()
		tween_from_previous_tab(previous_tab)


################################################################################
# Tab switching
################################################################################

func jump_to_tab(value: int) -> void:
	tab = value
	Screens.rect_position.x = -SCREEN_WIDTH*tab
	highlight_current_tab()

func tween_from_previous_tab(previous_tab: int) -> void:
	highlight_current_tab()
	$Tween.interpolate_property(
		Screens, "rect_position",
		Vector2(-SCREEN_WIDTH*previous_tab, Screens.rect_position.y),
		Vector2(-SCREEN_WIDTH*tab, Screens.rect_position.y),
		TAB_TRANSITION_FRAMES/60.0, 4
	)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	$Tween.reset_all()

func highlight_current_tab() -> void:
	for i in range(Labels.get_child_count()):
		Labels.get_child(i).add_color_override("font_color", TAB_COLOR_ACTIVE if i == tab else TAB_COLOR_INACTIVE)


################################################################################
# Pausing
################################################################################

func check_pause_input() -> void:
	input_pause = Input.is_action_just_pressed("input_pause")
	if input_pause and !transitioning:
		transitioning = true
		if !GameState.pause_menu and !GameState.is_game_paused():
			GameState.pause_menu = true
			jump_to_tab(0)
			ScreenShaders.black_fadein(FADE_GAME_FRAMES)
			yield(ScreenShaders, "black_fadein_complete")
			$Display.visible = true
			yield(get_tree().create_timer(FADE_WAIT_FRAMES / 60.0), "timeout")
			ScreenShaders.black_fadeout(FADE_MENU_FRAMES)
			yield(ScreenShaders, "black_fadeout_complete")
		elif GameState.pause_menu and GameState.is_game_paused():
			ScreenShaders.black_fadein(FADE_MENU_FRAMES)
			yield(ScreenShaders, "black_fadein_complete")
			$Display.visible = false
			yield(get_tree().create_timer(FADE_WAIT_FRAMES / 60.0), "timeout")
			ScreenShaders.black_fadeout(FADE_GAME_FRAMES)
			yield(ScreenShaders, "black_fadeout_complete")
			GameState.pause_menu = false
		transitioning = false
