class_name State
extends Node

var sname: String
var value: Variant

func _init(_name: String, _val=null):
  sname = _name
  value = _val

func _get_actions(_agent: Agent) -> Array[FMLInterpreter.Function]:
  push_error("Not Implemented `get_available_functions`")
  return []
