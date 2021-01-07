extends KinematicBody2D

################################################################################
# Constants
################################################################################

### STATES

enum PlayerStates {
	DEFAULT,
	GROUND, GROUND_ATK, GROUND_ATK_STUN, GROUND_DASH, HURT_GROUND,
	AIR, AIR_ATK, AIR_ATK_STUN, AIR_DASH, SJUMP, HURT_AIR,
	CROUCH, CROUCH_ATK, CROUCH_ATK_STUN, SLIDE, HURT_CROUCH, CROUCH_STUN,
}

enum PlayerFacingDir {
	LEFT, RIGHT,
}


### MOVEMENT CONSTANTS

const COLLISION_CHECK_MARGIN: float = 0.1

const JUMP_VELOCITY: float = 310.0
const DJUMP_VELOCITY: float = 250.0
const GRAVITY: float = 14.0
const FAST_GRAVITY: float = 160.0
const AIR_FRICTION: float = 20.0
const TERMINAL_VELOCITY: float = 500.0
const COYOTE_TIME_FRAMES: int = 5

const WALK_SPEED: int = 120
const GROUND_FRICTION: float = 20.0

const SLIDE_FRICTIONLESS_FRAMES: int = 12
const SLIDE_SPEED: int = 220
const SLIDE_FRICTION: float = 20.0
const SLIDE_STUN_FRAMES: int = 4


################################################################################
# Variables
################################################################################

onready var GameState: Node = get_node("/root/Main/GameState")

export onready var state: int = PlayerStates.DEFAULT
# The player's state exactly one frame prior; useful for remembering state transitions
onready var previous_state: int = PlayerStates.DEFAULT

var del: float

var input_left: bool
var input_right: bool
var input_up: bool
var input_down: bool
var input_jump: bool
var input_jump_press: bool
var input_attack_press: bool

onready var facing_dir: int = PlayerFacingDir.RIGHT
onready var forced_sprite_update: bool = false

export onready var velocity: Vector2 = Vector2(0, 0)
onready var fast_fall: bool = false
var jump_count: int


################################################################################
# Ready
################################################################################

func _ready():
	connect_timers()
	reset_jump_count()


################################################################################
# Input
################################################################################

func get_inputs() -> void:
	input_left = Input.is_action_pressed("input_left")
	input_right = Input.is_action_pressed("input_right")
	input_up = Input.is_action_pressed("input_up")
	input_down = Input.is_action_pressed("input_down")
	input_jump = Input.is_action_pressed("input_jump")
	input_jump_press = Input.is_action_just_pressed("input_jump")
	input_attack_press = Input.is_action_just_pressed("input_attack")


################################################################################
# Movement helper methods
################################################################################

### CONDITIONS

func on_ground() -> bool:
	return test_move(transform, Vector2(0, 1 - COLLISION_CHECK_MARGIN))

func on_semi_solid_ground() -> bool:
	var collision_rect: Rect2 = get_collision_rect($SpriteHandler.get_collision())
	var lower_left: Vector2 = collision_rect.position + Vector2(COLLISION_CHECK_MARGIN, collision_rect.size.y)
	var lower_right: Vector2 = collision_rect.end - Vector2(COLLISION_CHECK_MARGIN, 0)
	return on_ground() and is_tile_semi_solid_at_displacements([lower_left, lower_right])

func can_uncrouch() -> bool:
	var collision_rect: Rect2 = get_collision_rect($CollisionNormal)
	var upper_left: Vector2 = collision_rect.position + Vector2(COLLISION_CHECK_MARGIN, COLLISION_CHECK_MARGIN)
	var upper_middle: Vector2 = collision_rect.position + Vector2(collision_rect.size.x / 2, COLLISION_CHECK_MARGIN)
	var upper_right: Vector2 = collision_rect.position + Vector2(collision_rect.size.x - COLLISION_CHECK_MARGIN, COLLISION_CHECK_MARGIN)
	return is_tile_semi_solid_at_displacements([upper_left, upper_middle, upper_right])

func not_in_air() -> bool:
	return (on_ground()
		and (previous_state != PlayerStates.CROUCH or !on_semi_solid_ground())
		and velocity.y >= 0.0)

### HELPERS

func get_collision_rect(collision: CollisionShape2D) -> Rect2:
	var extents: Vector2 = collision.shape.extents
	return Rect2(Vector2(-extents.x, -2*extents.y), 2*extents)

func get_room_collision() -> Node:
	return get_node("/root/Main/Gameplay/Area/Room/Collision")

