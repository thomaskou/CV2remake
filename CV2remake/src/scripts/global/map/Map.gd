extends Node

const MAP_WIDTH: int = 48
const MAP_HEIGHT: int = 32

onready var GameState: Node = get_node("/root/Main/GameState")
onready var RoomHandler: Node = get_node("/root/Main/RoomHandler")
export var explored_tiles: Array
var input_map_press: bool

func _ready():
	explored_tiles = []
	for i in range(MAP_WIDTH):
		explored_tiles.append([])
		for j in range(MAP_HEIGHT):
			explored_tiles[i].append(false)

func _process(delta):
	update_explored_tiles()
	check_map_input()

func update_explored_tiles() -> void:
	if !explored_tiles[RoomHandler.coords_world.x][RoomHandler.coords_world.y]:
		explored_tiles[RoomHandler.coords_world.x][RoomHandler.coords_world.y] = true
		var map_draw: Node = get_node("./Parallax/Background/MapDraw")
		map_draw.update()

func check_map_input() -> void:
	input_map_press = Input.is_action_just_pressed("input_map")
	if input_map_press and !GameState.pause_menu:
		var paused: bool = get_tree().paused
		get_tree().paused = !paused
		GameState.map_screen = !GameState.map_screen
		var map_bg: Node = get_node("./Parallax/Background")
		map_bg.visible = !map_bg.visible
