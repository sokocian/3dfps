extends KinematicBody

export var MOUSE_SENS = 0.2
export var CAMERA_ACCEL = 40
export var SPEED = 10
export var DEFAULT_ACCEL = 10
export var AIR_ACCEL = 1
export var GRAVITY = 25
export var JUMP_FORCE = 10

var ground_cast_contact = false

var move_direction = Vector3()
var move_velocity = Vector3()
var movement = Vector3()
var gravity_vector = Vector3()

var acceleration
var snap
var current_velocity

onready var head = $Head
onready var camera = $Head/Camera
onready var camera_ray = $Head/Camera/Raycast
onready var player_mesh = $Mesh

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	player_mesh.set_visible(false)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * MOUSE_SENS))
		head.rotate_x(deg2rad(-event.relative.y * MOUSE_SENS))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad(89))
		
func _process(delta):
	#camera physics interpolation black magic to reduce physics jitter on high refresh-rate monitors
	if Engine.get_frames_per_second() > Engine.iterations_per_second:
		camera.set_as_toplevel(true)
		camera.global_transform.origin = camera.global_transform.origin.linear_interpolate(head.global_transform.origin, CAMERA_ACCEL * delta)
		camera.rotation.y = rotation.y
		camera.rotation.x = head.rotation.x
	else:
		camera.set_as_toplevel(false)
		camera.global_transform = head.global_transform

func _physics_process(delta):
	var horizontal_rotation = global_transform.basis.get_euler().y
	var forward_input = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	var horizontal_input = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	move_direction = Vector3(horizontal_input, 0, forward_input).rotated(Vector3.UP, horizontal_rotation).normalized()
	
	#jumping and gravity
	if is_on_floor():
		snap = -get_floor_normal()
		acceleration = DEFAULT_ACCEL
		gravity_vector = Vector3.ZERO
	else:
		snap = Vector3.DOWN
		acceleration = AIR_ACCEL
		gravity_vector += Vector3.DOWN * GRAVITY * delta
		
	if Input.is_action_just_pressed("jump") and is_on_floor():
		snap = Vector3.ZERO
		gravity_vector = Vector3.UP * JUMP_FORCE
	
	move_velocity = move_velocity.linear_interpolate(move_direction * SPEED, acceleration * delta)
	movement = move_velocity + gravity_vector
	
	current_velocity = move_and_slide_with_snap(movement, snap, Vector3.UP)


