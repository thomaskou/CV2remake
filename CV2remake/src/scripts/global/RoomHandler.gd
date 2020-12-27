extends Node


################################################################################
# Constants
################################################################################

const SCREEN_WIDTH: int = 320
const SCREEN_HEIGHT: int = 192

const ROOM_MARGIN_LEFT: int = 0
const ROOM_MARGIN_TOP: int = 6
const ROOM_MARGIN_RIGHT: int = 0
const ROOM_MARGIN_BOTTOM: int = 6

const ROOM_TRANSITION_FRAMES: int = 8


################################################################################
# Variables
################################################################################

onready var GameState: Node = get_node("/root/Main/GameState")
onready var ScreenShaders: Node = get_node("/root/Main/ScreenShaders")
onready var Player: Node = get_node("/root/Main/Gameplay/Player")
var AreaNode: Node
var Room: Node
var ScreenMap: Node
var coords_region: Vector2
export var coords_world: Vector2
export var room_limits: Rect2


################################################################################
# Process
################################################################################

func _process(_delta):
	vertical_screen_transition()
	update_area()
	update_room()
	get_coords_region()
	get_coords_world()


################################################################################
# Room loading
################################################################################

func unload_room() -> void:
	AreaNode.remove_child(Room)
	Room.queue_free()

func load_room(new_room_data: Dictionary) -> void:
	Room = load(new_room_data["filename"]).instance()
	Room.name = "Room"
	Room.position = new_room_data["position"]
	set_room_limits()
	AreaNode.add_child(Room)

func room_transition(new_room_data: Dictionary) -> void:
	ScreenShaders.black_fadein(0)
	unload_room()
	load_room(new_room_data)
	GameState.room_transitioning = true
	yield(get_tree().create_timer(ROOM_TRANSITION_FRAMES / 60.0), "timeout")
	ScreenShaders.black_fadeout(0)
	GameState.room_transitioning = false


################################################################################
# Room transitions
################################################################################

func vertical_screen_transition() -> void:
	if room_limits != null:
		if Player.position.y < room_limits.position.y:
			Player.move_local_y(-12)
		if Player.position.y > room_limits.end.y:
			Player.move_local_y(12)

func update_area() -> void:
	var get_area: Node = get_node("/root/Main/Gameplay/Area")
	if AreaNode != get_area:
		AreaNode = get_area

func update_room() -> void:
	var player_coords: Vector2 = Vector2(
		floor(Player.position.x / SCREEN_WIDTH),
		floor(Player.position.y / SCREEN_HEIGHT)
	)
	if AreaNode.room_map.has(player_coords):
		var get_room_data: Dictionary = AreaNode.room_map[player_coords]
		if get_room_data != null:
			if Room == null:
				load_room(get_room_data)
			elif Room.filename != get_room_data["filename"]:
				room_transition(get_room_data)


################################################################################
# Room coordinates/limits helpers
################################################################################

func set_room_limits() -> void:
	ScreenMap = Room.get_node("./Screens")
	var limits: Rect2 = ScreenMap.get_used_rect()
	var cell_size: Vector2 = ScreenMap.cell_size
	room_limits.position.x = Room.position.x + ScreenMap.position.x + (limits.position.x * cell_size.x) + ROOM_MARGIN_LEFT
	room_limits.position.y = Room.position.y + ScreenMap.position.y + (limits.position.y * cell_size.y) + ROOM_MARGIN_TOP
	room_limits.end.x = Room.position.x + ScreenMap.position.x + (limits.end.x * cell_size.x) - ROOM_MARGIN_RIGHT
	room_limits.end.y = Room.position.y + ScreenMap.position.y + (limits.end.y * cell_size.y) - ROOM_MARGIN_BOTTOM

func get_coords_region() -> void:
	coords_region = Vector2(
		(Player.position.x - ScreenMap.position.x) / ScreenMap.cell_size.x,
		(Player.position.y - ScreenMap.position.y) / ScreenMap.cell_size.y
	)

func get_coords_world() -> void:
	if AreaNode.get("region_coords") == null:
		coords_world = coords_region
	else:
		coords_world = coords_region + AreaNode.region_coords
