extends Control


################################################################################
# Constants
################################################################################

const GRID_WIDTH: int = 208
const GRID_SPACING: int = 16
const GRID_COLUMNS: int = 8

const TILE_DIMENSIONS: Vector2 = Vector2(24,24)
const TILE_SPACING: int = 2
const TAB_TRANSITION_FRAMES: int = 8
const GRID_SCROLL_FRAMES: int = 6
const GRID_TILE_MARGIN: int = 10
const GRID_SCROLL_MARGIN: int = 4

const INPUT_HOLD_WAIT: int = 18
const INPUT_HOLD_INTERVAL: int = 6

const TILE_BG_NORMAL: Color = Color("2c2c2c")
const TILE_BG_EQUIPPED: Color = Color("606060")
const TILE_BORDER: Color = Color("fcf8fc")

const STAT_COLOR_WORSE: Color = Color("e40060")
const STAT_COLOR_SAME: Color = Color("fcf8fc")
const STAT_COLOR_BETTER: Color = Color("38c0fc")
const STAT_ARROW_WORSE_PATH: String = "res://src/assets/sprites/ui/menu_stats_arrow_down.png"
const STAT_ARROW_SAME_PATH: String = "res://src/assets/sprites/ui/menu_stats_arrow_same.png"
const STAT_ARROW_BETTER_PATH: String = "res://src/assets/sprites/ui/menu_stats_arrow_up.png"


################################################################################
# Variables
################################################################################

onready var DataRepository: Node = get_node("/root/Main/DataRepository")
onready var FontRepository: Node = get_node("/root/Main/FontRepository")
onready var GameState: Node = get_node("/root/Main/GameState")
onready var Menu: Node = get_node("/root/Main/Menu")

export onready var tab: int = 0
onready var GridsBox: Control = get_node("Grids/Box")
onready var WeaponsGrid: GridContainer = get_node("Grids/Box/Weapons")
onready var SubwepsGrid: GridContainer = get_node("Grids/Box/Subweps")
onready var ArmorGrid: GridContainer = get_node("Grids/Box/Armor")
onready var SpellsGrid: GridContainer = get_node("Grids/Box/Spells")

onready var index: Array = [0,0,0,0]
onready var grid: Array = [WeaponsGrid, SubwepsGrid, ArmorGrid, SpellsGrid]

onready var style_normal: StyleBox = create_style_normal()
onready var style_selected: StyleBox = create_style_selected()
onready var style_equipped: StyleBox = create_style_equipped()

onready var stat_arrow_worse: Texture = load(STAT_ARROW_WORSE_PATH)
onready var stat_arrow_same: Texture = load(STAT_ARROW_SAME_PATH)
onready var stat_arrow_better: Texture = load(STAT_ARROW_BETTER_PATH)

var input_menu_modifier: bool
var input_confirm: bool
var input_up: bool
var input_down: bool
var input_left: bool
var input_right: bool
var input_up_press: bool
var input_down_press: bool
var input_left_press: bool
var input_right_press: bool
onready var input_up_counter: int = 0
onready var input_down_counter: int = 0
onready var input_left_counter: int = 0
onready var input_right_counter: int = 0


################################################################################
# Ready
################################################################################

func _ready():
	for name in GameState.inv_weapons:
		var repository: Dictionary = DataRepository.InvWeapons
		WeaponsGrid.add_child(create_item_tile(name, repository[name], GameState.equip_weapon == name))
	for name in GameState.inv_subweps:
		var repository: Dictionary = DataRepository.InvSubweps
		SubwepsGrid.add_child(create_item_tile(name, repository[name], GameState.equip_subwep == name))
	for name in GameState.inv_armor:
		var repository: Dictionary = DataRepository.InvArmor
		ArmorGrid.add_child(create_item_tile(name, repository[name], GameState.equip_armor == name))
	for name in GameState.inv_spells:
		var repository: Dictionary = DataRepository.InvSpells
		SpellsGrid.add_child(create_item_tile(name, repository[name], GameState.equip_spell == name))
	for i in range(GridsBox.get_child_count()):
		initiate_selected_item(i)


################################################################################
# Process
################################################################################

