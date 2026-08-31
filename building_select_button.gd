extends Button

var build_template : BuildingTemplate
var building_manager : Node

func setup(building: BuildingTemplate, manager : Node):
	build_template = building
	text = building.name
	building_manager = manager

func clicked():
	building_manager.select_building(build_template)
