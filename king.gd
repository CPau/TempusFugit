extends KinematicBody2D

# Member variables
const GRAVITY = 500.0 # pixels/second/second
const WALK_FORCE = 600
const WALK_MIN_SPEED = 10
const WALK_MAX_SPEED = 100
const STOP_FORCE = 1300
const SLIDE_STOP_VELOCITY = 1.0 # one pixel/second
const SLIDE_STOP_MIN_TRAVEL = 1.0 # one pixel

export(int) var patrol_distance = 200
var start_position = Vector2()
var end_position = Vector2()

enum STATES_MIND {WAIT, MOVE, ACT}
var current_mind_state = WAIT
var previous_mind_state = null

var last_move_direction = Vector2(-1,0)
var move_direction = Vector2()

var first_ai_cycle = true

var velocity = Vector2()
var parent
var player
var player_direction = 1

export(String) var weapon_scene_path = "res://Weapons/Spear.tscn"
var weapon = null
var weapon_path = ""

var distance = 0
var height = 0
var attacking = false

onready var animation_player = $AnimationPlayer

onready var wait_timer = $WaitTimer
onready var attack_timer = $AttackTimer

var hit = false

func _ready():
	parent = get_parent()
	player = get_node("../player")
	start_position = position
	end_position = start_position + Vector2(patrol_distance, 0)

	_change_mind_state(WAIT)
	randomize()
	wait_timer.stop()
	wait_timer.wait_time = randf() * 3
	wait_timer.start()
	
	# Weapon setup
	var weapon_instance = load(weapon_scene_path).instance()
	var weapon_anchor = $WeaponSpawnPoint/WeaponAnchorPoint
	weapon_anchor.add_child(weapon_instance)

	weapon = weapon_anchor.get_child(0)

	weapon_path = weapon.get_path()
	weapon.connect("attack_finished", self, "_on_Weapon_attack_finished")


func _physics_process(delta):
	if !hit:
		var vect_distance = position - player.position
		player_direction = sign(vect_distance.x)
		distance = sqrt(vect_distance.x * vect_distance.x + vect_distance.y * vect_distance.y)
		height = sqrt(vect_distance.y * vect_distance.y)
	#	print(distance)
	#	print(current_mind_state)

		if current_mind_state != ACT and distance < 70 and height < 20:
			_change_mind_state(ACT)
		
		if current_mind_state == MOVE:
			var force = Vector2(0, GRAVITY)
			var stop = true
			
			if move_direction == Vector2(-1,0):
				if velocity.x <= WALK_MIN_SPEED and velocity.x > -WALK_MAX_SPEED:
					force.x -= WALK_FORCE
					stop = false
			elif move_direction == Vector2(1,0):
				if velocity.x >= -WALK_MIN_SPEED and velocity.x < WALK_MAX_SPEED:
					force.x += WALK_FORCE
					stop = false
			
			if stop:
				var vsign = sign(velocity.x)
				var vlen = abs(velocity.x)
				
				vlen -= STOP_FORCE * delta
				if vlen < 0:
					vlen = 0
				
				velocity.x = vlen * vsign
			
				
			
			# Integrate forces to velocity
			velocity += force * delta
			# Integrate velocity into motion and move
			velocity = move_and_slide(velocity, Vector2(0, -1))
			
			
			if move_direction.x == 1 and position.x > end_position.x \
				or move_direction.x == -1 and position.x < start_position.x:
				last_move_direction = move_direction
				_change_mind_state(WAIT)
	else:
		print("end")
		if !parent.end:
			$hit.playing = true
		parent.end = true


func _change_mind_state(new_state):
	previous_mind_state = current_mind_state
	current_mind_state = new_state
	
	match current_mind_state:
		WAIT:
			print("wait")
			move_direction = Vector2()
			wait_timer.wait_time = 1.0
			wait_timer.start()
			print("idle")
			$AnimatedSprite.animation = "idle"
			$AnimatedSprite.flip_v = false
			if last_move_direction.x == 1:
				$AnimatedSprite.flip_h = true
			else:
				$AnimatedSprite.flip_h = false
			$AnimatedSprite.position.x = 0
		MOVE:
			print("move")
			move_direction.x = -last_move_direction.x
			if last_move_direction.x == 1:
				move_direction.x = -1
			elif last_move_direction.x == -1:
				move_direction.x = 1
			wait_timer.stop()
			print("run")
			$AnimatedSprite.animation = "run"
			$AnimatedSprite.flip_v = false
			if move_direction.x == -1:
				$AnimatedSprite.flip_h = false
			else:
				$AnimatedSprite.flip_h = true
			$AnimatedSprite.position.x = 0
		ACT:
			if player_direction == 1:
				$WeaponSpawnPoint/WeaponAnchorPoint.scale = Vector2(-1,1)
				$WeaponSpawnPoint/WeaponAnchorPoint.position = Vector2(-10,0)
			else:
				$WeaponSpawnPoint/WeaponAnchorPoint.scale = Vector2(1,1)
				$WeaponSpawnPoint/WeaponAnchorPoint.position = Vector2(10,0)
			weapon.attack()
			attacking = true
			wait_timer.stop()
			print("act")
			print("attack")
			$AnimatedSprite.animation = "attack"
			$AnimatedSprite.flip_v = false
			if player_direction == 1:
				$AnimatedSprite.flip_h = false
				$AnimatedSprite.position.x = -10
			else:
				$AnimatedSprite.flip_h = true
				$AnimatedSprite.position.x = 10


func _on_WaitTimer_timeout():
	wait_timer.stop()
	if first_ai_cycle:
		first_ai_cycle = false
		_change_mind_state(MOVE)
		return
	_change_mind_state(MOVE)
#	_change_mind_state(ACT)


func _on_Weapon_attack_finished():
	_change_mind_state(WAIT)
	attacking = false

