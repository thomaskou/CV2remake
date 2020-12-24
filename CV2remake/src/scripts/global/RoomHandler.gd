extends Node

const SCREEN_WIDTH: int = 320
const SCREEN_HEIGHT: int = 192

const ROOM_MARGIN_LEFT: int = 0
const ROOM_MARGIN_TOP: int = 6
const ROOM_MARGIN_RIGHT: int = 0
const ROOM_MARGIN_BOTTOM: int = 6

onready var Player: Node = get_node("/root/Main/Gameplay/Player")
var AreaNode: Node
var Room: Node
var ScreenMap: Node
var coords_region: Vector2
export var coords_world: Vector2
export var room_limits: Rect2

func _process(_delta):
	vertical_screen_transition()
	update_area()
	update_room()
	get_coords_region()
	get_coords_world()

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
		var get_room: Node = AreaNode.room_map[player_coords]
		if get_room != null and Room != get_room:
			AreaNode.remove_child(Room)
			AreaNode.add_child(get_room)
			Room = get_node("/root/Main/Gameplay/Area/Room")
			ScreenMap = Room.get_node("./Screens")
			set_room_limits()

func set_room_limits() -> void:
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
