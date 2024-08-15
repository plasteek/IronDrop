class_name ComputerState
extends State

# Describes state for ai interaction with the computer
@export var computer: Computer
var computer_available = true

const F = FMLInterpreter.Function
const P = FMLInterpreter.Param
const PT = FMLInterpreter.ParamType

func _init():
  super._init('computer')

func enable_computer():
  computer_available = true
func disable_computer():
  computer_available = false

func _get_actions(_agent) -> Array[F]:
  if not computer_available:
   return []
  return [
   F.new("send_message", _send_msg, [P.new("message", PT.STRING)]),
   F.new("send", _send_msg, [P.new("message", PT.STRING)]),
  ]

func _send_msg(msg: String):
  computer.machine.send_signal("new_message", [msg])