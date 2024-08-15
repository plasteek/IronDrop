extends Node2D

@export var easter_egg_timeout := 10000
@export var annoucement_timeout := 1000
@export var announcement_string = [
  "Still alive? Good.",
  "You are not supposed to be here",
  "I'll get you next time.",
  "There won't be a next time"
]

var delay: Delay

@onready var annoucer = $Announcer
@onready var audio = $AudioManager
@onready var animation = $AnimationPlayer
@onready var transition = $FadeTransition

func _ready():
  delay = Delay.new(self)

  transition.fade_in()
  audio.play("enter")
  animation.play("enter")

  await delay.wait(annoucement_timeout)
  audio.play("ambience", {"persistent": true})

  await annoucer.announce("Hey, thanks for playing!")
  await annoucer.announce("Remember to give feedbacks!")

  await delay.wait(easter_egg_timeout)

  audio.play("stringer")
  await annoucer.announce(announcement_string.pick_random())

func _on_button_button_clicked():
  await delay.wait(500)
  Globals.change_scene("res://scenes/main_menu.tscn")
