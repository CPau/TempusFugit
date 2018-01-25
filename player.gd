extends KinematicBody2D

# Member variables
const GRAVITY = 500.0 # pixels/second/second

# Angle in degrees towards either side that the player can consider "floor"
const FLOOR_ANGLE_TOLERANCE = 40
const WALK_FORCE = 600
const WALK_MIN_SPEED = 10
const WALK_MAX_SPEED = 200
const STOP_FORCE = 1300
const JUMP_SPEED = 200
const JUMP_MAX_AIRBORNE_TIME = 0.2

const WALL_SLIDE_SPEED = 100
const WALL_JUMP_SPEED = 200
const WALL_JUMP_AIR_SPEED = 1400
const WALL_JUMP_TIME = 0.4

const DASH_TIME = 0.1
const DASH_AIR_SPEED = 1200

const PUSH_TIME = 0.2
const PUSH_AIR_SPEED = 1200

const SLIDE_STOP_VELOCITY = 1.0 # one pixel/second
const SLIDE_STOP_MIN_TRAVEL = 1.0 # one pixel

enum STATES {IDLE, WALK, ATTACK, REWINDING}
var current_state = null
var previous_state = null

var velocity = Vector2()
var on_air_time = 100
var jumping = false

var wall_jump = false
var on_wall_jump_time = 100
var wall_jump_direction = 0

var on_ground = false

var dashing = false
var on_dash_time = 100
var dash_direction = 0

var prev_jump_pressed = false

var parent
var king
var king_direction = 0

var player_direction = 0

var hit = false
var on_push_time = 100
var push_direction = 0

export(String) var weapon_scene_path = "res://Weapons/Sword.tscn"
var weapon = null
var weapon_path = ""
var attacking = false

onready var animation_player = $AnimationPlayer

func _ready():
	parent = get_parent()
	king = get_node("../king")
	
	# Weapon setup
	var weapon_instance = load(weapon_scene_path).instance()
	var weapon_anchor = $WeaponSpawnPoint/WeaponAnchorPoint
	weapon_anchor.add_child(weapon_instance)

	weapon = weapon_anchor.get_child(0)

	weapon_path = weapon.get_path()
	weapon.connect("attack_finished", self, "_on_Weapon_attack_finished")

	_change_state(IDLE)

func _input(event):
	if !parent.rewind:
		if event.is_action_pressed("jump"):
			wall_jump = true
			if parent.start:
				$jump.playing = true
		if event.is_action_pressed("dash"):
			dashing = true
			if parent.start:
				$dash.playing = true
		if event.is_action_pressed("attack"):
			if current_state in [ATTACK, REWINDING]:
				return
			_change_state(ATTACK)

