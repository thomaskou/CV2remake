extends Camera2D

onready var RoomHandler: Node = get_node("/root/Main/RoomHandler")

func _process(_delta):
	limit_left = RoomHandler.room_limits.position.x
	limit_top = RoomHandler.room_limits.position.y
	limit_right = RoomHandler.room_limits.end.x
	limit_bottom = RoomHandler.room_limits.end.y
