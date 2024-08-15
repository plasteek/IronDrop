class_name StateMachine
extends RefCounted

# Naive State Machines

var log_activity = false
var current_state: FSMState

var states: Map

# First state is initial
func _init(_states: Array[FSMState]):
  states = Map.new()
  current_state = _states[0]
  for state in _states:
   states.set_value(state.name, state)

  # Ensure all transitions has a valid target
  for state in states.values():
   for transition in state.transitions.values():
     # Null means transition to self
     if transition.target == null:
      transition.target = state.name
     var target = transition.target

     if not states.has(target):
      push_error("'{}' is not a valid target state in '{}".format([target, state.name], "{}"))
      continue

  current_state = _states[0]
  _log("INITIAL STATE: " + current_state.name)
  current_state.on_entry.call()

func send_signal(signal_name: String, param: Array=[]):
  var transitions = current_state.transitions
  if not transitions.has(signal_name):
   _error("State({}) cannot handle signal ({})".format([current_state.name, signal_name], "{}"))
   return

  var transition = transitions.get_value(signal_name)
  var target_name = transition.target

  if target_name == null:
   target_name = current_state.name
  if not target_name in states.keys():
   _error("{} is not a valid state".format([target_name], "{}"))
   return

  var should_transition = transition.guard.call()
  if should_transition:
   var old_state = current_state
   current_state = states.get_value(target_name)
   _log("TRANSITIONING FROM {} TO {} ".format([old_state.name, current_state.name], "{}"))

   old_state.on_leave.call()
   transition.callback.callv(param)
   current_state.on_entry.call()

func _log(s: String):
  if log_activity:
   print(s)
func _error(s: String):
  if log_activity:
   push_error(s)
  
class FSMState:
  var name: String
  var on_entry: Callable
  var on_leave: Callable
  var transitions: Map # Map,signal_name, transition>

  func _init(_name: String, _transitions: Array[FSMTransition]=[], _entry: Callable=func(): pass , _leave: Callable=func(): pass ): # Dictionary {enter, leave, on: {[other_transitions]: FSMTransition} }
   name = _name
   on_entry = _entry
   on_leave = _leave

   transitions = Map.new()
   for transition in _transitions:
     transitions.set_value(transition.name, transition)

class FSMTransition:
  var name: String
  var guard: Callable
  var callback: Callable
  var target # Nullable String

  func _init(signal_name: String, _callback: Callable, _target=null, guard_func: Callable=func(): return true):
   name = signal_name
   target = _target
   guard = guard_func
   callback = _callback
