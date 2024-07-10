@tool
extends Node2D

signal button_clicked

@export var text := "Text":
   set = _update_text
@export var color: Color:
   set = _update_modulation

var m: StateMachine

@onready var sprite = $AnimatedSprite2D
@onready var label = $Label
@onready var audio: AudioManager = $AudioManager

func _ready():
  const S = StateMachine.FSMState
  const T = StateMachine.FSMTransition

  m = StateMachine.new([
   S.new("released", [
     T.new("btn_pressed", button_pressed, "pressed")
   ]),
   S.new("pressed", [
     T.new("btn_release", button_released, "released")
   ]),
  ])

func button_pressed():
  audio.play("press")
  sprite.play("pressed")

func button_released():
  audio.play("release")
  sprite.play("idle")
  button_clicked.emit()

func _update_text(new_text: String) -> void:
  $Label.text = new_text
  text = new_text

func _update_modulation(new_color: Color) -> void:
  $AnimatedSprite2D.self_modulate = new_color
  color = new_color

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
  if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
   m.send_signal("btn_pressed")
  if event is InputEventMouseButton and not event.is_pressed() and event.button_index == 1:
   m.send_signal("btn_release")

# TODO: maybe add animation for when button is going in and out
func _on_area_2d_mouse_exited() -> void:
  pass

func _on_area_2d_mouse_entered() -> void:
  pass
