extends Node

export var fonts: Dictionary

func _ready():
	prepare_nums0_gray()
	prepare_cv3()
	load_other_fonts()
	
func load_other_fonts() -> void:
	fonts["kingisdead"] = ResourceLoader.load("res://src/assets/fonts/font_kingisdead.tres")
	fonts["m3x6"] = ResourceLoader.load("res://src/assets/fonts/font_m3x6.tres")
	fonts["m5x7"] = ResourceLoader.load("res://src/assets/fonts/font_m5x7.tres")
	fonts["m6x11"] = ResourceLoader.load("res://src/assets/fonts/font_m6x11.tres")
	fonts["pansyhand"] = ResourceLoader.load("res://src/assets/fonts/font_pansyhand.tres")
	fonts["sinsgold"] = ResourceLoader.load("res://src/assets/fonts/font_sinsgold.tres")
	fonts["squarebit"] = ResourceLoader.load("res://src/assets/fonts/font_squarebit.tres")
	fonts["venice"] = ResourceLoader.load("res://src/assets/fonts/font_venice.fnt")

func prepare_nums0_gray() -> void:
	var font: BitmapFont = ResourceLoader.load("res://src/assets/fonts/font_nums0_gray.tres")
	if font == null:
		font = BitmapFont.new()
		font.add_texture(ResourceLoader.load("res://src/assets/fonts/fontbitmap_nums0_gray.png"))
		font.height = 8
		var chars: String = "0123456789"
		for i in range(chars.length()):
			font.add_char(chars.ord_at(i), 0, Rect2(6*i, 0, 6, 8))
		for c0 in font.chars:
			for c1 in font.chars:
				font.add_kerning_pair(c0, c1, 1)
		ResourceSaver.save("res://src/assets/fonts/font_nums0_gray.tres", font)
	fonts["nums0_gray"] = font

func prepare_cv3() -> void:
	var font: BitmapFont = ResourceLoader.load("res://src/assets/fonts/font_cv3.tres")
	if font == null:
		font = BitmapFont.new()
		font.add_texture(ResourceLoader.load("res://src/assets/fonts/fontbitmap_cv3.png"))
		font.height = 8
		var chars: String = "ACEGIKMOQSUWYBDFHJLNPRTVXZacegikmoqsuwybdfhjlnprtvxz?!0123456789&-“”:."
		for i in range(chars.length()):
			font.add_char(chars.ord_at(i), 0, Rect2((8*i)%104, 8*int(floor((8*i)/104.0)), 8, 8))
		for c0 in font.chars:
			for c1 in font.chars:
				font.add_kerning_pair(c0, c1, 1)
		ResourceSaver.save("res://src/assets/fonts/font_cv3.tres", font)
	fonts["cv3"] = font
