#Crouching is so so bad
extends KinematicBody

export var health = 50

export var MOUSE_SENS = 0.08
export var CAMERA_ACCEL = 40.0
export var DEFAULT_SPEED = 8.0
export var CROUCH_SPEED = 4.0
export var DEFAULT_ACCEL = 16.0
export var AIR_ACCEL = 2.0
export var GRAVITY = 28.0
export var JUMP_FORCE = 10.0
export var INERTIA = 1.0

var crosshair_default = load("res://images/hud/crosshair_default.png")
var crosshair_select = load("res://images/hud/crosshair_select.png")
var crosshair_moving = load("res://images/hud/crosshair_moving.png")

var ground_cast_contact = false
var is_crouching = false
var moving = false

var move_direction = Vector3()
var move_velocity = Vector3()
var movement = Vector3()
var gravity_vector = Vector3()

var acceleration
var snap
var current_velocity
var selected_interaction
var camera_target
var selected_interactable
var selected_interactable_class

onready var head = $Head
onready var camera = head.get_node("Camera")
onready var camera_ray = camera.get_node("Raycast")
onready var player_mesh = $Mesh
onready var crosshair = camera.get_node("Crosshair")
onready var interactions_list = camera.get_node("Interactions")
onready var collider = $Collision

func update_crosshair():
	if moving:
		crosshair.texture = crosshair_moving
	else:
		if (camera_target != null and camera_target.has_meta("interactable") and camera_target.get_meta("interactable")) or (camera_target != null and camera_target.get_class() == "RigidBody"):
			crosshair.texture = crosshair_select
		else:
			crosshair.texture = crosshair_default
		
func update_health(amount):
	health += amount 
	if health > 100:
		health = 100

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	player_mesh.set_visible(false)
	camera_ray.add_exception(self)

func _input(event):
	camera_target = camera_ray.get_collider()
	
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * MOUSE_SENS))
		head.rotate_x(deg2rad(-event.relative.y * MOUSE_SENS))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad(89))
		
	if Input.is_action_just_pressed("toggle_crouch"):
		is_crouching = !is_crouching
		
		if is_crouching:
			collider.shape.height = .5
			head.translation.y = 1.5
		else:
			collider.shape.height = 1.5
			head.translation.y = 2.5
	
	interactions_list.clear()
	if camera_target != null and not moving and camera_target.has_meta("interactable") and camera_target.get_meta("interactable"):
		selected_interactable = camera_target
		var interaction_count = selected_interactable.interactions.size() - 1
		
		if  selected_interactable.has_meta("interaction") and selected_interactable_class != selected_interactable.get_meta("interaction"):
			selected_interaction = 0
			selected_interactable_class = selected_interactable.get_meta("interaction")
		
		var count = 0
		for interaction in selected_interactable.interactions:
			interactions_list.add_item(interaction[1])
			interactions_list.set_item_tooltip_enabled(count, false)
			count += 1
			
		interactions_list.set_item_custom_bg_color(selected_interaction, Color(0.88, 0.88, 0.22, 0.75))
		interactions_list.visible = true
		
		if Input.is_action_just_pressed("select"):
			selected_interactable.call(selected_interactable.interactions[selected_interaction][0])
			selected_interactable = null
			camera_target = null 
						
		if Input.is_action_just_pressed("scroll_down"):
			selected_interaction += 1
			if selected_interaction > interaction_count:
				selected_interaction = 0
		
		if Input.is_action_just_pressed("scroll_up"):
			selected_interaction -= 1
			if selected_interaction < interaction_count - 1:
				selected_interaction = interaction_count
	else:
		selected_interactable = null
		interactions_list.visible = false
		
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
		
	if current_velocity.x > 5.0 or current_velocity.x < -5.0 or current_velocity.z > 5.0 or current_velocity.z < -5.0:
		moving = true
	else:
		moving = false
	
	update_crosshair()

func _physics_process(delta):
	var speed
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
	
	if is_crouching:
		speed = CROUCH_SPEED
	else:
		speed = DEFAULT_SPEED
	
	move_velocity = move_velocity.linear_interpolate(move_direction * speed, acceleration * delta)
	movement = move_velocity + gravity_vector
	
	current_velocity = move_and_slide_with_snap(movement, snap, Vector3.UP, true, 4, PI/4, false)
	
	for index in get_slide_count():
		var collision = get_slide_collision(index)
		if collision.collider is RigidBody:
			collision.collider.apply_central_impulse(-collision.normal.normalized() * INERTIA)


