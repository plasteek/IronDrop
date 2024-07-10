extends Node2D

@onready var annoucer = $Announcer
@export var annoucement_timeout := 1000
@export var announcement_string = [
  "Another victim of my own making",
  "It wasn't supposed to end like this",
  "Get up. You work is not done yet",
  "Already dead? This is pathetic",
]

var delay: Delay
func _ready():
  delay = Delay.new(self)

  await delay.wait(annoucement_timeout)
  await annoucer.announce(announcement_string.pick_random())

func _on_button_button_clicked():
  Globals.change_scene("res://scenes/main_menu.tscn")
