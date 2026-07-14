extends Node2D


func _on_cancel_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main-Menu.tscn")


func _on_submit_pressed() -> void:
	pass # Replace with function body.
