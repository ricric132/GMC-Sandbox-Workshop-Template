extends Node
class_name Building

@onready var highlight: MeshInstance3D = $Highlight


func building_selected():
	pass


func _on_static_body_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			building_selected()
