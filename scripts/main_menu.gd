extends Node2D




func _on_create_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/new_map_config.tscn")


func _on_edit_pressed() -> void:
	pass # Replace with function body.


func _on_exit_pressed() -> void:
	get_tree().quit()
