extends CharacterBody3D

var speed 
var gravity = Vector3(0,-9.8,0)
var mc_lb := -80 #mouse clamp lowerbound
var mc_ub =  80  #mouse clamp upperbound
var friction = 7
var air_control = 1.5

const WALK_SPEED = 2.5
const SPRINT_SPEED = 5
const JUMP_VELOCITY = 3
const SENSITIVITY = 0.005

#head bobbing 
const BOB_FREQUENCY = 1.0
const BOB_AMPLITUDE = 0.05
var bob_time = 0.0

#fov 
const BASE_FOV = 75
const FOV_CHANGE = 3

@onready var head = $head
@onready var camera = $head/Camera3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)    #lock mouse

func _unhandled_input(event: InputEvent) -> void:
	#mouse look around logic
	if event is InputEventMouseMotion:
		#we use different nodes for different axis of rotations because rotating one node on both axes fks it
		head.rotate_y(-event.relative.x * SENSITIVITY)  #head rotated up and down
		camera.rotate_x(-event.relative.y * SENSITIVITY) #camera rotated left and right
		#clamp veiw boundries
		camera.rotation.x = clamp(camera.rotation.x,deg_to_rad(mc_lb),deg_to_rad(mc_ub))

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	#Logic to unlock mouse from screen
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	#sprint logic
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
	
	#get direction vector from input
	var input_dir := Input.get_vector("left", "right", "up", "down") #returns Vector2 like (-1,1) left and up
	#convert 2d direction vector to 3d, also in direction the head is facing
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	#apply movement when on floor
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:   # if no input apply friction to stop
			velocity.x = lerp(velocity.x,direction.x * speed, delta * friction)
			velocity.z = lerp(velocity.z,direction.z * speed, delta * friction)
	else:    #while not on floor,limited control in air
		velocity.x = lerp(velocity.x,direction.x * speed, delta * air_control)
		velocity.z = lerp(velocity.z,direction.z * speed, delta * air_control)
		
	#head bob
	bob_time += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = headbob(bob_time)
	
	#FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, speed * 2)
	var targetfov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, targetfov, delta * 8)  
	
	move_and_slide()  #actually applies transformation


func headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQUENCY) * BOB_AMPLITUDE #bob up and down 
	pos.x = cos(time * BOB_FREQUENCY/2) * BOB_AMPLITUDE #bob left and right
	return pos
