extends Node

func map_key(action, event) -> void:
	var ev = InputEventKey.new()
	ev.scancode = event
	if !(InputMap.has_action(action)):
		InputMap.add_action(action)
	InputMap.action_add_event(action, ev)

func _ready() -> void:
	
	map_key("input_pause", KEY_ENTER)
	map_key("input_map", KEY_SHIFT)
	
	map_key("input_left", KEY_LEFT)
	map_key("input_right", KEY_RIGHT)
	map_key("input_up", KEY_UP)
	map_key("input_down", KEY_DOWN)
	
	map_key("input_jump", KEY_Z)
	map_key("input_attack", KEY_X)
	
	map_key("input_bumper_left", KEY_Q)
	map_key("input_bumper_right", KEY_E)
	map_key("input_menu_modifier", KEY_SHIFT)
	map_key("input_menu_confirm", KEY_Z)
	map_key("input_menu_deny", KEY_Z)
	
	map_key("input_debug1", KEY_1)
	map_key("input_debug2", KEY_2)
	map_key("input_debug3", KEY_3)
	map_key("input_debug4", KEY_4)
	map_key("input_debug5", KEY_5)
	map_key("input_debug6", KEY_6)
	map_key("input_debug7", KEY_7)
	map_key("input_debug8", KEY_8)
	map_key("input_debug9", KEY_9)
	map_key("input_debug0", KEY_0)