func _process(_delta):
	if is_tab_active():
		get_inputs()
		if input_menu_modifier:
			check_tab_input()
		else:
			check_tile_input()
			check_confirm_input()
			input_counters()

func is_tab_active() -> bool:
	return GameState.pause_menu and Menu.tab == 1 and !Menu.transitioning


################################################################################
# Input checking
################################################################################

func get_inputs() -> void:
	input_menu_modifier = Input.is_action_pressed("input_menu_modifier")
	input_confirm = Input.is_action_just_pressed("input_menu_confirm")
	input_up = Input.is_action_pressed("input_up")
	input_down = Input.is_action_pressed("input_down")
	input_left = Input.is_action_pressed("input_left")
	input_right = Input.is_action_pressed("input_right")
	input_up_press = Input.is_action_just_pressed("input_up")
	input_down_press = Input.is_action_just_pressed("input_down")
	input_left_press = Input.is_action_just_pressed("input_left")
	input_right_press = Input.is_action_just_pressed("input_right")

func check_tab_input() -> void:
	if input_left_press and !input_right_press:
		var previous_tab: int = tab
		tab = int(max(0, tab-1))
		update_display_data(tab)
		tween_from_previous_tab(previous_tab)
	if input_right_press and !input_left_press:
		var previous_tab: int = tab
		tab = int(min(tab+1, GridsBox.get_child_count()-1))
		update_display_data(tab)
		tween_from_previous_tab(previous_tab)

func check_confirm_input() -> void:
	if input_confirm:
		var name: String = grid[tab].get_child(index[tab]).name
		var old_name: String
		match tab:
			0:
				old_name = GameState.equip_weapon
				GameState.equip_weapon = name
			1:
				old_name = GameState.equip_subwep
				GameState.equip_subwep = name
			2:
				old_name = GameState.equip_armor
				GameState.equip_armor = name
			3:
				old_name = GameState.equip_spell
				GameState.equip_spell = name
		for item in grid[tab].get_children():
			if item.name == old_name:
				item.get_node("BG").add_stylebox_override("panel", style_normal)
		grid[tab].get_child(index[tab]).get_node("BG").add_stylebox_override("panel", style_equipped)
		render_stats_box(tab)

func input_counters() -> void:
	if input_confirm:
		input_up_counter = 0
		input_down_counter = 0
		input_left_counter = 0
		input_right_counter = 0
		return
	if !input_down:
		if input_up:
			input_up_counter += 1
		input_down_counter = 0
	if !input_up:
		if input_down:
			input_down_counter += 1
		input_up_counter = 0
	if !input_right:
		if input_left:
			input_left_counter += 1
		input_right_counter = 0
	if !input_left:
		if input_right:
			input_right_counter += 1
		input_left_counter = 0

func check_tile_input() -> void:
	var hold_up: bool = input_up_counter >= INPUT_HOLD_WAIT and input_up_counter % INPUT_HOLD_INTERVAL == 0
	var hold_down: bool = input_down_counter >= INPUT_HOLD_WAIT and input_down_counter % INPUT_HOLD_INTERVAL == 0
	var hold_left: bool = input_left_counter >= INPUT_HOLD_WAIT and input_left_counter % INPUT_HOLD_INTERVAL == 0
	var hold_right: bool = input_right_counter >= INPUT_HOLD_WAIT and input_right_counter % INPUT_HOLD_INTERVAL == 0
	if (input_up_press or input_up and hold_up) and !input_down and index[tab] >= GRID_COLUMNS:
		var previous_index = index[tab]
		index[tab] = int(max(0, index[tab] - GRID_COLUMNS))
		update_selected_item(previous_index)
	if (input_down_press or input_down and hold_down) and !input_up and index[tab] < grid[tab].get_child_count() - GRID_COLUMNS:
		var previous_index = index[tab]
		index[tab] = int(min(index[tab] + GRID_COLUMNS, grid[tab].get_child_count()-1))
		update_selected_item(previous_index)
	if (input_left_press or input_left and hold_left) and !input_right:
		var previous_index = index[tab]
		index[tab] = int(max(0, index[tab] - 1))
		update_selected_item(previous_index)
	if (input_right_press or input_right and hold_right) and !input_left:
		var previous_index = index[tab]
		index[tab] = int(min(index[tab] + 1, grid[tab].get_child_count()-1))
		update_selected_item(previous_index)


