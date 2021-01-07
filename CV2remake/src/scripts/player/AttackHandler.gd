extends Node


################################################################################
# Constants & variables
################################################################################

const WEAPON_FRONT_TYPES: Array = ["strike", "swing1"]
const ARM_OFFSET: Vector2 = Vector2(0, 12)
const GHOST_ALPHA: float = 0.4

onready var DataRepository: Node = get_node("/root/Main/DataRepository")
onready var GameState: Node = get_node("/root/Main/GameState")
onready var Player: Node = get_parent()
onready var TimerAttack: Timer = get_node("../TimerAttack")
onready var TimerAttackStun: Timer = get_node("../TimerAttackStun")

onready var player_textures: Dictionary = DataRepository.DataTextures["player_attack"]
var current_sprite: Sprite
var current_player_textures: Array

var weapon: Node2D
var weapon_sprite: Sprite
var ghost_sprite: Sprite
var arm_sprite: Sprite
export var weapon_data: Dictionary

var current_frame: int


################################################################################
# Ready
################################################################################

func _ready():
	TimerAttack.connect("timeout", self, "_on_timeout_attack")


################################################################################
# Begin attack
################################################################################

func attack() -> void:
	get_data()
	start_attack_timer()
	remove_existing_weapon()
	create_weapon()
	initial_sprite_setup()

func get_data() -> void:
	weapon_data = GameState.get_equipped_weapon()
	get_player_sprite()

func start_attack_timer() -> void:
	TimerAttack.stop()
	TimerAttackStun.stop()
	TimerAttack.start(weapon_data["sprite"]["total_frames"]/60.0)

func remove_existing_weapon() -> void:
	var existing_weapon: Node = Player.get_node("Weapon")
	if is_instance_valid(existing_weapon):
		Player.remove_child(existing_weapon)
		existing_weapon.queue_free()

func create_weapon() -> void:
	weapon = load("res://src/scenes/weapon/Weapon.tscn").instance()
	weapon_sprite = weapon.get_node("Sprite")
	ghost_sprite = weapon.get_node("SpriteGhost")
	arm_sprite = weapon.get_node("SpriteArm")
	Player.add_child(weapon)

func initial_sprite_setup() -> void:
	# Set z-index of weapon
	weapon.z_index = 1 if weapon_data["type"] in WEAPON_FRONT_TYPES else -1

################################################################################
# During attack
################################################################################

func get_player_sprite() -> bool:
	var player_textures_type: String
	match Player.state:
		Player.PlayerStates.GROUND_ATK:
			current_sprite = get_node("../Sprites/AttackStand")
			player_textures_type = "ground"
		Player.PlayerStates.AIR_ATK:
			current_sprite = get_node("../Sprites/AttackJump")
			player_textures_type = "air"
		Player.PlayerStates.CROUCH_ATK:
			current_sprite = get_node("../Sprites/AttackCrouch")
			player_textures_type = "crouch"
		_: return false
	current_player_textures = player_textures[player_textures_type][weapon_data["type"]]
	return true

