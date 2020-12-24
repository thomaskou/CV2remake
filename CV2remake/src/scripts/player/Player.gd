extends KinematicBody2D

################################################################################
# Constants
################################################################################

### STATES

enum PlayerStates {
	DEFAULT,
	GROUND, GROUND_ATK, GROUND_DASH, HURT_GROUND,
	AIR, AIR_ATK, AIR_DASH, SJUMP, HURT_AIR,
	CROUCH, CROUCH_ATK, SLIDE, HURT_CROUCH, CROUCH_STUN,
}

enum PlayerFacingDir {
	LEFT, RIGHT,
}


### MOVEMENT CONSTANTS

const JUMP_VELOCITY: float = 310.0
const DJUMP_VELOCITY: float = 250.0
const GRAVITY: float = 14.0
const FAST_GRAVITY: float = 160.0
const AIR_FRICTION: float = 20.0
const TERMINAL_VELOCITY: float = 500.0
const COYOTE_TIME: int = 5

const WALK_SPEED: int = 120
const GROUND_FRICTION: float = 50.0

const SLIDE_TIME: int = 12
const SLIDE_SPEED: int = 220
const SLIDE_FRICTION: float = 20.0
const SLIDE_STUN_TIME: int = 4


################################################################################
# Variables
################################################################################

onready var GameState: Node = get_node("/root/Main/GameState")
onready var SpriteHandler: Node = $SpriteHandler

export onready var state: int = PlayerStates.DEFAULT
# The player's state exactly one frame prior; useful for remembering state transitions
onready var previous_state: int = PlayerStates.DEFAULT

var del: float


### INPUT VARIABLES

var input_left: bool
var input_right: bool
var input_up: bool
var input_down: bool

var input_jump: bool
var input_jump_press: bool

var input_debug1_press: bool


### MOVEMENT VARIABLES

export onready var velocity: Vector2 = Vector2(0, 0)

onready var fast_fall: bool = false
onready var coyote_time: int = -1
var jump_count: int

onready var slide_timer: int = 0
onready var crouch_stun_timer: int = 0


### MISCELLANEOUS VARIABLES

onready var facing_dir: int = PlayerFacingDir.RIGHT


################################################################################
# Ready
################################################################################

func _ready():
	reset_jump_count()


################################################################################
# Methods
################################################################################

### CONDITIONS

func on_ground() -> bool:
	return test_move(transform, Vector2(0,0.9))

func on_semi_solid_ground() -> bool:
	return on_ground() and check_semi_solid_at_tile_positions([Vector2(-5.9,0), Vector2(5.9,0)])

func under_ceiling() -> bool:
	if test_move(transform, Vector2(0,-0.9)):
		return test_move(transform, Vector2(0.1,-0.9))
	return false


### HELPERS

func get_room_collision() -> Node:
	return get_node("/root/Main/Gameplay/Area/Room/Collision")

func get_tile_id_at_player_displacement(tile_map: TileMap, displacement: Vector2) -> int:
	var Room: Node = get_node("/root/Main/Gameplay/Area/Room")
	var col_position: Vector2 = tile_map.world_to_map(position + displacement - tile_map.position - Room.position)
	return tile_map.get_cell(col_position.x, col_position.y)

func tile_is_none_or_semi_solid(tile_set: TileSet, tile_id: int) -> bool:
	# NOTE: Assumes one-way shape ID is index 0 in the tile.
	return tile_id == -1 or tile_set.tile_get_shape_one_way(tile_id, 0)

func check_semi_solid_at_tile_positions(displacements: Array) -> bool:
	var collider: TileMap = get_room_collision()
	for displacement in displacements:
		var tile_id: int = get_tile_id_at_player_displacement(collider, displacement)
		if !tile_is_none_or_semi_solid(collider.tile_set, tile_id):
			return false
	return true


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

func set_downward_slope_velocity(delta: float) -> void:
	var test_y = round(abs(velocity.x))
	while test_move(transform, delta * Vector2(round(velocity.x), round(test_y))):
		if test_y <= 0:
			break
		test_y -= 1
	velocity.y = test_y


### GROUND MOVEMENT

func set_velocity_on_ground(speed: int, delta: float) -> void:
	if !input_left and !input_right:
		ground_friction()
	else:
		velocity.x = speed * (int(input_right) - int(input_left))
	set_downward_slope_velocity(delta)

func ground_friction() -> void:
	if velocity.x != 0.0:
		velocity.x -= sign(velocity.x) * min(GROUND_FRICTION, abs(velocity.x))

func move_on_ground() -> void:
	move_and_slide_with_snap(velocity.round(), Vector2(0,-1))


### AIR MOVEMENT

func gravity() -> void:
	if velocity.y < TERMINAL_VELOCITY:
		velocity.y += (min(FAST_GRAVITY, abs(velocity.y)) if fast_fall else GRAVITY)
	elif velocity.y > TERMINAL_VELOCITY:
		velocity.y = TERMINAL_VELOCITY

func set_velocity_in_air(speed: int) -> void:
	if under_ceiling() and velocity.y < 0:
		reset_vspeed()
	if !input_left and !input_right:
		air_friction()
	else:
		velocity.x = speed * (int(input_right) - int(input_left))
	gravity()

func air_friction() -> void:
	if velocity.x != 0.0:
		velocity.x -= sign(velocity.x) * min(AIR_FRICTION, abs(velocity.x))

func move_in_air() -> void:
	move_and_slide(velocity.round(), Vector2(0,-1))

func do_coyote_time() -> void:
	if coyote_time >= 0:
		coyote_time -= 1
	if coyote_time == 0:
		jump_count -= 1


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
		coyote_time = -1


### CROUCHING

