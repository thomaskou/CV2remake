extends Node

enum Sprites {
	STANDING, WALKING,
	JUMPING,
	CROUCHING, SLIDING
}

onready var Player: Node = get_parent()
var sprites: Dictionary
var current_sprite: Node

func _ready():
	sprites[Sprites.STANDING] = get_node("../Sprite_Standing")
	sprites[Sprites.WALKING] = get_node("../Sprite_Walking")
	sprites[Sprites.JUMPING] = get_node("../Sprite_Jumping")
	sprites[Sprites.CROUCHING] = get_node("../Sprite_Crouching")
	sprites[Sprites.SLIDING] = get_node("../Sprite_Sliding")
	
func update_sprite() -> void:
	
	if is_instance_valid(current_sprite):
		current_sprite.visible = false
		current_sprite.disabled = true
	
	match Player.state:
		
		Player.PlayerStates.AIR:
			current_sprite = sprites[Sprites.JUMPING]
		
		Player.PlayerStates.GROUND:
			if Player.velocity.x != 0.0:
				current_sprite = sprites[Sprites.WALKING]
			else:
				current_sprite = sprites[Sprites.STANDING]
		
		Player.PlayerStates.CROUCH:
			current_sprite = sprites[Sprites.CROUCHING]
		
		Player.PlayerStates.CROUCH_STUN:
			current_sprite = sprites[Sprites.CROUCHING]
		
		Player.PlayerStates.SLIDE:
			current_sprite = sprites[Sprites.SLIDING]
	
	current_sprite.get_child(0).flip_h = Player.facing_dir == Player.PlayerFacingDir.LEFT
	current_sprite.visible = true
	current_sprite.disabled = false
