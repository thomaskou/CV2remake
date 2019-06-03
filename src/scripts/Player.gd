extends KinematicBody2D


##### ++++++++++++++++++++ CONSTANTS ++++++++++++++++++++ #####


### MOVEMENT CONSTANTS

const GRAVITY: float = 14.0
const WALK_SPEED: int = 120
const JUMP_VELOCITY: int = 250


##### ++++++++++++++++++++ VARIABLES ++++++++++++++++++++ #####

var del: float


### INPUT VARIABLES

var input_left: int
var input_right: int
var input_up: bool
var input_down: bool

var input_jump: bool


### MOVEMENT VARIABLES

var velocity: Vector2


##### ++++++++++++++++++++ READY ++++++++++++++++++++ #####

func _ready() -> void:
	velocity = Vector2(0, 0)


##### ++++++++++++++++++++ PROCESS ++++++++++++++++++++ #####

func _physics_process(delta) -> void:
	
	del = delta * 60
	
	
	### SETTING INPUT VARIABLES
	
	input_left = int(Input.is_action_pressed("input_left"))
	input_right = int(Input.is_action_pressed("input_right"))
	input_up = Input.is_action_pressed("input_up")
	input_down = Input.is_action_pressed("input_down")
	
	input_jump = Input.is_action_pressed("input_jump")
	
	
	### MOVEMENT
	
	if is_on_floor():
		if input_jump:
			velocity.y = -JUMP_VELOCITY
		elif velocity.y != 0:
			velocity.y = 0
	else:
		velocity.y += GRAVITY
	
	velocity.x = WALK_SPEED * (input_right - input_left)
	
	move_and_slide(velocity, Vector2(0,-1))
