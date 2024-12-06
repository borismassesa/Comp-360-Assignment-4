extends Node3D

enum State {IDLE, GRABBING, ROTATING, RELEASING, RESETTING}
var current_state := State.IDLE

@onready var animation_player := $AnimationPlayer
@onready var grab_area := $GrabArea
@onready var ball := $"../PhysicsSystem/Ball"

var can_grab := true
var is_ball_grabbed := false
var initial_ball_position: Vector3
var initial_arm_rotation: Vector3

const ROTATION_SPEED := 5.0  # Adjusted for faster rotation
const RELEASE_DELAY := 1.0

func _ready() -> void:
	print("\n=== INITIALIZATION DEBUG ===")
	print("Script starting...")

	# Get the forward direction of the arm in global space
	var forward_direction = -self.global_transform.basis.z.normalized()
	
	# Position the ball in front of the arm along the forward direction
	ball.global_position = self.global_transform.origin + forward_direction * 2 + Vector3(0, 0.5, 0)
	print("Ball repositioned to: ", ball.global_position)
	
	# Position the grabbing area in front of the arm along the forward direction
	grab_area.global_position = self.global_transform.origin + forward_direction * 1.5 + Vector3(0, 0.5, 0)
	print("GrabArea repositioned to: ", grab_area.global_position)
	
	# Store initial positions
	initial_ball_position = ball.global_position
	initial_arm_rotation = rotation
	
	# Connect signals
	grab_area.body_entered.connect(_on_grab_area_body_entered)
	grab_area.body_exited.connect(_on_grab_area_body_exited)
	animation_player.animation_finished.connect(_on_animation_finished)
	
	print("Script initialized successfully")
	_start_grab_sequence()

func _physics_process(delta: float) -> void:
	if ball and grab_area:
		print("Distance to ball: ", ball.global_position.distance_to(grab_area.global_position))
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

func _start_grab_sequence() -> void:
	print("\n=== STARTING GRAB SEQUENCE ===")
	if ball.global_position.distance_to(initial_ball_position) > 5.0:
		print("Ball too far. Resetting position.")
		_reset_ball()
	if animation_player.has_animation("grab"):
		animation_player.play("grab")
		current_state = State.GRABBING
	else:
		print("ERROR: Missing 'grab' animation!")
	print("=== GRAB SEQUENCE INITIATED ===\n")

func _process_idle() -> void:
	if not animation_player.is_playing():
		_start_grab_sequence()

func _process_grabbing() -> void:
	print("State: GRABBING - Is ball grabbed: ", is_ball_grabbed)
	if is_ball_grabbed and not animation_player.is_playing():
		current_state = State.ROTATING
		print("Transitioning to ROTATING state.")

func _process_rotating(delta: float) -> void:
	print("Current state: ROTATING")
	if is_ball_grabbed:
		var target_rotation = Vector3(0, PI / 2, 0)
		rotation = rotation.lerp(target_rotation, ROTATION_SPEED * delta)
		ball.global_position = grab_area.global_position  # Align ball with grab area
		print("Rotating - Current: ", rotation, " Target: ", target_rotation)
		
		if rotation.is_equal_approx(target_rotation):
			current_state = State.RELEASING
			print("Rotation complete. Transitioning to RELEASING state.")

func _process_releasing() -> void:
	print("\n=== RELEASING BALL ===")
	is_ball_grabbed = false
	ball.freeze = false
	await get_tree().create_timer(RELEASE_DELAY).timeout
	print("Ball released at position: ", ball.global_position)
	current_state = State.RESETTING

func _process_resetting() -> void:
	print("\n=== RESETTING ===")
	rotation = initial_arm_rotation
	await get_tree().create_timer(2.0).timeout
	print("Arm reset. Transitioning to IDLE.")
	current_state = State.IDLE

func _on_grab_area_body_entered(body: Node3D) -> void:
	print("\n=== BODY ENTERED GRAB AREA ===")
	if body == ball and can_grab and current_state == State.GRABBING:
		is_ball_grabbed = true
		ball.freeze = true
		ball.global_position = grab_area.global_position
		print("Ball grabbed and aligned with GrabArea.")

func _on_grab_area_body_exited(body: Node3D) -> void:
	print("\n=== BODY EXITED GRAB AREA ===")
	if body == ball:
		is_ball_grabbed = false
		ball.freeze = false
		print("Ball released.")

func _on_animation_finished(anim_name: String) -> void:
	print("\n=== ANIMATION FINISHED ===")
	if anim_name == "grab":
		if is_ball_grabbed:
			current_state = State.ROTATING
		else:
			_start_grab_sequence()
	elif anim_name == "letgo":
		current_state = State.RESETTING

func _reset_ball() -> void:
	print("\n=== RESETTING BALL ===")
	ball.global_position = initial_ball_position
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	print("Ball reset to initial position: ", ball.global_position)
