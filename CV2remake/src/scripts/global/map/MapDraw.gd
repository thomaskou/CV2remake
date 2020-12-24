extends Node2D

const TILE_WIDTH: int = 10
const TILE_HEIGHT: int = 6

onready var Map: Node = get_node("/root/Main/Map")

func _draw():
	for i in range(Map.explored_tiles.size()):
		for j in range(Map.explored_tiles[i].size()):
			if Map.explored_tiles[i][j]:
				var rect: Rect2 = Rect2(
					i*TILE_WIDTH, j*TILE_HEIGHT,
					TILE_WIDTH, TILE_HEIGHT
				)
				draw_rect(rect, Color("#003fc2"))
