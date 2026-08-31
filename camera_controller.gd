extends Camera3D

var pan_speed : float = 20
var rot_speed : float = 2
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var move_x : float = Input.get_axis("move_left", "move_right")
	var move_y : float = Input.get_axis("move_forward", "move_back")
	
	var left : Vector3 = get_global_transform().basis.x
	var forward : Vector3 = get_global_transform().basis.z
	forward.y = 0
	
	position += (left*move_x + forward*move_y)  * pan_speed * delta 
	
	var rotation_input : float = Input.get_axis("look_left", "look_right")
	
	rotate(Vector3(0, 1, 0), -rotation_input * rot_speed * delta)
