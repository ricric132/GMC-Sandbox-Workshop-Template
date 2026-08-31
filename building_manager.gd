extends Node3D

@onready var cam: Camera3D = $"../Camera3D"
@onready var corner: Node3D = $"../Floor/Corner"
@onready var preview: Node3D = $"../Preview"
@onready var building_parent: Node3D = $"../BuildingParent"

var grid : Array[Array] = []
const WIDTH = 30
const HEIGHT = 30
const TILE_SIZE = 1

@export var selected_building : BuildingTemplate

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup_grid()

func setup_grid():
	grid.resize(WIDTH)
	for x in WIDTH:
		grid[x]=[]
		grid[x].resize(HEIGHT)
		for y in HEIGHT:
			grid[x][y]= Tile.new(x, y)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	
	var space_state = get_world_3d().direct_space_state
	var from = cam.project_ray_origin(mouse_pos)
	var to = from + cam.project_ray_normal(mouse_pos) * 1000
	var ray = PhysicsRayQueryParameters3D.create(from, to)
	ray.collision_mask = (1 << 1-1)
	var result = space_state.intersect_ray(ray)
	
	if result:
		var coords = world_to_grid_coords(result.position)
		preview.global_position = grid_to_world_position(coords.x, coords.y)
		if(Input.is_action_just_pressed("click")):
			build(coords.x, coords.y, selected_building)

func build(x : int, y : int, building : BuildingTemplate):
	if(!check_valid(x, y, building)):
		return
	
	var built : Node = building.build_object.instantiate()
	building_parent.add_child(built)
	built.global_position = grid_to_world_position(x, y)
	
	for i in building.dimension.x:
		for j in building.dimension.y:
			var check_coords = Vector2i(x+i, y+j)
			grid[check_coords.x][check_coords.y].building = built


func check_valid(x : int, y : int, building : BuildingTemplate) -> bool:
	for i in building.dimension.x:
		for j in building.dimension.y:
			var check_coords = Vector2i(x+i, y+j)
			
			if check_coords.x >= WIDTH || check_coords.x < 0:
				return false
			if check_coords.y >= HEIGHT || check_coords.y < 0:
				return false
			if !grid[check_coords.x][check_coords.y].is_empty():
				return false
				
	return true

func grid_to_world_position(x : int, y : int) -> Vector3:
	var coord = Vector3(x, 0, y)
	return corner.global_position + coord * TILE_SIZE

func world_to_grid_coords(pos: Vector3) -> Vector2i:
	var recentered_pos = pos - corner.global_position
	return Vector2i(recentered_pos.x/TILE_SIZE, recentered_pos.z/TILE_SIZE)