func get_tile_id_at_displacement(tile_map: TileMap, displacement: Vector2) -> int:
	var Room: Node = get_node("/root/Main/Gameplay/Area/Room")
	if !is_instance_valid(Room):
		return -1
	var col_position: Vector2 = tile_map.world_to_map(position + displacement - tile_map.position - Room.position)
	return tile_map.get_cell(col_position.x, col_position.y)

func tile_is_none_or_semi_solid(tile_set: TileSet, tile_id: int) -> bool:
	# NOTE: Assumes one-way shape ID is index 0 in the tile.
	return tile_id == -1 or tile_set.tile_get_shape_one_way(tile_id, 0)

func is_tile_semi_solid_at_displacements(displacements: Array) -> bool:
	var collider: TileMap = get_room_collision()
	for displacement in displacements:
		var tile_id: int = get_tile_id_at_displacement(collider, displacement)
		if !tile_is_none_or_semi_solid(collider.tile_set, tile_id):
			return false
	return true


################################################################################
# Movement
################################################################################

### GENERAL

func round_position() -> void:
	position.x = round(position.x)
	position.y = round(position.y)

func reset_hspeed() -> void:
	if velocity.x != 0:
		velocity.x = 0

func reset_vspeed() -> void:
	if velocity.y != 0:
		velocity.y = 0


### MOVE

func force_move() -> void:
	move_local_x(round(velocity.x))
	move_local_y(round(velocity.y))

func move_on_ground() -> void:
	move_and_slide_with_snap(velocity.round(), Vector2(0,-1))

func move_in_air() -> void:
	move_and_slide(velocity.round(), Vector2(0,-1))


### VELOCITY & ACCELERATION

func set_velocity(speed: int, friction: int, check_input: bool, on_ground: bool) -> void:
	if !on_ground and (is_on_ceiling() and velocity.y < 0): reset_vspeed()
	if !check_input or (!input_left and !input_right): friction(friction)
	else: velocity.x = speed * (int(input_right) - int(input_left))
	if on_ground: manipulate_slope_velocity()
	else: gravity()

func set_velocity_while_sliding() -> void:
	if $TimerSlideFrictionless.is_stopped():
		friction(SLIDE_FRICTION)
	manipulate_slope_velocity()

func manipulate_slope_velocity() -> void:
	var test_y = round(abs(velocity.x))
	while test_move(transform, del * Vector2(round(velocity.x), round(test_y))):
		if test_y < -abs(velocity.x) * 1.1:
			test_y = 0
			break
		test_y -= 1
	velocity.y = test_y if test_y >= 0 else test_y * 0.5

func gravity() -> void:
	if velocity.y < TERMINAL_VELOCITY:
		velocity.y += (min(FAST_GRAVITY, abs(velocity.y)) if fast_fall else GRAVITY)
	elif velocity.y > TERMINAL_VELOCITY:
		velocity.y = TERMINAL_VELOCITY

func friction(friction: int) -> void:
	if velocity.x != 0.0:
		velocity.x -= sign(velocity.x) * min(friction, abs(velocity.x))


### JUMPING

func reset_jump_count() -> void:
	jump_count = GameState.numjumps

func set_fast_fall() -> void:
	if !fast_fall and velocity.y < 0 and !input_jump:
		fast_fall = true
	elif fast_fall and velocity.y >= 0:
		fast_fall = false

func jump_after_input() -> void:
	if input_jump_press and jump_count > 0 and previous_state != PlayerStates.CROUCH:
		if !GameState.has_djumps or jump_count == 2:
			velocity.y = -JUMP_VELOCITY
		else:
			velocity.y = -DJUMP_VELOCITY
		jump_count -= 1
		fast_fall = false
		stop_coyote_time()


### SLIDING

func begin_slide() -> void:
	state = PlayerStates.SLIDE
	start_slide_frictionless_timer(SLIDE_FRICTIONLESS_FRAMES)
	match facing_dir:
		PlayerFacingDir.LEFT: velocity.x = SLIDE_SPEED * -1
		PlayerFacingDir.RIGHT: velocity.x = SLIDE_SPEED


### APPEARANCE (FACING DIRECTION)

func set_facing_dir_movement() -> void:
	if velocity.x < 0.0:
		facing_dir = PlayerFacingDir.LEFT
	if velocity.x > 0.0:
		facing_dir = PlayerFacingDir.RIGHT

func set_facing_dir_static() -> void:
	if input_left and !input_right:
		facing_dir = PlayerFacingDir.LEFT
	if input_right and !input_left:
		facing_dir = PlayerFacingDir.RIGHT


