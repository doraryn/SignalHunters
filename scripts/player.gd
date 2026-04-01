extends CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound
@onready var grapple_controller = $GrappleControler
@onready var death_sound: AudioStreamPlayer2D = $DeathSound
@onready var game_manager: Node = $"../GameManager"


const SPEED = 300.0
const JUMP_VELOCITY = -850.0  
const ACCELERATION = 0.1
const DECELERATION = 0.1

var took_damage = false
var can_move = true

func respawn():
	self.visible = false
	can_move = false
	await get_tree().create_timer(0.5).timeout # time until respwan
	
	self.global_position = Vector2(87, 563)    # respwan location
	self.visible = true
	can_move = true
	
	await get_tree().create_timer(0.5).timeout # time until respwan
	
	took_damage = false
   
func _physics_process(delta: float) -> void:
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Collision checking e.g. if touching spikes
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		
		if collision.get_collider().name == "TileMapSpikes": # if player touches anything drawn in tilemapsikes
			if took_damage == false:
				took_damage = true # set damage as true
				game_manager.update_player_health(-1) 
				respawn() # respawn the player

	# Handle jump.
	if Input.is_action_just_pressed("jump") && (is_on_floor() || grapple_controller.launched):
		velocity.y += JUMP_VELOCITY
		grapple_controller.retract()
		jump_sound.play()

	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = lerp(velocity.x, SPEED * direction, ACCELERATION)
	else:
		velocity.x = lerp(velocity.x, 0.0, DECELERATION)
		
	#Add animation
	if velocity.x > 1 or velocity.x < -1:
		animated_sprite_2d.animation = "moving"
	else:
		animated_sprite_2d.animation = "idle"

	move_and_slide()
	
	if can_move == false:
		death_sound.play()
		return
	else:
		if direction == 1.0:
			animated_sprite_2d.flip_h = false
		elif direction == -1.0:
			animated_sprite_2d.flip_h = true