################################################################################
# Tab switching
################################################################################

func tween_from_previous_tab(previous_tab: int) -> void:
	$TweenTab.interpolate_property(
		GridsBox, "rect_position",
		Vector2(-(GRID_WIDTH+GRID_SPACING)*previous_tab, GridsBox.rect_position.y),
		Vector2(-(GRID_WIDTH+GRID_SPACING)*tab, GridsBox.rect_position.y),
		TAB_TRANSITION_FRAMES/60.0, 4
	)
	$TweenTab.start()
	yield($TweenTab, "tween_all_completed")
	$TweenTab.reset_all()


################################################################################
# Tile selection
################################################################################

func initiate_selected_item(current_tab: int) -> void:
	grid[current_tab].get_child(index[current_tab]).get_node("Border").visible = true
	update_display_data(current_tab)
	initiate_scroll_grid(current_tab)

func update_selected_item(previous_index: int) -> void:
	grid[tab].get_child(previous_index).get_node("Border").visible = false
	grid[tab].get_child(index[tab]).get_node("Border").visible = true
	update_display_data(tab)
	scroll_grid(previous_index)

func get_scroll_height(selected_index: int) -> int:
	var tile_height = TILE_DIMENSIONS.y+TILE_SPACING
	return int(floor(selected_index/GRID_COLUMNS)) * tile_height

func get_scroll_position(new_height: int, current_tab: int) -> int:
	var tile_height = TILE_DIMENSIONS.y+TILE_SPACING
	var min_height: int = tile_height + GRID_TILE_MARGIN - GRID_SCROLL_MARGIN
	var max_height: int = (int(floor(max(0,grid[current_tab].get_child_count()-1)/GRID_COLUMNS))-1) * tile_height - GRID_TILE_MARGIN + GRID_SCROLL_MARGIN
	return tile_height+GRID_TILE_MARGIN-int(clamp(new_height, min_height, max_height))

func initiate_scroll_grid(current_tab: int) -> void:
	grid[current_tab].rect_position.y = get_scroll_position(get_scroll_height(index[tab]), current_tab)

func scroll_grid(previous_index: int) -> void:
	var tile_height = TILE_DIMENSIONS.y+TILE_SPACING
	var previous_height: int = get_scroll_height(previous_index)
	var selected_height: int = get_scroll_height(index[tab])
	if previous_height != selected_height:
		$TweenGrid.interpolate_property(
			grid[tab], "rect_position",
			grid[tab].rect_position,
			Vector2(grid[tab].rect_position.x, get_scroll_position(selected_height, tab)),
			GRID_SCROLL_FRAMES/60.0, 0
		)
		$TweenGrid.start()
		yield($TweenGrid, "tween_all_completed")
		$TweenGrid.reset_all()

func create_item_tile(name: String, data: Dictionary, equipped: bool) -> Node:
	# Create outer node
	var tile: Control = Control.new()
	tile.name = name
	tile.rect_min_size = TILE_DIMENSIONS
	
	# Create Background and add to node
	var background: Panel = Panel.new()
	background.name = "BG"
	background.rect_min_size = TILE_DIMENSIONS
	background.add_stylebox_override("panel", style_equipped if equipped else style_normal)
	tile.add_child(background)
	
	# Create border and add to node
	var border: Panel = Panel.new()
	border.name = "Border"
	border.rect_min_size = TILE_DIMENSIONS
	border.add_stylebox_override("panel", style_selected)
	border.visible = false
	tile.add_child(border)
	
	# Create CenterContainer and add to node
	var container: CenterContainer = CenterContainer.new()
	container.rect_min_size = TILE_DIMENSIONS
	tile.add_child(container)
	
	# Create sprite and add to CenterContainer
	var sprite: TextureRect = TextureRect.new()
	sprite.texture = load(data["icon"])
	container.add_child(sprite)
	
	# Add ATK label and add to node
	# if data.has("stats") and data["stats"].has("atk"):
	# 	var label: Label = Label.new()
	# 	label.text = String(data["stats"]["atk"])
	# 	label.rect_size = Vector2(TILE_DIMENSIONS.x, 7)
	# 	label.rect_position = Vector2(1, TILE_DIMENSIONS.y - 11)
	# 	label.align = Label.ALIGN_RIGHT
	# 	label.valign = Label.VALIGN_BOTTOM
	# 	label.add_font_override("font", FontRepository.fonts["pansyhand"])
	# 	label.material = load("res://src/assets/shaders/outline_outer_black.tres")
	# 	tile.add_child(label)
	
	return tile


