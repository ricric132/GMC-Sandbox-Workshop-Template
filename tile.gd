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