func _process(_delta):
	if is_instance_valid(weapon):
		# Get current frame and don't process if frame is outside of animation range
		current_frame = int(max(0, weapon_data["sprite"]["total_frames"] - ceil(60*TimerAttack.time_left) - 1))
		if current_frame >= weapon_data["sprite"]["total_frames"]: return
		
		# Update existing sprite information
		if !get_player_sprite(): return
		
		# Get animation portion data for weapon
		var current_portion_index: int = weapon_data["sprite"]["frame_to_portion"][current_frame]
		var current_portion: Dictionary = weapon_data["sprite"]["frames"][current_portion_index]
		
		# Get current frame relative to WEAPON and PLAYER animation portions
		var current_portion_frame: int = current_frame - current_portion["cumulative_time"]
		
		# Set player sprite
		var current_player_sprite_index: int = get_equivalent_element_in_array(current_portion["player_frames"], current_portion_frame, current_portion["time"])
		var current_player_sprite: Dictionary = current_player_textures[current_player_sprite_index]
		current_sprite.texture = load(current_player_sprite["sprite"])
		current_sprite.offset = Vector2(current_player_sprite["offset"][0], current_player_sprite["offset"][1])
		
		# Get sprite centers/origins
		var current_weapon_sprite_index: int = weapon_data["sprite"]["frame_to_sprite"][current_frame]
		var weapon_sprite_center: Vector2 = Vector2(
			weapon_data["sprite"]["center"][current_weapon_sprite_index][0],
			weapon_data["sprite"]["center"][current_weapon_sprite_index][1]
		)
		var player_sprite_center: Vector2 = Vector2(
			current_player_sprite["center"][0],
			current_player_sprite["center"][1]
		)
		
		# Set weapon sprite texture and horizontal flip
		var flipped: bool = Player.facing_dir == Player.PlayerFacingDir.LEFT
		var flip_vector: Vector2 = Vector2(-1 if flipped else 1, 1)
		weapon_sprite.texture = load(weapon_data["sprite"]["path"] + "/" + String(current_weapon_sprite_index) + ".png")
		weapon_sprite.flip_h = flipped
		
		# Set weapon sprite offset
		weapon_sprite.offset = weapon_sprite.texture.get_size()/2 - weapon_sprite_center
		if weapon_data["type"] == "swing1": weapon_sprite.offset -= ARM_OFFSET
		weapon_sprite.offset *= flip_vector
		
		# Set position of weapon
		weapon.position = flip_vector * (
			current_sprite.position + current_sprite.offset + player_sprite_center
			- current_sprite.texture.get_size()/2)
		
		# Set rotation of weapon
		if current_portion.has("angle"):
			if current_portion["angle"].size() == 2:
				var first_angle: int = current_portion["angle"][0]
				var second_angle: int = current_portion["angle"][1]
				weapon.rotation_degrees = interpolate(current_portion_frame, current_portion["time"], first_angle, second_angle)
			else:
				weapon.rotation_degrees = current_portion["angle"][0]
			if flipped: weapon.rotation_degrees *= -1
		else:
			weapon.rotation_degrees = 0
		
		# Set opacity of weapon
		var alpha: float = 1.0
		if current_portion.has("opacity"):
			if current_portion["opacity"].size() == 2:
				var first_alpha: int = current_portion["opacity"][0]
				var second_alpha: int = current_portion["opacity"][1]
				alpha = interpolate(current_portion_frame, current_portion["time"], first_alpha, second_alpha)
			else:
				alpha = current_portion["opacity"][0]
		weapon_sprite.material.set_shader_param("alpha", alpha)
		ghost_sprite.material.set_shader_param("alpha", GHOST_ALPHA * alpha)
		
		# Draw ghost effect
		var ghost_frames: int = weapon_data["sprite"]["effects"]["ghost_frames"]
		if ghost_frames != -1:
			draw_ghost_sprite(ghost_frames, weapon_sprite.texture, weapon_sprite.flip_h, weapon_sprite.offset)
		
		# Show arm if weapon is swing type 1
		arm_sprite.visible = weapon_data["type"] == "swing1"

func get_equivalent_index_in_array(array: Array, index: int, total: int) -> int:
	return int(floor(array.size() * index / total))

func get_equivalent_element_in_array(array: Array, index: int, total: int):
	return array[get_equivalent_index_in_array(array, index, total)]

func interpolate(num: float, denom: float, begin: float, end: float) -> float:
	return begin+(end-begin)*num/denom

func draw_ghost_sprite(frames: int, texture: Texture, flipped: bool, offset: Vector2) -> void:
	# TODO: yield function does not pause when game pauses
	yield(get_tree().create_timer(frames/60.0), "timeout")
	if is_instance_valid(weapon):
		var flip_vector: Vector2 = Vector2(-1 if flipped else 1, 1)
		ghost_sprite.texture = texture
		ghost_sprite.flip_h = flipped
		ghost_sprite.offset = offset + Vector2(-2,-2)*flip_vector


################################################################################
# End attack
################################################################################

func force_stop_attack() -> void:
	TimerAttack.stop()
	TimerAttackStun.stop()
	_on_timeout_attack()

func _on_timeout_attack() -> void:
	if is_instance_valid(weapon):
		Player.remove_child(weapon)
		weapon.queue_free()
