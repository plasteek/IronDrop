class_name FadeTransition
extends Node2D

@export var start_covered := true
@export_range(0, 2, 0.1, "or_less") var fade_speed := 1.0
@export var cover_color: Color = Color(0, 0, 0, 1):
  set(new_value):
   cover_color = new_value
  
@onready var animation: AnimationPlayer
@onready var cover: ColorRect

func _ready():
  if Engine.is_editor_hint():
   return

  cover = $Cover
  animation = $AnimationPlayer
  cover.color = cover_color

  if start_covered:
   cover.modulate.a = 1
  else:
   cover.modulate.a = 0
  
  cover.visible = true
  animation.speed_scale = fade_speed

func fade_in(linear=false):
  if linear:
   animation.play("fade_in_linear")
  else:
   animation.play("fade_in")
  await animation.animation_finished
func fade_out(linear=false):
  if linear:
   animation.play("fade_out_linear")
  else:
   animation.play("fade_out")
  await animation.animation_finished
