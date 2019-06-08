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

const GRAVITY: float = 14.0
const AIR_FRICTION: float = 6.0

const WALK_SPEED: int = 120
const JUMP_VELOCITY: int = 250


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


##### +++++++++++++++++++++++++++++ READY ++++++++++++++++++++++++++++++ #####

func _ready() -> void:
	
	GameState = get_node("../State")
	
	state = PlayerStates.DEFAULT
	
	
	### MOVEMENT VARIABLES
	
	velocity = Vector2(0, 0)
	
	reset_jump_count()
	can_jump = false


##### ++++++++++++++++++++++++++++++ METHODS ++++++++++++++++++++++++++++++ #####

### CONDITIONS

func on_ground() -> bool:
	return test_move(transform, Vector2(0,1))


### MOVEMENT

func get_velocity_in_air(speed: int) -> void:
	if !input_left && !input_right:
		air_friction(speed)
	elif input_right && !input_left:
		velocity.x = speed * int(input_right)
	elif input_left && !input_right:
		velocity.x = -speed * int(input_left)
	elif input_left || input_right:
		velocity.x = speed * (int(input_right) - int(input_left))

func move_in_air() -> void:
	move_and_slide(velocity.round(), Vector2(0,-1))

func get_velocity_on_ground(speed: int) -> void:
	velocity.x = speed * (int(input_right) - int(input_left))

func move_on_ground(delta: float) -> void:
	var test_x = round(velocity.x)
	while test_move(transform, Vector2(test_x * delta, 0)):
		test_x -= sign(test_x)
		if test_x == 0:
			break
	move_local_x(test_x * delta)
	#move_and_slide_with_snap(velocity.round(), Vector2(0,-1))


### GRAVITY

func reset_vspeed() -> void:
	if velocity.y != 0:
		velocity.y = 0

func gravity() -> void:
	velocity.y += GRAVITY

func air_friction(speed: int) -> void:
	if velocity.x != 0.0:
		velocity.x -= sign(velocity.x) * min(AIR_FRICTION, abs(velocity.x))


### JUMPING

func reset_jump_count() -> void:
	jump_count = GameState.jumps

func set_can_jump() -> void:
	if !can_jump && !input_jump && jump_count > 0:
		can_jump = true

func jump_after_input() -> void:
	if input_jump && can_jump:
		can_jump = false
		jump_count -= 1
		velocity.y = -JUMP_VELOCITY


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
			jump_after_input()
			gravity()
			get_velocity_in_air(WALK_SPEED)
			move_in_air()
		
		PlayerStates.GROUND:
			reset_jump_count()
			reset_vspeed()
			get_velocity_on_ground(WALK_SPEED)
			move_on_ground(delta)
	
	
	### STATE-INDEPENDENT FUNCTIONALITY
	
	set_can_jump()
