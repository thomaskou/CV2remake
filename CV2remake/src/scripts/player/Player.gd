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
const WALK_SPEED: int = 120
const JUMP_VELOCITY: int = 250


##### ++++++++++++++++++++++++++++++ VARIABLES ++++++++++++++++++++++++++++++ #####

var GameState: Node

var del: float
var state: int


### INPUT VARIABLES

var input_left: int
var input_right: int
var input_up: bool
var input_down: bool

var input_jump: bool


### MOVEMENT VARIABLES

var velocity: Vector2

var jumps: int
var can_jump: bool


##### +++++++++++++++++++++++++++++ READY ++++++++++++++++++++++++++++++ #####

func _ready() -> void:
	
	GameState = get_node("../State")
	
	state = PlayerStates.DEFAULT
	
	
	### MOVEMENT VARIABLES
	
	velocity = Vector2(0, 0)
	
	reset_jumps()
	can_jump = false


##### ++++++++++++++++++++++++++++++ METHODS ++++++++++++++++++++++++++++++ #####

func reset_jumps() -> void:
	jumps = GameState.jumps

func jump() -> void:
	can_jump = false
	jumps -= 1
	velocity.y = -JUMP_VELOCITY

func on_ground() -> bool:
	return test_move(transform, Vector2(0,1))


##### ++++++++++++++++++++++++++++++ PROCESS ++++++++++++++++++++++++++++++ #####

func _physics_process(delta) -> void:
	
	del = delta * 60
	
	
	### SETTING INPUT VARIABLES
	
	input_left = int(Input.is_action_pressed("input_left"))
	input_right = int(Input.is_action_pressed("input_right"))
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
				print("AIR -> GROUND")
		
		PlayerStates.GROUND:
			if !on_ground():
				state = PlayerStates.AIR
				print("GROUND -> AIR")
			if input_jump && can_jump:
				state = PlayerStates.AIR
				print("GROUND -> AIR")
	
	
	### STATE FUNCTIONALITY
	
	match state:
		
		
		PlayerStates.AIR:
			
			if input_jump && can_jump:
				jump()
			
			velocity.y += GRAVITY
			velocity.x = WALK_SPEED * (input_right - input_left)
			
			move_and_slide(velocity, Vector2(0,-1))
		
		
		PlayerStates.GROUND:
			
			reset_jumps()
			
			if velocity.y != 0:
				velocity.y = 0
			velocity.x = WALK_SPEED * (input_right - input_left)
			
			move_and_slide_with_snap(velocity, Vector2(0,-1))
		
		
		_: #default
			continue
	
	
	### STATE-INDEPENDENT FUNCTIONALITY
	
	if !can_jump && !input_jump && jumps > 0:
		can_jump = true
