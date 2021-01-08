extends Node


################################################################################
# Enums, constants, & variables
################################################################################

enum Sprites {
	NONE,
	STANDING, WALKING, JUMPING, ATK_STAND, ATK_JUMP,
	CROUCHING, ATK_CROUCH,
	SLIDING,
}

const COLLISION_NORMAL_SPRITES: Array = [
	Sprites.STANDING, Sprites.WALKING, Sprites.ATK_STAND,
	Sprites.JUMPING, Sprites.ATK_JUMP]
const COLLISION_CROUCHING_SPRITES: Array = [Sprites.CROUCHING, Sprites.ATK_CROUCH]
const COLLISION_SLIDING_SPRITES: Array = [Sprites.SLIDING]

const TRAIL_SPRITE_PATH: String = "res://src/scenes/misc/TrailSprite.tscn"
const TRAIL_INTERVAL: int = 6
const TRAIL_FADE_FRAMES: int = 24
const TRAIL_MAX_ALPHA: float = 0.4
const TRAIL_OVERLAY: Color = Color("#606060")

onready var Player: Node = get_parent()
onready var current: int = Sprites.NONE
onready var previous: int = Sprites.NONE

var collision: Dictionary
var sprites: Dictionary


################################################################################
# Ready
################################################################################

func _ready():
	create_collision_dict()
	create_sprite_dict()
	connect_timers()
	begin_trail_timer()

func create_collision_dict() -> void:
	for sprite in COLLISION_NORMAL_SPRITES: collision[sprite] = get_node("../CollisionNormal")
	for sprite in COLLISION_CROUCHING_SPRITES: collision[sprite] = get_node("../CollisionCrouching")
	for sprite in COLLISION_SLIDING_SPRITES: collision[sprite] = get_node("../CollisionSliding")

func create_sprite_dict() -> void:
	sprites[Sprites.STANDING] = get_node("../Sprites/Standing")
	sprites[Sprites.WALKING] = get_node("../Sprites/Walking")
	sprites[Sprites.JUMPING] = get_node("../Sprites/Jumping")
	sprites[Sprites.CROUCHING] = get_node("../Sprites/Crouching")
	sprites[Sprites.SLIDING] = get_node("../Sprites/Sliding")
	sprites[Sprites.ATK_STAND] = get_node("../Sprites/AttackStand")
	sprites[Sprites.ATK_JUMP] = get_node("../Sprites/AttackJump")
	sprites[Sprites.ATK_CROUCH] = get_node("../Sprites/AttackCrouch")


################################################################################
# Methods
################################################################################

func get_collision() -> CollisionShape2D:
	return collision[current]


################################################################################
# Update sprite
################################################################################
	
func update_sprite() -> void:
	
	previous = current
	
	match Player.state:
		Player.PlayerStates.AIR: current = Sprites.JUMPING
		Player.PlayerStates.AIR_ATK: current = Sprites.ATK_JUMP
		Player.PlayerStates.AIR_ATK_STUN: current = Sprites.JUMPING
		Player.PlayerStates.GROUND: current = Sprites.WALKING if Player.velocity.x != 0.0 else Sprites.STANDING
		Player.PlayerStates.GROUND_ATK: current = Sprites.ATK_STAND
		Player.PlayerStates.GROUND_ATK_STUN: current = Sprites.STANDING
		Player.PlayerStates.CROUCH: current = Sprites.CROUCHING
		Player.PlayerStates.CROUCH_ATK: current = Sprites.ATK_CROUCH
		Player.PlayerStates.CROUCH_ATK_STUN: current = Sprites.CROUCHING
		Player.PlayerStates.CROUCH_STUN: current = Sprites.CROUCHING
		Player.PlayerStates.SLIDE: current = Sprites.SLIDING
	
	sprites[current].flip_h = Player.facing_dir == Player.PlayerFacingDir.LEFT
	
	if current != previous:
		collision[current].disabled = false
		sprites[current].visible = true
		if sprites[current] is AnimatedSprite: sprites[current].frame = 0
		if previous != Sprites.NONE:
			if collision[current] != collision[previous]: collision[previous].disabled = true
			sprites[previous].visible = false


################################################################################
# Timers
################################################################################

func connect_timers() -> void:
	$TimerTrail.connect("timeout", self, "_on_timeout_trail")

func begin_trail_timer() -> void:
	$TimerTrail.start(TRAIL_INTERVAL/60.0)

func _on_timeout_trail() -> void:
	$TimerTrail.stop()
	var trail: Sprite = load(TRAIL_SPRITE_PATH).instance()
	if sprites[current] is AnimatedSprite:
		trail.texture = sprites[current].frames.get_frame(sprites[current].animation, sprites[current].frame)
	else: trail.texture = sprites[current].texture
	trail.flip_h = sprites[current].flip_h
	trail.position = Player.position + sprites[current].position
	trail.offset = sprites[current].offset
	trail.modulate.a = TRAIL_MAX_ALPHA
	trail.material.set_shader_param("overlay", TRAIL_OVERLAY)
	add_child(trail)
	trail.begin(TRAIL_FADE_FRAMES)
	begin_trail_timer()
