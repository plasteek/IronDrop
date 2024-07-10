class_name Delay
extends RefCounted

var timer: Timer

func _init(targetNode: Node):
  timer = Timer.new()
  timer.autostart = false
  targetNode.add_child(timer)

func wait(timeoutInMs: int):
  timer.wait_time = timeoutInMs / 1000.0 # to seconds
  timer.start()
  return await timer.timeout