################################################################################
# State transitions
################################################################################

func snap_to_ground_or_fall(snap_distance: float, air_state: int, crouch_state: int) -> void:
	var collision = move_and_collide(Vector2(0, snap_distance))
	if !is_instance_valid(collision):
		move_and_collide(del * Vector2(0, -snap_distance))
		reset_vspeed()
		start_coyote_time(COYOTE_TIME_FRAMES)
		state = air_state if can_uncrouch() else crouch_state

func slide_or_drop() -> void:
	if can_uncrouch() and on_semi_solid_ground():
		move_local_y(1)
		jump_count -= 1
		state = PlayerStates.AIR
		return
	if GameState.has_slide:
		begin_slide()


################################################################################
# Timers
################################################################################

func connect_timers() -> void:
	$TimerAttack.connect("timeout", self, "_on_timeout_attack")
	$TimerAttackStun.connect("timeout", self, "_on_timeout_attack_stun")
	$TimerCoyote.connect("timeout", self, "_on_timeout_coyote")
	$TimerCrouchStun.connect("timeout", self, "_on_timeout_crouch_stun")
	$TimerSlideFrictionless.connect("timeout", self, "_on_timeout_slide_frictionless")


### ATTACK

func _on_timeout_attack() -> void:
	$TimerAttack.stop()
	if $AttackHandler.weapon_data["delay"] > 0:
		match state:
			PlayerStates.GROUND_ATK: state = PlayerStates.GROUND_ATK_STUN
			PlayerStates.AIR_ATK: state = PlayerStates.AIR_ATK_STUN
			PlayerStates.CROUCH_ATK: state = PlayerStates.CROUCH_ATK_STUN
		$SpriteHandler.update_sprite()
		$TimerAttackStun.start($AttackHandler.weapon_data["delay"]/60.0)
	else:
		_on_timeout_attack_stun()

func _on_timeout_attack_stun() -> void:
	$TimerAttackStun.stop()
	match state:
		PlayerStates.GROUND_ATK, PlayerStates.GROUND_ATK_STUN: state = PlayerStates.GROUND
		PlayerStates.AIR_ATK, PlayerStates.AIR_ATK_STUN: state = PlayerStates.AIR
		PlayerStates.CROUCH_ATK, PlayerStates.CROUCH_ATK_STUN: state = PlayerStates.CROUCH
	$SpriteHandler.update_sprite()


### COYOTE TIME

func start_coyote_time(frames: int) -> void:
	$TimerCoyote.start(frames/60.0)

func stop_coyote_time() -> void:
	$TimerCoyote.stop()

func _on_timeout_coyote() -> void:
	$TimerCoyote.stop()
	jump_count -= 1


### CROUCH STUN

func start_crouch_stun(frames: int) -> void:
	state = PlayerStates.CROUCH_STUN
	$TimerCrouchStun.start(frames/60.0)

func _on_timeout_crouch_stun() -> void:
	$TimerCrouchStun.stop()
	state = PlayerStates.CROUCH


### SLIDE FRICTIONLESS

func start_slide_frictionless_timer(frames: int) -> void:
	$TimerSlideFrictionless.start(frames/60.0)

func _on_timeout_slide_frictionless() -> void:
	$TimerSlideFrictionless.stop()


################################################################################
# Miscellaneous
################################################################################

func force_sprite_update() -> void:
	forced_sprite_update = true
	$SpriteHandler.update_sprite()

func stop_attack_if_not_attacking() -> void:
	if !(state in [PlayerStates.GROUND_ATK, PlayerStates.AIR_ATK, PlayerStates.CROUCH_ATK]):
		$AttackHandler.force_stop_attack()


################################################################################
# Process
################################################################################

