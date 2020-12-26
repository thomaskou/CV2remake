extends Node

export var fonts: Dictionary

func _ready():
	prepare_nums0_gray()

func prepare_nums0_gray() -> void:
	var font: BitmapFont = ResourceLoader.load("res://src/assets/fonts/font_nums0_gray.tres")
	if font == null:
		font = BitmapFont.new()
		font.add_texture(ResourceLoader.load("res://src/assets/sprites/text/text_nums0_gray.png"))
		font.height = 8
		var chars: String = "0123456789"
		for i in range(chars.length()):
			font.add_char(chars.ord_at(i), 0, Rect2(6*i, 0, 6, 8))
		for c0 in font.chars:
			for c1 in font.chars:
				font.add_kerning_pair(c0, c1, 1)
		ResourceSaver.save("res://src/assets/fonts/font_nums0_gray.tres", font)
	fonts["nums0_gray"] = font
