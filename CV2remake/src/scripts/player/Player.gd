extends KinematicBody2D


##### ++++++++++++++++++++++++++++++ CONSTANTS ++++++++++++++++++++++++++++++ #####

### STATES

enum PlayerStates {
	DEFAULT,
	GROUND, AIR, CROUCH,
	GROUND_ATK, AIR_ATK, CROUCH_ATK,
	GROUND_DASH, AIR_DASH, SLIDE, SJUMP,
	HURT,
}


### MOVEMENT CONSTANTS

const JUMP_VELOCITY: float = 280.0
const GRAVITY: float = 15.0
const FAST_GRAVITY: float = 80.0
const AIR_FRICTION: float = 20.0
const TERMINAL_VELOCITY: float = 500.0

const WALK_SPEED: int = 120
const GROUND_FRICTION: float = 50.0


##### ++++++++++++++++++++++++++++++ VARIABLES ++++++++++++++++++++++++++++++ #####

var GameState: Node

var del: float
var state: int


### INPUT VARIABLES

var input_left: bool
var input_right: bool
var input_up: bool
var input_down: bool

var input_jump: bool


### MOVEMENT VARIABLES

var velocity: Vector2

var jump_count: int
var can_jump: bool
var fast_fall: bool


##### +++++++++++++++++++++++++++++ READY ++++++++++++++++++++++++++++++ #####

func _ready() -> void:
	
	GameState = get_node("../State")
	
	state = PlayerStates.DEFAULT
	
	
	### MOVEMENT VARIABLES
	
	velocity = Vector2(0, 0)
	
	reset_jump_count()
	can_jump = false
	fast_fall = false


##### ++++++++++++++++++++++++++++++ METHODS ++++++++++++++++++++++++++++++ #####

### CONDITIONS

func on_ground() -> bool:
	return test_move(transform, Vector2(0,0.9))


### GENERAL

func round_position() -> void:
	move_local_x(round(position.x) - position.x)
	move_local_y(round(position.y) - position.y)


### GROUND MOVEMENT

func get_velocity_on_ground(speed: int, delta: float) -> void:
	
	# standard horizontal movement
	if !input_left && !input_right:
		ground_friction()
	else:
		velocity.x = speed * (int(input_right) - int(input_left))
		
	# slope movement (set downward velocity when moving downhill)
	var test_y = round(abs(velocity.x))
	while test_move(transform, delta * Vector2(round(velocity.x), round(test_y))):
		if test_y == 0:
			break
		test_y -= 1
	velocity.y = test_y

func ground_friction() -> void:
	if velocity.x != 0.0:
		velocity.x -= sign(velocity.x) * min(GROUND_FRICTION, abs(velocity.x))

func move_on_ground(delta: float) -> void:
	move_and_slide_with_snap(velocity.round(), Vector2(0,-1))


### AIR MOVEMENT

func reset_vspeed() -> void:
	if velocity.y != 0:
		velocity.y = 0

func gravity() -> void:
	if velocity.y < TERMINAL_VELOCITY:
#		if fast_fall && (velocity.y + FAST_GRAVITY < 0):
#			velocity.y += FAST_GRAVITY
#		else:
#			velocity.y += GRAVITY
		velocity.y += (min(FAST_GRAVITY, abs(velocity.y)) if fast_fall else GRAVITY)
	elif velocity.y > TERMINAL_VELOCITY:
		velocity.y = TERMINAL_VELOCITY

func get_velocity_in_air(speed: int) -> void:
	if !input_left && !input_right:
		air_friction()
	else:
		velocity.x = speed * (int(input_right) - int(input_left))
	gravity()

func air_friction() -> void:
	if velocity.x != 0.0:
		velocity.x -= sign(velocity.x) * min(AIR_FRICTION, abs(velocity.x))

func move_in_air() -> void:
	move_and_slide(velocity.round(), Vector2(0,-1))


### JUMPING

func reset_jump_count() -> void:
	jump_count = GameState.jumps

func set_can_jump() -> void:
	if !can_jump && !input_jump && jump_count > 0:
		can_jump = true

func set_fast_fall() -> void:
	if !fast_fall && velocity.y < 0 && !input_jump:
		fast_fall = true
	elif fast_fall && velocity.y >= 0:
		fast_fall = false

func jump_after_input() -> void:
	if input_jump && can_jump:
		can_jump = false
		jump_count -= 1
		velocity.y = -JUMP_VELOCITY
		fast_fall = false


##### ++++++++++++++++++++++++++++++ PROCESS ++++++++++++++++++++++++++++++ #####

func _physics_process(delta) -> void:
	
	del = delta * 60
	
	
	### SETTING INPUT VARIABLES
	
	input_left = Input.is_action_pressed("input_left")
	input_right = Input.is_action_pressed("input_right")
	input_up = Input.is_action_pressed("input_up")
	input_down = Input.is_action_pressed("input_down")
	
	input_jump = Input.is_action_pressed("input_jump")
	
	
	### STATE SWITCHING
	
	match state:
		
		PlayerStates.DEFAULT:
			state = PlayerStates.AIR
			
		PlayerStates.AIR:
			if on_ground():
				state = PlayerStates.GROUND
		
		PlayerStates.GROUND:
			if !on_ground():
				jump_count -= 1
				state = PlayerStates.AIR
			if input_jump && can_jump:
				state = PlayerStates.AIR
	
	
	### STATE FUNCTIONALITY
	
	match state:
		
		PlayerStates.AIR:
			set_fast_fall()
			jump_after_input()
			get_velocity_in_air(WALK_SPEED)
			move_in_air()
		
		PlayerStates.GROUND:
			reset_jump_count()
			reset_vspeed()
			get_velocity_on_ground(WALK_SPEED, delta)
			move_on_ground(delta)
	
	
	### STATE-INDEPENDENT FUNCTIONALITY
	
	set_can_jump()
	round_position()
