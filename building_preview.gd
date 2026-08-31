extends Node3D

@export var valid_preview : Node
@export var invalid_preview : Node

func toggle_preview(is_valid : bool):
	valid_preview.visible = is_valid
	invalid_preview.visible = !is_valid
