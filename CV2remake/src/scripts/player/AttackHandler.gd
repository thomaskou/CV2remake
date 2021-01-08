extends Node


################################################################################
# Constants & variables
################################################################################

const TRAIL_SPRITE_PATH: String = "res://src/scenes/misc/TrailSprite.tscn"
const WEAPON_FRONT_TYPES: Array = ["strike", "slash", "swing1"]
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

var weapon_container: Node2D
var weapon: Node2D
var weapon_sprite: Sprite
var ghost_sprite: Sprite
var arm_sprite: Sprite
export var weapon_data: Dictionary

var current_frame: int
var current_portion_index: int


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
	if Player.has_node("WeaponContainer"):
		var existing_weapon = Player.get_node("WeaponContainer")
		Player.remove_child(existing_weapon)
		existing_weapon.queue_free()

func create_weapon() -> void:
	weapon_container = load("res://src/scenes/weapon/WeaponContainer.tscn").instance()
	weapon = weapon_container.get_node("Weapon")
	weapon_sprite = weapon.get_node("Sprite")
	ghost_sprite = weapon.get_node("SpriteGhost")
	arm_sprite = weapon.get_node("SpriteArm")
	Player.add_child(weapon_container)

func initial_sprite_setup() -> void:
	weapon_container.z_index = 1 if weapon_data["type"] in WEAPON_FRONT_TYPES else -1
	current_portion_index = -1

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
	if is_instance_valid(weapon_container):
		# Get current frame and don't process if frame is outside of animation range
		current_frame = int(max(0, weapon_data["sprite"]["total_frames"] - ceil(60*TimerAttack.time_left) - 1))
		if current_frame >= weapon_data["sprite"]["total_frames"]: return
		
		# Update existing sprite information
		if !get_player_sprite(): return
		
		# Get previous weapon sprite parameters (for interpolated trail effect)
		var previous_portion_index: int = current_portion_index
		var previous_texture: Texture = weapon_sprite.texture
		var previous_flipped: bool = weapon_sprite.flip_h
		var previous_offset: Vector2 = weapon_sprite.offset
		var previous_position: Vector2 = weapon.position
		var previous_angle: float = weapon.rotation_degrees
		var previous_alpha: float = weapon.modulate.a
		
		# Get animation portion data for weapon
		current_portion_index = weapon_data["sprite"]["frame_to_portion"][current_frame]
		var current_portion: Dictionary = weapon_data["sprite"]["frames"][current_portion_index]
		var changed_portions: bool = previous_portion_index != current_portion_index
		
		# Get current frame relative to WEAPON and PLAYER animation portions
		var current_portion_frame: int = current_frame - current_portion["cumulative_time"]
		
		# Set player sprite
		var current_player_sprite_index: int = get_equivalent_element_in_array(current_portion["player_frames"], current_portion_frame, current_portion["time"])
		var current_player_sprite: Dictionary = current_player_textures[current_player_sprite_index]
		current_sprite.texture = load(current_player_sprite["sprite"])
		current_sprite.offset = Vector2(current_player_sprite["offset"][0], current_player_sprite["offset"][1])
		
		# Get sprite centers/origins
		var current_weapon_sprite_index: int = weapon_data["sprite"]["frame_to_sprite"][current_frame]
		var current_weapon_center_index: int = min(current_weapon_sprite_index, weapon_data["sprite"]["center"].size()-1)
		var weapon_sprite_center: Vector2 = Vector2(
			weapon_data["sprite"]["center"][current_weapon_center_index][0],
			weapon_data["sprite"]["center"][current_weapon_center_index][1]
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
			else: weapon.rotation_degrees = current_portion["angle"][0]
			if flipped: weapon.rotation_degrees *= -1
		else: weapon.rotation_degrees = 0
		
		# Set opacity of weapon
		var alpha: float = 1.0
		if current_portion.has("opacity"):
			if current_portion["opacity"].size() == 2:
				var first_alpha: int = current_portion["opacity"][0]
				var second_alpha: int = current_portion["opacity"][1]
				alpha = interpolate(current_portion_frame, current_portion["time"], first_alpha, second_alpha)
			else: alpha = current_portion["opacity"][0]
		weapon.modulate.a = alpha
		
		# Draw ghost effect
		var ghost_frames: int = weapon_data["sprite"]["effects"]["ghost_frames"]
		if ghost_frames != -1:
			draw_ghost_sprite(ghost_frames, weapon_sprite.texture, weapon_sprite.flip_h, weapon_sprite.offset)
		
		# Get trail variables
		var trail_overlay: Color = Color(weapon_data["sprite"]["effects"]["trail_overlay"])
		var trail_alpha: float = weapon_data["sprite"]["effects"]["trail_alpha"]
		
		# Draw trail sprites
		if current_portion.has("trail"):
			if current_portion["trail"].has("step") and current_frame % int(current_portion["trail"]["step"]) == 0:
				create_trail_sprite(
					current_portion["trail"]["frames"], weapon_sprite.texture, weapon_sprite.flip_h,
					weapon.position, weapon_sprite.offset, weapon.rotation_degrees, alpha,
					trail_alpha, trail_overlay
				)
			elif current_portion["trail"].has("num"):
				draw_interpolated_trail(
					current_portion["trail"]["num"],
					current_portion["trail"]["frames"],
					weapon_sprite.texture, weapon_sprite.flip_h,
					[previous_position, weapon.position],
					[previous_offset, weapon_sprite.offset],
					[previous_angle, weapon.rotation_degrees],
					[previous_alpha, alpha],
					trail_alpha, trail_overlay
				)
				
		
		# Draw trail for previous fading frame
		if changed_portions and current_portion.has("fade_previous"):
			create_trail_sprite(
				current_portion["fade_previous"], previous_texture, previous_flipped,
				previous_position, previous_offset, previous_angle, previous_alpha,
				trail_alpha, trail_overlay
			)
		
		# Draw interpolated trail sprites
		if changed_portions and current_portion.has("interpolate_trail"):
			draw_interpolated_trail(
				current_portion["interpolate_trail"]["num"],
				current_portion["interpolate_trail"]["frames"],
				weapon_sprite.texture, weapon_sprite.flip_h,
				[previous_position, weapon.position],
				[previous_offset, weapon_sprite.offset],
				[previous_angle, weapon.rotation_degrees],
				[previous_alpha, alpha],
				trail_alpha, trail_overlay
			)
		
		# Show arm if weapon is swing type 1
		arm_sprite.visible = weapon_data["type"] == "swing1"

func get_equivalent_index_in_array(array: Array, index: int, total: int) -> int:
	return int(floor(array.size() * index / total))

func get_equivalent_element_in_array(array: Array, index: int, total: int):
	return array[get_equivalent_index_in_array(array, index, total)]

func interpolate(num: float, denom: float, begin: float, end: float) -> float:
	return begin+(end-begin)*num/denom

func interpolate_vec(num: float, denom: float, begin: Vector2, end: Vector2) -> Vector2:
	return Vector2(
		interpolate(num, denom, begin.x, end.x),
		interpolate(num, denom, begin.y, end.y)
	)

func draw_ghost_sprite(frames: int, texture: Texture, flipped: bool, offset: Vector2) -> void:
	# TODO: yield function does not pause when game pauses
	yield(get_tree().create_timer(frames/60.0), "timeout")
	if is_instance_valid(weapon_container):
		var flip_vector: Vector2 = Vector2(-1 if flipped else 1, 1)
		ghost_sprite.texture = texture
		ghost_sprite.flip_h = flipped
		ghost_sprite.offset = offset + Vector2(-2,-2)*flip_vector

func create_trail_sprite(
	frames: int, texture: Texture, flipped: bool, position: Vector2, offset: Vector2,
	angle: float, alpha: float, trail_alpha: float, overlay: Color
) -> void:
	var trail: Sprite = load(TRAIL_SPRITE_PATH).instance()
	trail.texture = texture
	trail.flip_h = flipped
	trail.position = position
	trail.offset = offset
	trail.rotation_degrees = angle
	trail.modulate.a = trail_alpha * alpha
	trail.material.set_shader_param("overlay", overlay)
	weapon_container.add_child(trail)
	trail.begin(frames)

func draw_interpolated_trail(
	num: int, frames: int, texture: Texture, flipped: bool, positions: Array, offsets: Array,
	angles: Array, alphas: Array, trail_alpha: float, overlay: Color
):
	for i in range(num):
		create_trail_sprite(
			frames, texture, flipped,
			interpolate_vec(i+1, num, positions[0], positions[1]),
			interpolate_vec(i+1, num, offsets[0], offsets[1]),
			interpolate(i+1, num, angles[0], angles[1]),
			interpolate(i+1, num, alphas[0], alphas[1]),
			trail_alpha, overlay
		)


################################################################################
# End attack
################################################################################

func force_stop_attack() -> void:
	TimerAttack.stop()
	TimerAttackStun.stop()
	_on_timeout_attack()

func _on_timeout_attack() -> void:
	if is_instance_valid(weapon_container):
		Player.remove_child(weapon_container)
		weapon_container.queue_free()
