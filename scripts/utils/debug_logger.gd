class_name DebugLog
extends Node

var should_log := false
func _init(enable=false):
  should_log = enable

func log(msg: String):
  if should_log:
   print(msg)
