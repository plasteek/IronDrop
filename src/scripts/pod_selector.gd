class_name PodSelector
extends Node2D

@export var pod_drop_wait := 1000
@export var pod_dropped_timeout := 1000
@export var margin_x := 10

signal pod_chosen(number: int)

var pod_size: Vector2
var pod_scene = preload ("res://components/pod.tscn")

var current_pods = []
var initial_pos = Vector2(0, 0)
var selected_pod = -1
var pod_to_drop = null

var delay: Delay

@onready var ref_pod = $RefPod
@onready var audio: AudioManager = $AudioManager

func _ready():
  initial_pos.x = position.x
  initial_pos.y = position.y

  delay = Delay.new(self)
  pod_size = ref_pod.get_size()
  ref_pod.hide()

func select_from(count: int):
  # relative coordinate to the in-scene based on coordinate 0,0
  var total_size = (count - 1) * margin_x + count * pod_size.x
  # imagine case with 3, the middle one contributes "half" extra width
  # to the actual coordinate so it starts half extra width earlier
  var start_x = -(total_size / 2) + pod_size.x / 2

  for i in range(count):
   var new_pod = pod_scene.instantiate()
   var offset = i * (pod_size.x + margin_x)
   new_pod.position = Vector2(start_x + offset, 0)

   new_pod.pod_clicked.connect(func(): listen_for_click(i))
   new_pod.pod_dropped_timeout = pod_dropped_timeout

   add_child(new_pod)
   current_pods.append(new_pod)
  
  audio.play("selection_start")

func listen_for_click(index: int):
  selected_pod = index
  for i in range(0, current_pods.size()):
   if i == selected_pod:
     continue
   var pod = current_pods[i]
   pod.deactivate()
  
  var target_pod = current_pods[selected_pod]
  _drop_pod(target_pod, selected_pod)

func cleanup():
  for pod in current_pods:
   remove_child(pod)
   pod.queue_free()
  current_pods = []
  selected_pod = -1

  audio.play("selection_end")

func _drop_pod(pod, pod_index):
  await delay.wait(pod_drop_wait)
  await pod.drop_pod()

  cleanup()
  pod_chosen.emit(pod_index + 1) # Convert to pod number
