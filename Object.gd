extends Area2D

var taken=false

func _on_Object_body_entered( body ):
	if not taken and body is preload("res://player.gd"):
		print("item taken")
		taken = true
		var parent = get_parent()
		print(parent.get_name())
		parent.text_index = 11
