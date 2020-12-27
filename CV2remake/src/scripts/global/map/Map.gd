extends CanvasLayer

const MAP_WIDTH: int = 48
const MAP_HEIGHT: int = 32

onready var GameState: Node = get_node("/root/Main/GameState")
onready var RoomHandler: Node = get_node("/root/Main/RoomHandler")
export var explored_tiles: Array

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
		$Background.get_node("./MapDraw").update()

func check_map_input() -> void:
	if Input.is_action_just_pressed("input_map"):
		GameState.map_screen = !GameState.map_screen
		$Background.visible = GameState.map_screen
