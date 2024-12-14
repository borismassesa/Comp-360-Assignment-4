extends Node3D

enum State {IDLE, GRABBING, ROTATING, RELEASING, RESETTING}
var current_state := State.IDLE

@onready var animation_player := $AnimationPlayer
@onready var grab_area := $GrabArea
@onready var ball := $"../Ball" # Ball should be a RigidBody3D with a CollisionShape3D and MeshInstance3D

var can_grab := true
var is_ball_grabbed := false
var initial_ball_position: Vector3
var initial_arm_rotation: Vector3

const ROTATION_SPEED := 4.0
const RELEASE_DELAY := 0.2

func _ready() -> void:
	print("Script starting...")

	# Get the forward direction of the arm in global space
	# Assuming the arm faces along its negative z-axis.
	var forward_direction = -self.global_transform.basis.z.normalized()

	# Place the ball in front of the arm and slightly above the ground.
	ball.global_position = self.global_transform.origin + forward_direction * 1.2 + Vector3(0, 0.5, 0)
	print("Ball repositioned to: ", ball.global_position)

	# Place the grab area at the same position as the ball
	grab_area.global_position = ball.global_position
	print("GrabArea repositioned to: ", grab_area.global_position)

	# Adjust the camera to look at the ball from a reasonable angle and distance
	var camera = get_node("../Camera3D")
	if camera:
		# Position camera to look at the ball from a slight offset
		camera.global_position = ball.global_position + Vector3(2, 1.5, 2)
		camera.look_at(ball.global_position, Vector3.UP)
		print("Camera adjusted to view ball")

	# Store initial positions
	initial_ball_position = ball.global_position
	initial_arm_rotation = rotation

	# Connect signals
	grab_area.body_entered.connect(_on_grab_area_body_entered)
	grab_area.body_exited.connect(_on_grab_area_body_exited)
	animation_player.animation_finished.connect(_on_animation_finished)

	# Ensure ball starts frozen so it doesn't fall away
	ball.freeze = true

	print("Script initialized successfully")
	_start_sequence()

func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			_process_idle()
		State.GRABBING:
			_process_grabbing()
		State.ROTATING:
			_process_rotating(delta)
		State.RELEASING:
			_process_releasing()
		State.RESETTING:
			_process_resetting()

	# Keep the ball at the grab area's position while grabbed
	if is_ball_grabbed:
		ball.global_transform.origin = grab_area.global_transform.origin

func _start_sequence() -> void:
	print("Starting grab sequence")
	print("Available animations: ", animation_player.get_animation_list())

	if animation_player.has_animation("grab"):
		animation_player.play("grab")
		current_state = State.GRABBING
	else:
		print("ERROR: Missing grab animation!")

func _process_idle() -> void:
	if not animation_player.is_playing():
		_start_sequence()

func _process_grabbing() -> void:
	if is_ball_grabbed and not animation_player.is_playing():
		current_state = State.ROTATING

func _process_rotating(delta: float) -> void:
	if is_ball_grabbed:
		var target_rotation = Vector3(0, PI/2, 0)
		rotation = rotation.lerp(target_rotation, ROTATION_SPEED * delta)

		if rotation.is_equal_approx(target_rotation):
			current_state = State.RELEASING

func _process_releasing() -> void:
	is_ball_grabbed = false

	if animation_player.has_animation("letgo"):
		animation_player.play("letgo")

		# Keep ball at grab area position before releasing
		var release_position = grab_area.global_position
		ball.global_position = release_position
		# Keep ball frozen to prevent it from falling or moving away
		ball.freeze = true
		# Zero out velocities
		ball.linear_velocity = Vector3.ZERO
		ball.angular_velocity = Vector3.ZERO

	await get_tree().create_timer(RELEASE_DELAY).timeout
	current_state = State.RESETTING

func _process_resetting() -> void:
	# Reset arm rotation and reposition ball if needed
	rotation = initial_arm_rotation
	ball.global_position = grab_area.global_position
	ball.freeze = true
	await get_tree().create_timer(1.0).timeout
	current_state = State.IDLE

func _on_grab_area_body_entered(body: Node) -> void:
	print("Body entered grab area: ", body.name)
	if body == ball and can_grab and current_state == State.GRABBING:
		print("Ball grabbed!")
		is_ball_grabbed = true
		ball.freeze = true
		ball.global_transform.origin = grab_area.global_transform.origin

func _on_grab_area_body_exited(body: Node) -> void:
	print("Body exited grab area: ", body.name)
	if body == ball and current_state != State.ROTATING:
		is_ball_grabbed = false
		ball.freeze = true
		ball.global_position = grab_area.global_position

func _on_animation_finished(anim_name: String) -> void:
	print("Animation finished: ", anim_name)
	match anim_name:
		"grab":
			if is_ball_grabbed:
				current_state = State.ROTATING
			else:
				_start_sequence()
		"letgo":
			current_state = State.RESETTING

func _reset_ball() -> void:
	ball.global_position = initial_ball_position
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	ball.freeze = true
