class_name AutoplayWithDelay
extends AudioStreamPlayer

@export var delay: int = 1000

var _delay: Delay

func _ready():
  _delay = Delay.new(self)
  await _delay.wait(delay)
  play()
