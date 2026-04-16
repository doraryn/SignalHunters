extends Node2D

@export var rest_length = 200.0
@export var stiffness = 50.0
@export var damping = 1.0

@onready var player := get_parent()
@onready var ray := $RayCast2D
@onready var rope := $Line2D

var launched = false
var target: Vector2

func _process(delta):
	if NetworkManager.is_grapple_player():
		# This peer controls grapple: read local input
		ray.look_at(get_global_mouse_position())

		if Input.is_action_just_pressed("grapple"):
			_try_launch()
		if Input.is_action_just_released("grapple"):
			_request_retract()
	# Grapple physics run on all peers
	if launched:
		handle_grapple(delta)

func _try_launch():
	if ray.is_colliding():
		var point = ray.get_collision_point()
		if NetworkManager.is_multiplayer_mode:
			_sync_launch.rpc(point)
		_do_launch(point)

func _request_retract():
	if NetworkManager.is_multiplayer_mode:
		_sync_retract.rpc()
	retract()

func _do_launch(point: Vector2):
	launched = true
	target = point
	rope.show()

func launch():
	# Legacy call kept for compatibility
	_try_launch()

func retract():
	launched = false
	rope.hide()

func handle_grapple(delta):
	var target_dir = player.global_position.direction_to(target)
	var target_dist = player.global_position.distance_to(target)

	var displacement = target_dist - rest_length

	var force = Vector2.ZERO

	if displacement > 0:
		var spring_force_magnitude = stiffness * displacement
		var spring_force = target_dir * spring_force_magnitude

		var vel_dot = player.velocity.dot(target_dir)
		var damping_force = -damping * vel_dot * target_dir

		force = spring_force + damping_force

	player.velocity += force * delta
	update_rope()

func update_rope():
	rope.set_point_position(1, to_local(target))

@rpc("any_peer", "call_remote", "reliable")
func _sync_launch(point: Vector2):
	_do_launch(point)

@rpc("any_peer", "call_remote", "reliable")
func _sync_retract():
	retract()
