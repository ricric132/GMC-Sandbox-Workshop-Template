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

In building_manager.gd
- implement setup buttons function and call it in the _ready() function
```gdscript
func _ready() -> void:
	setup_grid()
	setup_buttons() #add this

func setup_buttons() -> void:
	#loops through all buildings and creates a button for each
	for building in all_buildings:
		var button = button_scene.instantiate()
		button_container.add_child(button)
		button.setup(building, self)

```

In building_manager.gd 
- select_building function that is called by the button script
```gdscript
func select_building(building : BuildingTemplate):
	selected_building = building
```

Now you should be able to test it

# 6. Adding building previews

First take a look around the preview scenes eg.house_preview.tscn and the building_preview.gd script
```gdscript
extends Node3D

@export var valid_preview : Node
@export var invalid_preview : Node

func toggle_preview(is_valid : bool):
	valid_preview.visible = is_valid
	invalid_preview.visible = !is_valid
```

In building_manager.gd 
- Update the building_select function
```gdscript
func select_building(building : BuildingTemplate):
	selected_building = building 

	#add this
	if(active_preview):
		active_preview.queue_free()
	
	active_preview = building.build_preview.instantiate()
	preview_parent.add_child(active_preview)
```

 - Update _physics_process in building_manager to show/hide the preview object

```gdscript 
	# Checks if the cursor is on the platform and a buildig  is selected
	if(result && selected_building):
		# shows the preview build
		var coords : Vector2i = world_to_grid_coords(result.position)
		preview_parent.position = grid_to_world_position(coords.x, coords.y, cur_rot)

		#add this
		preview_parent.show()
		active_preview.toggle_preview(check_valid(coords.x, coords.y, selected_building))
		
		# if player presses we attempt to build
		if Input.is_action_just_pressed("click"):
			build(coords.x, coords.y, selected_building)
#add this
	else:
		preview_parent.hide()

```

Now previews should appear when you build and it should be red when invalid building location and blue when valid

# 7. Adding rotations to the buildings

In buidling_manager.gd add some variables that will be used for rotating:
- rot_dir defines all the orientation directions the building can have
- rot_offset helps realign the rotated building with the grid
- rot_basis defines the 2 Vector2i for each rotation orentation that determines the direction the x-y dimensions of the building point
- cur_rot defines the current selected rotation
```gdscript
enum rot_dir {FORWARD = 0, RIGHT = 1, BACK = 2, LEFT = 3}
const rot_offset = [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 0)]
#basis for determinining x and y directions after roatation of a building
const rot_basis = [	[Vector2i(1, 0), Vector2i(0, 1)],
					[Vector2i(0, -1), Vector2i(1, 0)],
					[Vector2i(-1, 0), Vector2i(0, -1)],
					[Vector2i(0, 1), Vector2i(-1, 0)]
					]
var cur_rot : rot_dir = rot_dir.FORWARD
```


- add a change_rot to cycle through the rotations
```gdscript
func change_rot():
	cur_rot = (cur_rot+1)%4
```
- call the change rot function in physics_process when "rot" (currently binded to r) is pressed
```gdscript
if(Input.is_action_just_pressed("rot")):
	change_rot()
```
- rotate the preview in _physics_process
```gdscript
#add this
preview_parent.rotation_degrees = Vector3(0, cur_rot*90, 0)

#existing lines
preview_parent.show()
active_preview.toggle_preview(check_valid(coords.x, coords.y, selected_building))
```

- rotate the built object
```gdscript
# spawns in the building
var built : Node = building.build_object.instantiate()
building_parent.add_child(built)
built.global_position = grid_to_world_position(x, y)

built.rotation_degrees = Vector3(0, cur_rot*90, 0)  #add this line

built.building_manager = self
built.template = building
```

- now if you test this, you will see that by pressing "r" the object will rotate but it will not be placed on the square that the cursour is hovering and the validity of placments will no longer be enforced properly. This is because when we rotate the buildings the origin point of the building needs to change and the direction in which we check validity will also be different, as the building will be pointed in a different direction.

- edit grid_to_world_position function to allow for a rotation parameter (rotation has a default value as often we will not use the rotation)
```gdscript
func grid_to_world_position(x : int, y : int, rot : rot_dir = rot_dir.FORWARD) -> Vector3:
	#offset the grid coordinates based off of rotation to recentre corner of building
	var offsetted_coord = Vector3(x, 0, y) + Vector3(rot_offset[rot].x, 0 ,rot_offset[rot].y)
	return grid_corner.global_position + offsetted_coord * TILE_SIZE
```

- edit the grid_to_world_position function calls to use the new rot parameter
- in _physics_process
```gdscript
# shows the preview build
var coords : Vector2i = world_to_grid_coords(result.position)
preview_parent.position = grid_to_world_position(coords.x, coords.y, cur_rot)
```
- and in build function
```gdscript
# spawns in the building
var built : Node = building.build_object.instantiate()
building_parent.add_child(built)

built.global_position = grid_to_world_position(x, y, cur_rot) # edit this line

built.rotation_degrees = Vector3(0, cur_rot*90, 0)
built.building_manager = self
built.template = building
```

- edit build function and check valid function check_coord variable to account for the new direction the building is pointed. Replace the original check_coord with this
```gdscript
var check_coord : Vector2i = Vector2i(x, y)

# uses our basis to which direction the x and y of
# the building face
check_coord += rot_basis[cur_rot][0] * i
check_coord += rot_basis[cur_rot][1] * j
```

