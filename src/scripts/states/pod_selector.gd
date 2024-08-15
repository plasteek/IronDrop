class_name PodSelectorState
extends State

signal pod_chosen(num: int)

var choosing = false
var chosen_pod = null

func _init():
  super._init("available_pods", null)

func _get_actions(_agent):
  if not choosing:
   return []

  const F = FMLInterpreter.Function
  const P = FMLInterpreter.Param
  const PT = FMLInterpreter.ParamType
  return [
   F.new("select_pod", select_pod, [P.new("pod_number", PT.STRING)])
  ]

func choose_from(count: int):
  var choice = []
  choosing = true
  for i in range(0, count):
   choice.push_back(i + 1)
  # Update own value
  self.value = choice

func select_pod(num):
  pod_chosen.emit(int(num))
  self.value = []
  choosing = false
