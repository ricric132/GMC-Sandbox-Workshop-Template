extends Node3D

@onready var cam: Camera3D = $"../Camera3D"
@onready var preview_parent: Node3D = $"../PreviewParent"
@onready var grid_corner: Node3D = $"../Grid/Floor/GridCorner"
@onready var building_parent: Node3D = $"../Grid/BuildingParent"
@onready var button_container: VBoxContainer = $"../CanvasLayer/VBoxContainer"

var grid : Array[Array] = []
const WIDTH = 30
const HEIGHT = 30
const TILE_SIZE = 1

@export var selected_builidng : BuildingTemplate
@export var all_buildings : Array[BuildingTemplate]

const  button_scene := preload("res://building_selector.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup_grid()
	setup_buttons()

func setup_grid():
	grid.resize(WIDTH)
	for x in WIDTH:
		grid[x]=[]
		grid[x].resize(HEIGHT)
		for y in HEIGHT:
			grid[x][y] = Tile.new(x, y)

func setup_buttons():
	for building in all_buildings:
		var button = button_scene.instantiate()
		button_container.add_child(button)
		button.setup(building, self)
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var mousePos = get_viewport().get_mouse_position()
	
	var space_state = get_world_3d().direct_space_state
	var from = cam.project_ray_origin(mousePos)
	var to = from + cam.project_ray_normal(mousePos) * 1000
	var ray = PhysicsRayQueryParameters3D.create(from, to)
	ray.collision_mask = (1 << 1-1)
	var result = space_state.intersect_ray(ray)
	
	if(result && selected_builidng):
		var coords = world_to_grid_coords(result.position)
		preview_parent.global_position = grid_to_world_position(coords.x, coords.y)
		
		if Input.is_action_just_pressed("click"):
			build(coords.x, coords.y, selected_builidng)


func build(x : int, y : int, building : BuildingTemplate):
	if(!check_valid(x, y, building)):
		return
	
	var built : Node = building.build_object.instantiate()
	building_parent.add_child(built)
	built.global_position = grid_to_world_position(x, y)
	
	for i in building.dimension.x:
		for j in building.dimension.y:
			var check_coord = Vector2i(x, y) + Vector2i(i, j)
			
			grid[check_coord.x][check_coord.y].building = built 

func check_valid(x : int, y : int, building : BuildingTemplate):
	for i in building.dimension.x:
		for j in building.dimension.y:
			var check_coord = Vector2i(x, y) + Vector2i(i, j)
			
			if check_coord.x >= WIDTH || check_coord.x < 0:
				return false
			if check_coord.y >= HEIGHT || check_coord.y < 0:
				return false
			if grid[check_coord.x][check_coord.y].is_empty() == false:
				return false
	
	return true

func grid_to_world_position(x : int, y: int):
	var coords = Vector3(x, 0, y)
	return grid_corner.global_position + coords * TILE_SIZE
	
func world_to_grid_coords(pos : Vector3):
	var recentred_pos = pos - grid_corner.global_position
	return Vector2i(recentred_pos.x/TILE_SIZE, recentred_pos.z/TILE_SIZE)

func select_building(building:BuildingTemplate):
	selected_builidng = building
