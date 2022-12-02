extends KinematicBody

export var MOUSE_SENS = 0.08
export var CAMERA_ACCEL = 40.0
export var SPEED = 8.0
export var DEFAULT_ACCEL = 16.0
export var AIR_ACCEL = 2.0
export var GRAVITY = 28.0
export var JUMP_FORCE = 10.0

var m_interaction = load("res://scripts/interaction.gd").new()
var crosshair_default = load("res://images/hud/crosshair_default.png")
var crosshair_select = load("res://images/hud/crosshair_select.png")

var ground_cast_contact = false
var crosshair_is_selection = false

var move_direction = Vector3()
var move_velocity = Vector3()
var movement = Vector3()
var gravity_vector = Vector3()

var acceleration
var snap
var current_velocity
var camera_target
var held_object 

onready var head = $Head
onready var camera = head.get_node("Camera")
onready var camera_ray = camera.get_node("Raycast")
onready var player_mesh = $Mesh
onready var crosshair = camera.get_node("Crosshair")
onready var hold_pos = camera.get_node("HoldPos")

func update_crosshair():
	if (camera_target != null and camera_target.has_meta("interactable") and camera_target.get_meta("interactable")) or (camera_target != null and camera_target.get_class() == "RigidBody"):
		crosshair.texture = crosshair_select
		crosshair_is_selection = true
	elif crosshair_is_selection:
		crosshair.texture = crosshair_default
		crosshair_is_selection = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	player_mesh.set_visible(false)
	camera_ray.add_exception(self)

func _input(event):
	camera_target = m_interaction.get_camera_target(camera_ray)
	update_crosshair()
	
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * MOUSE_SENS))
		head.rotate_x(deg2rad(-event.relative.y * MOUSE_SENS))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad(89))
		
	if Input.is_action_just_pressed("select"):
		m_interaction.interact_node(camera_target)
		
	if Input.is_action_just_pressed("pickup"):
		if camera_target != null and camera_target.get_class() == "RigidBody":
			held_object = camera_target
			held_object.mode = RigidBody.MODE_KINEMATIC
			held_object.collision_mask = 0
		
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
	
	if held_object:
		held_object.global_transform.origin = hold_pos.global_transform.origin


