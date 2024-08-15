extends Node2D

@onready var input = $UserInput
@onready var audio = $AudioManager

var available_sounds := []
var current_track = 0

func _ready():
  input.text_changed.connect(_on_text_changed)
  input.focus_entered.connect(_on_focus_entered)
  input.gui_input.connect(_on_gui_input)

  available_sounds = audio.get_available_tracks()

func _on_text_changed(new_text: String):
  _set_caret_to_end()
  _play_type_sound()

func _on_focus_entered():
  _set_caret_to_end()

func _on_gui_input(event):
  _set_caret_to_end()

func _set_caret_to_end():
  var text_len = input.text.length()
  input.caret_column = text_len

var play_count = 0 # Play sequentially
func _play_type_sound():
  var track_index = Util.wrap(0, available_sounds.size() - 1, play_count)
  audio.play(available_sounds[track_index])
  play_count += 1