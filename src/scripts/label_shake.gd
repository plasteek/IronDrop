extends Label

@export var max_offset = 10.0

var original_pos: Vector2

func _ready():
  original_pos = position

func _process(_delta):
  var shift = Vector2(randi_range( - max_offset, max_offset), randi_range( - max_offset, max_offset))
  position = original_pos + shift
