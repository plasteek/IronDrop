extends Node2D

var delay: Delay

@onready var animator = $IdleAnimator
@onready var music_animator = $MusicAnimator
@onready var fade = $FadeTransition
@onready var click_area = $Area2D

func _ready():
  click_area.visible = false
  delay = Delay.new(self)

  await delay.wait(1000)
  await fade.fade_in(true)

  animator.play("fade_between")
  click_area.visible = true

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int):
  if event is InputEventMouseButton and event.is_pressed and event.button_index == 1:
   music_animator.play("music_fade")
   await fade.fade_out(true)
   await delay.wait(1000)
   Globals.change_scene("res://scenes/main_game.tscn")