func _physics_process(delta):
	
	del = delta
	get_inputs()
	
	
	### STATE-SPECIFIC FUNCTIONALITY, PRE-TRANSITION
	
	match state:
		PlayerStates.CROUCH: set_facing_dir_static()
	
	
	### STATE TRANSITIONS
	
	previous_state = state
	var wep_stun: bool = $AttackHandler.weapon_data.has("stun") and $AttackHandler.weapon_data["stun"]
	
	match state:
		
		PlayerStates.DEFAULT: state = PlayerStates.AIR
			
		PlayerStates.AIR:
			if not_in_air():
				state = PlayerStates.GROUND
			elif input_attack_press:
				state = PlayerStates.AIR_ATK
				set_facing_dir_static()
				force_sprite_update()
				$AttackHandler.attack()
		
		PlayerStates.AIR_ATK:
			if not_in_air():
				if wep_stun: state = PlayerStates.GROUND_ATK
				else: state = PlayerStates.GROUND
				stop_attack_if_not_attacking()
		
		PlayerStates.AIR_ATK_STUN:
			if not_in_air():
				state = PlayerStates.GROUND_ATK_STUN if wep_stun else PlayerStates.GROUND
		
		PlayerStates.GROUND:
			if !on_ground():
				snap_to_ground_or_fall(del*abs(velocity.x), PlayerStates.AIR, PlayerStates.CROUCH)
			elif input_attack_press:
				state = PlayerStates.GROUND_ATK
				set_facing_dir_static()
				force_sprite_update()
				$AttackHandler.attack()
			elif input_jump_press: state = PlayerStates.AIR
			elif input_down: state = PlayerStates.CROUCH
		
		PlayerStates.GROUND_ATK:
			if !on_ground():
				snap_to_ground_or_fall(del*abs(velocity.x), PlayerStates.AIR_ATK, PlayerStates.CROUCH_ATK)
				stop_attack_if_not_attacking()
		
		PlayerStates.GROUND_ATK_STUN:
			if !on_ground():
				var air_state: int = PlayerStates.AIR_ATK_STUN if wep_stun else PlayerStates.AIR
				snap_to_ground_or_fall(del*abs(velocity.x), air_state, PlayerStates.CROUCH_ATK_STUN)
		
		PlayerStates.CROUCH:
			if !on_ground():
				if can_uncrouch(): state = PlayerStates.AIR
			elif input_attack_press:
				state = PlayerStates.CROUCH_ATK
				set_facing_dir_static()
				force_sprite_update()
				$AttackHandler.attack()
			elif !input_down and can_uncrouch(): state = PlayerStates.GROUND
			elif input_jump_press: slide_or_drop()
		
		PlayerStates.CROUCH_ATK:
			if !on_ground() and can_uncrouch():
				state = PlayerStates.AIR
				stop_attack_if_not_attacking()
		
		PlayerStates.CROUCH_ATK_STUN:
			if !on_ground() and can_uncrouch():
				state = PlayerStates.AIR_ATK_STUN if wep_stun else PlayerStates.AIR
		
		PlayerStates.CROUCH_STUN:
			if !on_ground() and can_uncrouch():
				state = PlayerStates.AIR
		
		PlayerStates.SLIDE:
			if !on_ground():
				snap_to_ground_or_fall(del*abs(velocity.x), PlayerStates.AIR, PlayerStates.CROUCH)
			if velocity.x == 0:
				start_crouch_stun(SLIDE_STUN_FRAMES)
				force_sprite_update()
				snap_to_ground_or_fall(5, PlayerStates.AIR, state)
	
	
	### SPRITES
	
	if forced_sprite_update == true:
		forced_sprite_update = false
	else:
		$SpriteHandler.update_sprite()
	
	
	### MULTI-STATE FUNCTIONALITY, POST_TRANSITION
	
	if state != PlayerStates.AIR:
		reset_jump_count()
		stop_coyote_time()
	
	
	### STATE-SPECIFIC FUNCTIONALITY, POST_TRANSITION
	
	match state:
		
		PlayerStates.AIR:
			set_fast_fall()
			jump_after_input()
			set_velocity(WALK_SPEED, AIR_FRICTION, true, false)
			move_in_air()
			set_facing_dir_movement()
		
		PlayerStates.AIR_ATK, PlayerStates.AIR_ATK_STUN:
			set_fast_fall()
			set_velocity(WALK_SPEED, AIR_FRICTION, true, false)
			move_in_air()
			
		PlayerStates.GROUND:
			reset_vspeed()
			set_velocity(WALK_SPEED, GROUND_FRICTION, true, true)
			move_on_ground()
			set_facing_dir_movement()
		
		PlayerStates.GROUND_ATK, PlayerStates.GROUND_ATK_STUN:
			set_velocity(WALK_SPEED, GROUND_FRICTION, false, true)
			move_on_ground()
			
		PlayerStates.CROUCH, PlayerStates.CROUCH_STUN, PlayerStates.CROUCH_ATK, PlayerStates.CROUCH_ATK_STUN:
			reset_hspeed()
			if !on_ground(): set_velocity(0, AIR_FRICTION, false, false)
			else: reset_vspeed()
			move_in_air()
			
		PlayerStates.SLIDE:
			reset_vspeed()
			set_velocity_while_sliding()
			move_on_ground()
	
	
	### STATE-INDEPENDENT FUNCTIONALITY
	
	round_position()
