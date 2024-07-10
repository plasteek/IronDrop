class_name TimerCounter
extends RefCounted

var timers := Map.new()

func start(tag: String):
  timers.set_value(tag, Time.get_ticks_msec())

func stop(tag: String) -> float:
  var start_time = timers.get_value(tag)
  if start_time == null:
   push_error("No timer named %s" % tag)

  var current_time = Time.get_ticks_msec()
  var elapsed = current_time - start_time
  return elapsed
