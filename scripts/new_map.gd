extends Node3D

var selected_tile = ""


func _on_option_button_item_selected(index: int) -> void:
	var option = $CanvasLayer/Toolbar/VBoxContainer/OptionButton
	selected_tile = option.get_item_text(index)

	print("Selected:", selected_tile)
