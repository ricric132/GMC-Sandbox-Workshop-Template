extends Control

@onready var building_name: Label = $BuildingName
@onready var building_manager: Node3D = $"../../BuildingManager"

func setup(building : Node):
	building_name.text = building.template.name


func _on_button_pressed() -> void:
	building_manager.delete_building()
