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
const GRID_SCROLL_MARGIN: int = 6

const INPUT_HOLD_WAIT: int = 18
const INPUT_HOLD_INTERVAL: int = 6


################################################################################
# Variables
################################################################################

onready var DataRepository: Node = get_node("/root/Main/DataRepository")
onready var FontRepository: Node = get_node("/root/Main/FontRepository")
onready var GameState: Node = get_node("/root/Main/GameState")
onready var Menu: Node = get_node("/root/Main/Menu")

export onready var tab: int = 0
onready var GridsBox: Node = get_node("Grids/Box")
onready var WeaponsGrid: Node = get_node("Grids/Box/Weapons")
onready var SubwepsGrid: Node = get_node("Grids/Box/Subweps")
onready var ArmorGrid: Node = get_node("Grids/Box/Armor")
onready var SpellsGrid: Node = get_node("Grids/Box/Spells")

onready var index: Array = [0,0,0,0]
onready var grid: Array = [WeaponsGrid, SubwepsGrid, ArmorGrid, SpellsGrid]

onready var style_normal: StyleBox = create_style_normal()
onready var style_selected: StyleBox = create_style_selected()
onready var style_equipped: StyleBox = create_style_equipped()

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
		update_description(tab)
		tween_from_previous_tab(previous_tab)
	if input_right_press and !input_left_press:
		var previous_tab: int = tab
		tab = int(min(tab+1, GridsBox.get_child_count()-1))
		update_description(tab)
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
	update_description(current_tab)
	initiate_scroll_grid(current_tab)

func initiate_scroll_grid(current_tab: int) -> void:
	var tile_height = TILE_DIMENSIONS.y+TILE_SPACING
	var selected_height: int = int(floor(index[current_tab]/GRID_COLUMNS)) * tile_height
	var max_height: int = (int(floor(grid[current_tab].get_child_count()/GRID_COLUMNS))-1) * tile_height
	grid[current_tab].rect_position.y = tile_height+GRID_SCROLL_MARGIN-int(clamp(selected_height, tile_height, max_height))

func update_selected_item(previous_index: int) -> void:
	grid[tab].get_child(previous_index).get_node("Border").visible = false
	grid[tab].get_child(index[tab]).get_node("Border").visible = true
	update_description(tab)
	scroll_grid(previous_index)

func scroll_grid(previous_index: int) -> void:
	var tile_height = TILE_DIMENSIONS.y+TILE_SPACING
	var previous_height: int = int(floor(previous_index/GRID_COLUMNS)) * tile_height
	var selected_height: int = int(floor(index[tab]/GRID_COLUMNS)) * tile_height
	if previous_height != selected_height:
		var max_height: int = (int(floor(grid[tab].get_child_count()/GRID_COLUMNS))-1) * tile_height
		$TweenGrid.interpolate_property(
			grid[tab], "rect_position",
			grid[tab].rect_position,
			Vector2(grid[tab].rect_position.x, tile_height+GRID_SCROLL_MARGIN-int(clamp(selected_height, tile_height, max_height))),
			GRID_SCROLL_FRAMES/60.0, 0
		)
		$TweenGrid.start()
		yield($TweenGrid, "tween_all_completed")
		$TweenGrid.reset_all()

func update_description(current_tab: int) -> void:
	var repository: Dictionary
	match tab:
		0: repository = DataRepository.InvWeapons
		1: repository = DataRepository.InvSubweps
		2: repository = DataRepository.InvArmor
		3: repository = DataRepository.InvSpells
	var data: Dictionary = repository[grid[current_tab].get_child(index[current_tab]).name]
	get_node("Description/Sprite").texture = load(data["icon"])
	get_node("Description/Name").text = data.name
	get_node("Description/DescText").text = data.description

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
	style.bg_color = Color(44.0/255, 44.0/255, 44.0/255, 1)
	return style

func create_style_selected() -> StyleBox:
	var style = StyleBoxFlat.new()
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.border_color = Color(252.0/255, 248.0/255, 252.0/255, 1)
	style.bg_color = Color(0,0,0,0)
	return style

func create_style_equipped() -> StyleBox:
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(3)
	style.bg_color = Color(96.0/255, 96.0/255, 96.0/255, 1)
	return style
