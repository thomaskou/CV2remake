extends Node

func map_key(action, event) -> void:
	var ev = InputEventKey.new()
	ev.scancode = event
	if !(InputMap.has_action(action)):
		InputMap.add_action(action)
	InputMap.action_add_event(action, ev)

func _ready() -> void:
	
	map_key("input_left", KEY_LEFT)
	map_key("input_right", KEY_RIGHT)
	map_key("input_up", KEY_UP)
	map_key("input_down", KEY_DOWN)
	
	map_key("input_jump", KEY_Z)
