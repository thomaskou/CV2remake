extends Node

export var has_djumps: bool

export var jumps: int

func _ready() -> void:
	
	has_djumps = false
	
	jumps = (2 if has_djumps else 1)
