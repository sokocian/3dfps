extends KinematicBody

var moveSpeed = 5.0
var jumpForce = 5.0
var gravity = 12.0
var lookSens = 10.0

var velocity = Vector3()
var mouseDelta = Vector2()

func movement():
	var input = Vector2()
	velocity.x = 0
	velocity.y = 0

	if Input.is_action_pressed("move_forward"):
		input.y -= 1
	if Input.is_action_pressed("move_backward"):
		input.y += 1
	if Input.is_action_pressed("move_right"):
		input.x += 1
	if Input.is_action_pressed("move_left"):
		input.x -= 1
		
	input = input.normalized()

func _physics_process(_delta):
	movement()
	
	


