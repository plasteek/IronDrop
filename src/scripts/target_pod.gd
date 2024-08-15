extends Node2D

signal pod_clicked;

@export var drop_acceleration = 10
@export var pod_dropped_timeout = 1000 # Time will we consider pod has been dropped

var delay: Delay

var active = true
var has_dropped = false
var drop_velocity = 0

@onready var selected = $Selected
@onready var idle = $Idle
@onready var pod = $PodAnchor/ChainPodAnchor/PodSprite
@onready var audio = $AudioManager
@onready var animation = $AnimationPlayer

func _ready():
  delay = Delay.new(self)
  animation.play("idle_swing")

  # Ensure not everything swings the sample way
  randomize()
  var animation_len = animation.current_animation_length
  animation.seek(randi_range(0, animation_len))

  idle.show()
  selected.hide()

func _process(delta):
  pod.position += Vector2(0, drop_velocity * delta)
  if has_dropped:
   drop_velocity += drop_acceleration * delta # Ensure acceleration also not affected

func drop_pod():
  await audio.play("drop_init")
  audio.play("drop_release", {"volume": - 20})
  has_dropped = true
  await delay.wait(pod_dropped_timeout)
  await audio.play("drop_crash")

func hover_enter():
  audio.play("hover")
  idle.hide()
  selected.show()

func hover_leave():
  idle.show()
  selected.hide()

func pod_select():
  audio.play("selected")
  active = false

  idle.hide()
  selected.show()
  pod_clicked.emit()

func deactivate():
  active = false
  idle.hide()
  selected.hide()
  pod.hide()

func get_size():
  # Get the texture size in the actual game
  var size = selected.texture.get_size()
  size.x *= selected.scale.x
  size.y *= selected.scale.y
  return size

func _on_area_2d_mouse_exited():
  if active:
   hover_leave()

func _on_area_2d_mouse_entered():
  if active:
   hover_enter()

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
  if not active:
   return
  if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
   pod_select()
