extends ColorRect

@export var blink_rate = 3 # Hz
var timer: Timer

# Called when the node enters the scene tree for the first time.
func _ready():
  var blink_timeout = 1.0 / blink_rate
  timer = Timer.new()
  timer.wait_time = blink_timeout
  timer.autostart = false
  timer.timeout.connect(_toggle_caret)
  add_child(timer)

  timer.start()

func _toggle_caret():
  if visible:
   hide()
  else:
   show()
  timer.start()
