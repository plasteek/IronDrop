extends Node2D

@onready var drop: DropScene = $DropScene

var delay = Delay

func _ready():
  delay = delay.new(self)
  await delay.wait(1000)

  drop.start();
  await delay.wait(2000)
  drop.drop()
