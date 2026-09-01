# 1.Download and check around the template

# 2. Raycast from camera onto floor
Add building_manager.gd to BuildingManager node

building_manager.gd
```gdscript
extends Node3D

@onready var cam: Camera3D = $"../Camera3D"
@onready var preview_parent: Node3D = $"../PreviewParent"

func _physics_process(delta: float) -> void:
	var mousePos = get_viewport().get_mouse_position()
	
	# raycast to find where pointer is on the floor 
	var space_state = get_world_3d().direct_space_state
	var from = cam.project_ray_origin(mousePos)
	var to = from + cam.project_ray_normal(mousePos) * 1000
	var ray = PhysicsRayQueryParameters3D.create(from, to)
	ray.collision_mask = (1 << 1-1)
	var result = space_state.intersect_ray(ray)

  if(result):
    preview_parent.position = result.position
    preview_parent.show()
  else:
    preview_parent.hide()
```

# 3.Setup grid system
add new variables to top

building_manager.gd
```gdscript
var grid : Array[Array] = []
const WIDTH = 30
const HEIGHT = 30
const TILE_SIZE = 1
```

create tile.gd script

tile.gd
```gdscript
extends Object

class_name Tile

var x : int
var y : int 
var building : Node

func _init(_x : int, _y : int):
	x = _x
	y = _y
	building = null

func is_empty() -> bool:
	return building == null
```

initialize grid array

building_manager.gd
```gdscript
@onready var grid_corner: Node3D = $"../Grid/Floor/GridCorner"

func _ready() -> void:
	setup_grid()

func setup_grid() -> void:
	#create 2D array of size WIDTHxHEIGHT and populating with tile objects
	grid.resize(WIDTH)
	for x in range(WIDTH):
		grid[x]=Array()
		grid[x].resize(HEIGHT)
		for y in range(HEIGHT):
			grid[x][y] = Tile.new(x, y)
```

add helper functions for grid coordinates

building_manager.gd
```gdscript
func grid_to_world_position(x : int, y : int, rot : rot_dir = rot_dir.FORWARD) -> Vector3:
	#offset the grid coordinates based off of rotation to recentre corner of building
	var offsetted_coord = Vector3(x, 0, y) + Vector3(rot_offset[rot].x, 0 ,rot_offset[rot].y)
	return grid_corner.global_position + offsetted_coord * TILE_SIZE

func world_to_grid_coords(pos : Vector3) -> Vector2i:
	var recentered_pos : Vector3 = pos - grid_corner.global_position
	return Vector2i(recentered_pos.x/TILE_SIZE, recentered_pos.z/TILE_SIZE)
```

test this by updating our preview to snap to grid

building_manager.gd
```gdscript
#OLD ----------------------------------------------------------------------
  if(result):
    preview_parent.position = result.position
    preview_parent.show()
  else:
    preview_parent.hide()

#REPLACE WITH THIS --------------------------------------------------------
	if(result && selected_building):
		var coords : Vector2i = world_to_grid_coords(result.position)
		preview_parent.position = grid_to_world_position(coords.x, coords.y)
	else:
		preview_parent.hide()
```


# 4.Actually Building things 
First understand the custom resource BuildingTemplate

add building_parent and selected_building variables

building_manager.gd
```gdscript
@onready var building_parent: Node3D = $"../Grid/BuildingParent"
@export var selected_building : BuildingTemplate
```

add build and check_valid function

building_manager.gd
```gdscript
func build(x : int, y : int, building : BuildingTemplate) -> void:
	# checks if the attempted build spot is valid
	if !check_valid(x, y, building):
		return
	
	# spawns in the building
	var built : Node = building.build_object.instantiate()
	building_parent.add_child(built)
	built.global_position = grid_to_world_position(x, y, cur_rot)
	
	# update grid tiles to track what tiles are occupied by what buildings
	for i in range(building.dimension.x):
		for j in range(building.dimension.y):
			var check_coord : Vector2i = Vector2i(x, y)

			grid[check_coord.x][check_coord.y].building = built


func check_valid(x : int, y : int, building : BuildingTemplate):
	for i in range(building.dimension.x):
		for j in range(building.dimension.y):
			var check_coord : Vector2i = Vector2i(x, y)
			
			#checks in range and not occupied
			if check_coord.x >= WIDTH || check_coord.x < 0:
				return false
			if check_coord.y >= HEIGHT || check_coord.y < 0:
				return false
			if !grid[check_coord.x][check_coord.y].is_empty():
				return false
	
	return true
```

update _physics_process function in to detect user left click

building_manager.gd
```gdscript
#OLD ----------------------------------------------------------------------
	if(result && selected_building):
		var coords : Vector2i = world_to_grid_coords(result.position)
		preview_parent.position = grid_to_world_position(coords.x, coords.y)
	else:
		preview_parent.hide()

#REPLACE WITH THIS --------------------------------------------------------
	if(result && selected_building):
		# shows the preview build
		var coords : Vector2i = world_to_grid_coords(result.position)
		preview_parent.position = grid_to_world_position(coords.x, coords.y)
		
		# if player presses we attempt to build
		if Input.is_action_just_pressed("click"):
			build(coords.x, coords.y, selected_building)
	else:
		preview_parent.hide()
```
# 5.Adding buttons to select buildings

Look over the provided button_select_button.gd, which is attacthed to the button in building_selector.tscn
```gdscript
extends Button

var build_template : BuildingTemplate
var building_manager : Node

#this will be called from the build_manager when the button is created
func setup(building: BuildingTemplate, manager : Node):
	build_template = building
	text = building.name
	building_manager = manager

#this should be connected to the button pressed signal
func clicked():
	building_manager.select_building(build_template)

```

In building_manager.gd 
- add an export variable to store an array of all building, then fill it with all our building templates eg. house.tres in the inspector
- add a reference to the button scene
- add a reference to the ui container that will hold all of the buttons (be sure to drag the container node into the inspector box that @export creates)
```gdscript
@export var all_buildings : Array[BuildingTemplate]
const button_scene := preload("res://building_selector.tscn") #fill with what your path to building_selector.tscn is
@onready var button_container: VBoxContainer = $"../CanvasLayer/BuildingButtons" 
```

```gdscript
func setup_buttons() -> void:
	#loops through all buildings and creates a button for each
	for building in all_buildings:
		var button = button_scene.instantiate()
		button_container.add_child(button)
		button.setup(building, self)

```



