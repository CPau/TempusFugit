extends Node2D

# Record one position if player on the floor
# Start recording positions every TIME_INTERVAL when leaving floor and MAX_FRAMES_REC
# Slow movement if falling more than 200 px under the first position

const TIME_INTERVAL = 0.002
const MAX_FRAMES_REC = 2000
const REWIND_TIME_INTERVAL = 0.01

var player_positions = PoolVector2Array()

var rewind = false
var freeze = false
var time_counter = 0
var rewind_time_counter = 1

var rewind_gauge = 0.0

var start = false
var end = false

var text_index = 1

var visible_end = 0

func _ready():
	pass
	
func _input(event):
	if event.is_action_pressed("jump"):
		text_index += 1

func _process(delta):
	if !$Music.playing:
			$Music.playing = true
	
	if !start:
		if text_index == 2:
			$Start_text/T1.visible = false
			$Start_text/T2.visible = true
		if text_index == 3:
			$Start_text/T2.visible = false
			$Start_text/T3.visible = true
		if text_index == 4:
			$Start_text/T3.visible = false
			$Start_text/T4.visible = true
		if text_index == 5:
			$Start_text/T4.visible = false
			$Start_text/T5.visible = true
		if text_index == 6:
			$Start_text/T5.visible = false
			$Start_text/T6.visible = true
		if text_index == 7:
			$Start_text/T6.visible = false
			$Start_text/T7.visible = true
		if text_index == 8:
			$Start_text/T7.visible = false
			$Start_text/T8.visible = true
		if text_index == 9:
			$Start_text/T8.visible = false
			$Start_text/T9.visible = true
		if text_index == 10:
			$Start_text/T9.visible = false
			$Start_text/T10.visible = true
			$king_start.visible = false
			$king_stare.visible = true
			start = true
	
	if $Object.taken:
		$Start_text/T10.visible = false
		$king_stare.visible = false
		$Start_text/Rewind.visible = true
		if text_index == 10:
			$Object/pickup.playing = true
		text_index = 11
	
	if end:
		$player/T0.visible = true
		$king/AnimatedSprite.visible = false
		$king/king_dead.visible = true
		visible_end += 1
		var t_end = visible_end/400.0
		if t_end > 1:
			t_end = 1
		$Screen.material.set_shader_param("end_factor",t_end)
	
	if start and !end and text_index == 11:
		rewind = Input.is_action_pressed("rewind")
		
	#	if player_positions.size() > MAX_FRAMES_REC-1:
	#		freeze = true
	#	else:
	#		freeze = false
		
	#	if !rewind and player_positions.size() < MAX_FRAMES_REC:
	#		if time_counter > TIME_INTERVAL:
	#			player_positions.push_back($player.position)
	#			print("add position")
	#			print(player_positions.size())
	#			time_counter = 0
	
		# and $player.on_ground:
		if !rewind:
			if player_positions.size() > MAX_FRAMES_REC-1:
				player_positions.invert()
				var size
				if player_positions.size() < MAX_FRAMES_REC:
					size = player_positions.size()
				else: 
					size = MAX_FRAMES_REC
				player_positions.resize(size)
				player_positions.invert()
				player_positions.remove(0)
			player_positions.push_back($player.position)
			time_counter = 0
	#		print("add position")
	#		print(player_positions.size())
		
		if rewind:
			if rewind_time_counter > REWIND_TIME_INTERVAL and player_positions.size() > 0:
				player_positions.invert()
				$player.position = player_positions[0]
				$player.velocity = Vector2(0,0)
				player_positions.remove(0)
				player_positions.invert()
				rewind_time_counter = 0
				rewind_gauge += 1.0
			
			if !$player/rewind.playing:
				$player/rewind.playing = true
	
		time_counter += delta
		if rewind:
			rewind_time_counter += delta
		else:
			rewind_time_counter = 0
		
		var t = rewind_gauge/1000.0
		if t > 1:
			t = 1
		$Screen.material.set_shader_param("color_factor",t)
		
