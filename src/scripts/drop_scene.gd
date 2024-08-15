@tool
class_name DropScene
extends Node2D

@export var drop_tint: Color
@export var drop_timeout := 1000

var delay: Delay
var initial_tint: Color
const distant_noise_offset := - 30 # db

@onready var animation = $AnimationPlayer

@onready var light_tint = $Environment/LighSelf/Tint
@onready var ligh_particle = $Environment/LighSelf/Particle
@onready var distant_death = $OtherDeathTint

@onready var audio = $AudioManager
@onready var scene_cover = $Postprocessing/OffCover
@onready var pov_cover = $Postprocessing/POVCover

func _ready():
  if Engine.is_editor_hint():
   return
  delay = Delay.new(self)
  initial_tint = light_tint.color
  reset()

func start():
  audio.play("spotlight")
  scene_cover.hide()

func drop():
  light_tint.color = drop_tint
  await _play_drop_sequence(false)
  animation.play("drop")
  await delay.wait(500)

  await _play_audio("accelerating")
  reset()

  await delay.wait(drop_timeout)

func safe():
  audio.play("spotlight")
  pov_cover.show()
  _self_light_off()

  await _simulate_distant_drop()

func reset():
  _self_light_on()
  light_tint.color = initial_tint

  # animation.play("idle")
  distant_death.hide()
  scene_cover.show()
  pov_cover.hide()

func _simulate_distant_drop():
  distant_death.show()
  await _play_drop_sequence(true)
  await delay.wait(drop_timeout)
  await _play_audio("distant_crash", true)
  reset()

func _self_light_on():
  light_tint.show()
  ligh_particle.show()

func _self_light_off():
  light_tint.hide()
  ligh_particle.hide()

func _play_drop_sequence(distant=false):
  await _play_audio("selected", distant)
  await _play_audio("init", distant)
  _play_audio("release", distant)

func _play_audio(t: String, distant=false):
  var config = {"volume": distant_noise_offset if distant else 0}
  await audio.play(t, config)