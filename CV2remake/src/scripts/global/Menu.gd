extends CanvasLayer

onready var GameState: Node = get_node("/root/Main/GameState")
onready var ScreenShaders: Node = get_node("/root/Main/ScreenShaders")
onready var transitioning: bool = false

func _process(_delta):
	check_pause_input()

func check_pause_input() -> void:
	if Input.is_action_just_pressed("input_pause") and !transitioning:
		transitioning = true
		if !GameState.pause_menu:
			GameState.pause_menu = true
			ScreenShaders.black_fadein(2)
			yield(ScreenShaders, "black_fadein_complete")
			$Display.visible = true
			yield(get_tree().create_timer(1.0/30), "timeout")
			ScreenShaders.black_fadeout(4)
			yield(ScreenShaders, "black_fadeout_complete")
		else:
			ScreenShaders.black_fadein(4)
			yield(ScreenShaders, "black_fadein_complete")
			$Display.visible = false
			yield(get_tree().create_timer(1.0/30), "timeout")
			ScreenShaders.black_fadeout(2)
			yield(ScreenShaders, "black_fadeout_complete")
			GameState.pause_menu = false
		transitioning = false