func can_uncrouch() -> bool:
	return check_semi_solid_at_tile_positions([Vector2(-5.9,-27.9), Vector2(0,-27.9), Vector2(5.9,-27.9)])

func set_velocity_in_air_while_crouching() -> void:
	if !on_ground():
		if under_ceiling() and velocity.y < 0:
			reset_vspeed()
		air_friction()
		gravity()
	else:
		reset_vspeed()

func start_crouch_stun(timer: int) -> void:
	state = PlayerStates.CROUCH_STUN
	crouch_stun_timer = timer

func do_crouch_stun_timer() -> void:
	if crouch_stun_timer > 0:
		crouch_stun_timer -= 1


### SLIDING

func begin_slide() -> void:
	state = PlayerStates.SLIDE
	slide_timer = SLIDE_TIME
	match facing_dir:
		PlayerFacingDir.LEFT: velocity.x = SLIDE_SPEED * -1
		PlayerFacingDir.RIGHT: velocity.x = SLIDE_SPEED

func do_slide_timer() -> void:
	if slide_timer > 0:
		slide_timer -= 1

func slide_friction() -> void:
	if velocity.x != 0.0:
		velocity.x -= sign(velocity.x) * min(SLIDE_FRICTION, abs(velocity.x))

func set_velocity_while_sliding(speed: int, delta: float) -> void:
	if slide_timer <= 0:
		slide_friction()
	set_downward_slope_velocity(delta)


### APPEARANCE

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

func snap_to_ground_or_fall(delta: float) -> void:
	var collision = move_and_collide(delta * Vector2(0, abs(velocity.x)))
	if !is_instance_valid(collision):
		move_and_collide(delta * Vector2(0, abs(velocity.x) * -1))
		reset_vspeed()
		coyote_time = COYOTE_TIME
		if can_uncrouch():
			state = PlayerStates.AIR
		else:
			state = PlayerStates.CROUCH

func snap_to_ground_or_fall_after_slide() -> void:
	var collision = move_and_collide(Vector2(0, 5))
	if !is_instance_valid(collision):
		move_and_collide(Vector2(0, -5))
		reset_vspeed()
		coyote_time = COYOTE_TIME
		if can_uncrouch():
			state = PlayerStates.AIR

func slide_or_drop() -> void:
	if can_uncrouch() and on_semi_solid_ground():
		move_local_y(1)
		jump_count -= 1
		state = PlayerStates.AIR
		return
	if GameState.has_slide:
		begin_slide()

func crouch_transitions() -> void:
	if !on_ground():
		if can_uncrouch():
			state = PlayerStates.AIR
	else:
		if !input_down and can_uncrouch():
			state = PlayerStates.GROUND
		elif input_jump_press:
			slide_or_drop()


################################################################################
# Process
################################################################################

func _physics_process(delta):
	
	del = delta * 60
	
	
	### SETTING INPUT VARIABLES
	
	input_left = Input.is_action_pressed("input_left")
	input_right = Input.is_action_pressed("input_right")
	input_up = Input.is_action_pressed("input_up")
	input_down = Input.is_action_pressed("input_down")
	
	input_jump = Input.is_action_pressed("input_jump")
	input_jump_press = Input.is_action_just_pressed("input_jump")
	
	input_debug1_press = Input.is_action_just_pressed("input_debug1")
	
	
	### STATE TRANSITIONS
	
	previous_state = state
	var forced_sprite_update = false
	
	match state:
		
		PlayerStates.DEFAULT:
			state = PlayerStates.AIR
			
		PlayerStates.AIR:
			if (on_ground()
					and (previous_state != PlayerStates.CROUCH or !on_semi_solid_ground())
					and velocity.y >= 0.0):
				state = PlayerStates.GROUND
		
		PlayerStates.GROUND:
			if !on_ground():
				snap_to_ground_or_fall(delta)
			if input_jump_press:
				state = PlayerStates.AIR
			elif input_down:
				state = PlayerStates.CROUCH
		
		PlayerStates.CROUCH:
			crouch_transitions()
		
		PlayerStates.CROUCH_STUN:
			if crouch_stun_timer <= 0:
				crouch_stun_timer = 0
				state = PlayerStates.CROUCH
				crouch_transitions()
		
		PlayerStates.SLIDE:
			if !on_ground():
				snap_to_ground_or_fall(delta)
			elif velocity.x == 0:
				start_crouch_stun(SLIDE_STUN_TIME)
				SpriteHandler.update_sprite()
				forced_sprite_update = true
				snap_to_ground_or_fall_after_slide()
	
	
	### SPRITES
	if forced_sprite_update == true:
		forced_sprite_update = false
	else:
		SpriteHandler.update_sprite()
	
	
	### STATE FUNCTIONALITY
	
	match state:
		
		PlayerStates.AIR:
			set_fast_fall()
			do_coyote_time()
			jump_after_input()
			set_velocity_in_air(WALK_SPEED)
			move_in_air()
			set_facing_dir_movement()
		
		PlayerStates.GROUND:
			reset_jump_count()
			reset_vspeed()
			set_velocity_on_ground(WALK_SPEED, delta)
			move_on_ground()
			set_facing_dir_movement()
		
		PlayerStates.CROUCH:
			reset_jump_count()
			reset_hspeed()
			set_velocity_in_air_while_crouching()
			move_in_air()
			set_facing_dir_static()
		
		PlayerStates.CROUCH_STUN:
			do_crouch_stun_timer()
			reset_jump_count()
			reset_hspeed()
			set_velocity_in_air_while_crouching()
			move_in_air()
		
		PlayerStates.SLIDE:
			reset_jump_count()
			reset_vspeed()
			do_slide_timer()
			set_velocity_while_sliding(SLIDE_SPEED, delta)
			move_on_ground()
	
	
	### STATE-INDEPENDENT FUNCTIONALITY
	round_position()