-now the rotations should work


# 8. Selecting/deleting buildings
- now we will move onto adding functionality to select and delete buildings

- first we can navigate to the building.gd script attatched to each building (when we want to implement individual functions and have each building do thier own things we would probably turn building into a superclass and give each building thier own script that inherits from building)
- now we want to add some variables and functions to the building.gd script
```gdscript
extends Node
class_name Building

@onready var highlight: MeshInstance3D = $Highlight

var template : BuildingTemplate
var building_manager : Node
var occupied_tiles : Array[Vector2i] = []

func update_highlight():
	if building_manager.highlighted_building == self:
		highlight.show()
	else:
		highlight.hide()

func building_selected():
	building_manager.highlight_building(self)


func _on_static_body_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			building_selected()
```


- then we want to implement the highlight_building function in building_manager.gd
- we also need to add the relevant variables to the script. building_info_panel is a UI object in the scene that will display some building info and the delete button. 
```gdscript
@onready var building_info_panel: Control = $"../CanvasLayer/BuildingInfoPanel"
var highlighted_building

func highlight_building(building: Node):	
	highlighted_building = building
	building_info_panel.setup(building)
```

- take a look at the building_info_panel scene and script, note the setup function that we call from out building_manager.gd is setting the text on the label to match the highlighted building's name (you can always add more to the setup function to display more info)
```gdscript
extends Control

@onready var building_name: Label = $BuildingName
@onready var building_manager: Node3D = $"../../BuildingManager"

func setup(building : Node):
	building_name.text = building.template.name

#make sure this is connected to the pressed() signal of the button
func _on_button_pressed() -> void:
	building_manager.delete_building()
```

- edit _physics_process in building_manager.gd, so that the building_info_panel is visible depending on if there is a highlighted building
```gdscript
func _physics_process(delta: float) -> void:
	if(highlighted_building):
		building_info_panel.show()
	else:
		building_info_panel.hide()
```

- now you can test it, when you select a building the info_panel should display its name however the delete button does not work yet because its trying to call delete_building() function in building_manager.gd but it doesnt exist yet
- implement building_manager.gd delete building function
```gdscript
func delete_building():
	if(highlighted_building):
		for coord in highlighted_building.occupied_tiles:
			grid[coord.x][coord.y].building = null
		highlighted_building.queue_free()
		highlighted_building = null
```

- we can now test, but now its annoying to buidl and select at the same time so lets implement a toggle for buiding and selecting mode

- add toggle_buildmode function to building_manager.gd and create a ui button and connect the pressed signal to the toggle_buildmode function
```gdscript
var is_building = false

func toggle_buildmode():
	is_building = !is_building
	button_container.visible = is_building
	highlighted_building = null
```

- now adjust the _physics_process
```gdscript
if(result && selected_building && is_building): #edit this line
```
- and add an is_building check to the highlight_building function
```gdscript
func highlight_building(building: Node):
	if(is_building):
		return
```
You can now run it and test out the new selecting and deleting system


# 9.Possible extensions

So now that we have the basics of a building system created, how might we expand on it?

This section will talk about possible extensions and give some details on how we could approach them, feel free to try implement these if you are interested. If there are any questions or if you need help with implementation feel free to ask me (ricric on the GMC discord)

## Importing as setting up your own 3d models for buildings:
- Create your own 3d models in your software of choice eg.blender
- Export as a .glb format (works best for godot but others should work) then just drag into your godot project
- You can copy he setup of the existing buildings and replace visual with your new model then match up the size of the highlight and collision area to match (here make sure that bottem left corner of your model lines up with the origin (0, 0) and is pointed in the right direction, see image for reference)
<img width="1160" height="550" alt="image" src="https://github.com/user-attachments/assets/5ae47d04-29d3-4b03-866e-5883505f4453" />

- Then for the preview create a copy of one of the existing preview scenes and replace the preview blue and preview red with the models you want for your valid preview and invalid preview (in the workshop we just used the same model but with the material fully blue/red) and add ensure it is also lined up with the origin.
- Then fill in the inspector export variables for the preview by draggin in your models from the scene heirarchy 
- Now create the building template custom resource and fill it in with your new scenes and set appropriate dimensions before adding it to the build_manager list of buildings 


## Turning the grid from a 2d grid to a 3d grid:
This will allow for buildings to be stacked on top of eachother.
This will be similiar to how Minecraft does its building system if you were consider all the blocks as individual buildings
To implement this:
- Add a z coordinate to Tile.gd
- Turn the grid 2D array into a 3D array 
- Adjust functions accordingly to account for the new dimensions this will include grid_to_world_position, world_to_grid_position, build and check_valid functions
- then we would need to turn the building dimensions in building_template.gd into a Vector3i so that we can store a height
- We would also make the camera raycast detect the buildings so that we can actually build ontop of buildings (do this by adding the collision layer of the buildings static_body to the layermask of the ray)

## Moving the camera 
With the current system we are not restricted to the topdown camera, for example we could create a first person cam for this game
- create a first person character movement script and change the var mousePos = get_viewport().get_mouse_position() in building_manager.gd to a constant vector 2 for the centre of the scene and we can start building in first person using a crosshair on the centre of the screen