func _physics_process(delta):
	if !parent.rewind and !parent.freeze and parent.start and !parent.end:
		# Create forces
		var force = Vector2(0, GRAVITY)
		
		var walk_left = Input.is_action_pressed("move_left")
		var walk_right = Input.is_action_pressed("move_right")
		var jump = Input.is_action_pressed("jump")
		
		# Movement
		if current_state == IDLE:
			if walk_left or walk_right:
				_change_state(WALK)
		if current_state == WALK:
			if !walk_left and !walk_right:
				_change_state(IDLE)
		
		if walk_left:
			player_direction = -1
			$WeaponSpawnPoint/WeaponAnchorPoint.scale = Vector2(-1,1)
			$WeaponSpawnPoint/WeaponAnchorPoint.position = Vector2(-10,0)
		elif walk_right:
			$WeaponSpawnPoint/WeaponAnchorPoint.scale = Vector2(1,1)
			$WeaponSpawnPoint/WeaponAnchorPoint.position = Vector2(10,0)
			player_direction = 1
		
		var stop = true
		on_ground = false
		
		if on_wall_jump_time > WALL_JUMP_TIME and on_dash_time > DASH_TIME and on_push_time > PUSH_TIME:
			if walk_left:
				if velocity.x <= WALK_MIN_SPEED and velocity.x > -WALK_MAX_SPEED:
					force.x -= WALK_FORCE
					stop = false
			elif walk_right:
				if velocity.x >= -WALK_MIN_SPEED and velocity.x < WALK_MAX_SPEED:
					force.x += WALK_FORCE
					stop = false
			
		if on_wall_jump_time < WALL_JUMP_TIME and on_dash_time > DASH_TIME and on_push_time > PUSH_TIME:
			force.x += wall_jump_direction * WALL_JUMP_AIR_SPEED * (0.3/(on_wall_jump_time+0.1))
		if on_wall_jump_time > WALL_JUMP_TIME and on_dash_time < DASH_TIME and on_push_time > PUSH_TIME:
			force.x += dash_direction * DASH_AIR_SPEED * (0.3/(on_dash_time+0.01))
			velocity.y = 0
		if on_wall_jump_time > WALL_JUMP_TIME and on_dash_time > DASH_TIME and on_push_time < PUSH_TIME:
			force.x += push_direction * PUSH_AIR_SPEED * (0.3/(on_push_time+0.01))
			velocity.y = 0
		
		if is_on_wall() and jump and wall_jump and on_air_time > 0.1:
			if walk_left:
				wall_jump_direction = 1
				velocity.y = -WALL_JUMP_SPEED
				jumping = true
				on_wall_jump_time = 0
			if walk_right:
				wall_jump_direction = -1
				velocity.y = -WALL_JUMP_SPEED
				jumping = true
				on_wall_jump_time = 0
		
		if hit:
			var vect_distance = position - king.position
			king_direction = sign(vect_distance.x)
			if king_direction == -1:
				velocity.x = 0
				push_direction = -1
				on_push_time = 0
			else :
				velocity.x = 0
				push_direction = 1
				on_push_time = 0
			hit = false
			$hit.playing = true
		
		if dashing:
			if walk_left:
				velocity.x = 0
				dash_direction = -1
				on_dash_time = 0
			if walk_right:
				velocity.x = 0
				dash_direction = 1
				on_dash_time = 0
		
		if stop:
			var vsign = sign(velocity.x)
			var vlen = abs(velocity.x)
			
			vlen -= STOP_FORCE * delta
			if vlen < 0:
				vlen = 0
			
			velocity.x = vlen * vsign
		
		if velocity.x == 0 and velocity.y == 0 and !attacking:
			$AnimatedSprite.animation = "idle"
			$AnimatedSprite.flip_v = false
			if player_direction == 1:
				$AnimatedSprite.flip_h = true
			else:
				$AnimatedSprite.flip_h = false
		if velocity.x != 0 and velocity.y == 0 and !attacking:
			$AnimatedSprite.animation = "run"
			$AnimatedSprite.flip_v = false
			$AnimatedSprite.flip_h = velocity.x > 0
		if (not is_on_wall() and velocity.y != 0 and !attacking):
			$AnimatedSprite.animation = "jump"
			$AnimatedSprite.flip_v = false
			if player_direction == 1:
				$AnimatedSprite.flip_h = true
			else:
				$AnimatedSprite.flip_h = false
		if attacking:
			$AnimatedSprite.animation = "attack"
			$AnimatedSprite.flip_v = false
			if player_direction == 1:
				$AnimatedSprite.flip_h = true
			else:
				$AnimatedSprite.flip_h = false
		if is_on_wall() and !attacking:
			$AnimatedSprite.animation = "wall"
			$AnimatedSprite.flip_v = false
			if player_direction == 1:
				$AnimatedSprite.flip_h = true
			else:
				$AnimatedSprite.flip_h = false
			
		# Integrate forces to velocity
		velocity += force * delta
		# Integrate velocity into motion and move
		velocity = move_and_slide(velocity, Vector2(0, -1))
		
		if is_on_floor():
			on_air_time = 0
			on_wall_jump_time = 1
			on_ground = true
		
		if jumping and velocity.y > 0:
			# If falling, no longer jumping
			jumping = false
		
		if on_air_time < JUMP_MAX_AIRBORNE_TIME and jump and not prev_jump_pressed and not jumping:
			# Jump must also be allowed to happen if the character left the floor a little bit ago.
			# Makes controls more snappy.
			velocity.y = -JUMP_SPEED
			jumping = true
		
		on_air_time += delta
		on_wall_jump_time += delta
		on_dash_time += delta
		on_push_time += delta
		prev_jump_pressed = jump
		wall_jump = false
		dashing = false
	
	if parent.rewind :
		$trail.show()
	else: 
		$trail.hide()
		$trail.restart()

func _change_state(new_state):
	previous_state = current_state
	current_state = new_state
	
	# initialize/enter the state
	match new_state:
		IDLE:
			animation_player.play("idle")
		ATTACK:
			animation_player.play("attack")
			weapon.attack()
			attacking = true
		WALK:
			animation_player.play("walk")
		REWINDING:
			animation_player.play("rewind")


func _on_Weapon_attack_finished():
	_change_state(IDLE)
	attacking = false
	