extends Node

onready var GameState: Node = get_node("../GameState")
onready var HP: Node = get_node("Margin/HBox/Bars/HP")
onready var MP: Node = get_node("Margin/HBox/Bars/MP")

func _process(_delta):
	set_hp()
	set_mp()

func set_hp() -> void:
	if GameState.hp == 0:
		HP.value = 0
	elif GameState.hp == GameState.max_hp:
		HP.value = HP.max_value
	else:
		HP.value = int(round((HP.max_value-2)*(GameState.hp-1)/(GameState.max_hp-2)))+1

func set_mp() -> void:
	if GameState.mp == 0:
		MP.value = 0
	elif GameState.mp == GameState.max_mp:
		MP.value = MP.max_value
	else:
		MP.value = int(round((MP.max_value-2)*(GameState.mp-1)/(GameState.max_mp-2)))+1
