extends Node2D

export var room_map: Dictionary

func _enter_tree():
	for room in $Rooms.get_children():
		var screens: TileMap = room.get_node("./Screens")
		var room_rect: Rect2 = screens.get_used_rect()
		var cell_size: Vector2 = screens.cell_size
		var room_position: Vector2 = Vector2(room.position.x / cell_size.x, room.position.y / cell_size.y)
		for i in range(room_rect.position.x, room_rect.end.x):
			for j in range (room_rect.position.y, room_rect.end.y):
				var room_data: Dictionary
				room_data["filename"] = room.filename
				room_data["position"] = room.position
				room_map[Vector2(i + room_position.x, j + room_position.y)] = room_data
				$Rooms.remove_child(room)
				room.queue_free()
	remove_child($Rooms)