################################################################################
# Styling
################################################################################

func create_style_normal() -> StyleBox:
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(3)
	style.bg_color = TILE_BG_NORMAL
	return style

func create_style_selected() -> StyleBox:
	var style = StyleBoxFlat.new()
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.border_color = TILE_BORDER
	style.bg_color = Color(0,0,0,0)
	return style

func create_style_equipped() -> StyleBox:
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(3)
	style.bg_color = TILE_BG_EQUIPPED
	return style


################################################################################
# Description, stats, metadata
################################################################################

func update_display_data(current_tab: int) -> void:
	update_description(current_tab)
	update_stats_text(current_tab)
	update_attributes(current_tab)
	render_stats_box(current_tab)

func update_description(current_tab: int) -> void:
	var data: Dictionary = get_selected_data(current_tab)
	get_node("Description/Sprite").texture = load(data["icon"])
	get_node("Description/Name").text = data.name
	get_node("Description/DescText").text = data.description

func update_stats_text(current_tab: int) -> void:
	var StatsText: Label = get_node("Description/StatsText")
	var text_arr: Array = []
	var stats: Dictionary = get_selected_data(current_tab)["stats"]
	for stat in stats:
		if stats[stat] != 0:
			text_arr.append(stat.to_upper() + " " + String(stats[stat]))
	var text: String = ""
	for i in text_arr.size():
		if text_arr.size() > 2 and i == ceil(text_arr.size() / 2.0): text += ",\n"
		elif i > 0: text += ", "
		text += text_arr[i]
	StatsText.text = text

func update_attributes(current_tab: int) -> void:
	var AttribGrid: GridContainer = get_node("Description/AttribGrid")
	for child in AttribGrid.get_children():
		AttribGrid.remove_child(child)
		child.queue_free()
	var attribs: Array = get_selected_data(current_tab)["attrib"]
	for attrib in attribs:
		var icon: TextureRect = TextureRect.new()
		icon.texture = load(DataRepository.DataTextures["icons_attrib_gold"][attrib])
		AttribGrid.add_child(icon)
	AttribGrid.rect_size = Vector2(attribs.size()*16, 16)
	AttribGrid.rect_position = Vector2(312 - attribs.size()*16, 28)

func render_stats_box(current_tab: int) -> void:
	var data: Dictionary = get_selected_data(current_tab)
	var StatsText: Control = get_node("StatsBoxDiff/Text")
	for i in range(7):
		var stat_name: String = DataRepository.DataEnums["stats"][i]
		var current_stat: int = GameState.get_stat_by_name(stat_name)
		var new_stat: int = int(max(GameState.get_base_stat_by_name(stat_name) + data["stats"][stat_name], 0))
		StatsText.get_child(i).get_node("Left").text = String(current_stat)
		StatsText.get_child(i).get_node("Right").text = String(new_stat)
		var text_color: Color
		var stat_arrow: Texture
		match sign(new_stat - current_stat):
			-1.0:
				text_color = STAT_COLOR_WORSE
				stat_arrow = stat_arrow_worse
			0.0:
				text_color = STAT_COLOR_SAME
				stat_arrow = stat_arrow_same
			1.0:
				text_color = STAT_COLOR_BETTER
				stat_arrow = stat_arrow_better
		StatsText.get_child(i).get_node("Right").add_color_override("font_color", text_color)
		StatsText.get_child(i).get_node("Arrow").texture = stat_arrow


################################################################################
# Helper methods
################################################################################

func get_selected_data(current_tab: int) -> Dictionary:
	var repository: Dictionary
	match tab:
		0: repository = DataRepository.InvWeapons
		1: repository = DataRepository.InvSubweps
		2: repository = DataRepository.InvArmor
		3: repository = DataRepository.InvSpells
	return repository[grid[current_tab].get_child(index[current_tab]).name]
