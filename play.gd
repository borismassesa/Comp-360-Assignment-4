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

const ROTATION_SPEED := 2.0
const RELEASE_DELAY := 1.0

func _ready() -> void:
	print("Script starting...")
	
	# Verify nodes
	if !animation_player:
		print("ERROR: AnimationPlayer not found!")
	if !grab_area:
		print("ERROR: GrabArea not found!")
	if !ball:
		print("ERROR: Ball not found!")
	
	# Store initial positions
	initial_ball_position = ball.global_position
	initial_arm_rotation = rotation
	
	# Connect signals
	grab_area.body_entered.connect(_on_grab_area_body_entered)
	grab_area.body_exited.connect(_on_grab_area_body_exited)
	
	print("Script initialized successfully")
	_start_grab_sequence()

func _physics_process(delta: float) -> void:
	# Print distance between ball and grab area for debugging
	if ball and grab_area:
		var distance = ball.global_position.distance_to(grab_area.global_position)
		print("Distance to ball: ", distance)
	
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
	print("Starting grab sequence...")
	if ball.global_position.distance_to(initial_ball_position) > 5.0:
		_reset_ball()
	
	if animation_player.has_animation("grab"):
		print("Playing grab animation")
		animation_player.play("grab")
		current_state = State.GRABBING
	else:
		print("ERROR: No grab animation found!")

func _process_idle() -> void:
	if not animation_player.is_playing():
		_start_grab_sequence()

func _process_grabbing() -> void:
	print("Grabbing state - Is ball grabbed: ", is_ball_grabbed)
	if is_ball_grabbed and not animation_player.is_playing():
		print("Transitioning to rotating")
		current_state = State.ROTATING

func _process_rotating(delta: float) -> void:
	if is_ball_grabbed:
		var target_rotation := Vector3(0, PI/2, 0)
		rotation = rotation.lerp(target_rotation, ROTATION_SPEED * delta)
		
		# Update ball position
		ball.global_position = grab_area.global_position
		print("Moving ball to: ", grab_area.global_position)
		
		if rotation.distance_to(target_rotation) < 0.1:
			current_state = State.RELEASING

func _process_releasing() -> void:
	print("Releasing ball")
	is_ball_grabbed = false
	ball.freeze = false
	await get_tree().create_timer(RELEASE_DELAY).timeout
	current_state = State.RESETTING

func _process_resetting() -> void:
	rotation = initial_arm_rotation
	await get_tree().create_timer(2.0).timeout
	current_state = State.IDLE

func _on_grab_area_body_entered(body: Node3D) -> void:
	print("Body entered grab area: ", body.name)
	if body == ball and can_grab:
		print("Ball grabbed!")
		is_ball_grabbed = true
		ball.freeze = true

func _on_grab_area_body_exited(body: Node3D) -> void:
	print("Body exited grab area: ", body.name)
	if body == ball:
		print("Ball released!")
		is_ball_grabbed = false
		ball.freeze = false

func _reset_ball() -> void:
	print("Resetting ball position")
	ball.global_position = initial_ball_position
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
