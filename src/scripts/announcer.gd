extends Node2D

@export var delay_per_announcement := 200
@export var hold_timeout := 1000

@export_group("Sounds")
@export_file var type_sound = null

@export_group("Tempo")
@export var delay_per_chara := 65

@export var short_pause_timeout := 100
@export var chara_short_pause: Array[String] = [',', ';', ":"]

@export var long_pause_timeout := 200
@export var chara_long_pause: Array[String] = ['.', '!', '?']

var delay: Delay
var mutex: Mutex # Ensure label appears one at a time

@onready var sound_player: AudioManager = $AudioManager

@onready var label = $PanelContainer/Label

func _ready():
  delay = Delay.new(self)
  mutex = Mutex.new()

func announce(text: String):
  mutex.lock()

  label.text = ""
  label.show()

  for c in text:
   label.text += c

   if c == " ":
     await delay.wait(short_pause_timeout)
     continue

   sound_player.play("typing")

   if c in chara_short_pause:
     await delay.wait(short_pause_timeout)
   elif c in chara_long_pause:
     await delay.wait(long_pause_timeout)
   else:
     await delay.wait(delay_per_chara)

  await delay.wait(hold_timeout)
  label.hide()

  await delay.wait(delay_per_announcement)
  mutex.unlock()
