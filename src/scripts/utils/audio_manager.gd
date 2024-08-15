@tool

class_name AudioManager
extends Node

signal finished

@export_group("Globals")
@export var volume_db := 0
@export var pitch_scale := 1

@export_group("Audio")
@export var audio_labels: Array[String] = []
@export var audio_sources: Array[AudioStream] = []:
  set(new_sources):
   if Engine.is_editor_hint(): # The array adjustment should only be in editor
     if not intern_has_init: # Check if the editor initialize
      audio_sources = new_sources
      intern_has_init = true
      return

     var source_count_diff = new_sources.size() - audio_sources.size()
     if source_count_diff < 0:
      audio_labels = audio_labels.slice(0, new_sources.size())
     elif source_count_diff > 0:
      # Add until the array for label match
      for i in range(source_count_diff):
        var new_labels = audio_labels.duplicate()
        new_labels.append("Untitled Track")
        audio_labels = new_labels

   audio_sources = new_sources

var persistent_audios: Array[AudioStreamPlayer] = []
var intern_has_init = false # For tooling and as ahack

var audio_map: Map
var defaults: Dictionary

func _ready():
  if Engine.is_editor_hint(): # Code should only run in game
   return

  audio_map = Map.new()
  for i in range(0, audio_labels.size()):
   var label = audio_labels[i]
   var audio_stream = audio_sources[i]
   audio_map.set_value(label, audio_stream)
  
  defaults = {
   "persistent": false,
   "volume": volume_db,
   "pitch": pitch_scale
  }

func play_random(config: Dictionary={}):
  var track_name = audio_map.keys().pick_random()
  play(track_name, config)

# Config = {persistent: boolean, volume: int}
func play(track_name: String, config: Dictionary={}):
  var target_stream = audio_map.get_value(track_name)

  config.merge(defaults) # Defaults
  var persistent = config['persistent']
  var volume = config['volume']
  var pitch = config['pitch']

  if target_stream == null:
   push_error("'%s' is not a valid track" % track_name)
   return

  if target_stream.loop and not persistent:
   push_error("Cannot play a persistent audio if the import is not looped '%s'" % track_name)
   return

  var new_player = AudioStreamPlayer.new()
  new_player.stream = target_stream
  new_player.volume_db = volume
  new_player.pitch_scale = pitch

  add_child(new_player)
  new_player.play()

  if target_stream.loop and persistent: # It keeps playing
   persistent_audios.append(new_player)
   return

  await new_player.finished
  finished.emit()

  remove_child(new_player)
  new_player.queue_free()

func resume_persistent_audios():
  for node in persistent_audios:
   node.play()

func pause_persistent_audios():
  for node in persistent_audios:
   node.stop()

func get_available_tracks():
  return audio_map.keys()

func get_track_length_ms(track_name: String):
  var track = audio_map.get_value(track_name)
  if track != null:
   return track.get_length() * 1000
  return - 1
