class_name AgentState
extends RefCounted

# data class that represents an agent state at a given moment

var goal: String = ""
var knowledge: String = ""
var history: Array[String] = []

var pending_events: Array[String] = []
var states: Array[State] = []
var functions: Array[String] = []

# Actual function definitions
var function_impls: Array[FMLInterpreter.Function] = []
var response: String # possibly null

static func capture(agent: Agent):
  var new_state = AgentState.new()

  var persona = agent.persona
  new_state.goal = persona.goal
  new_state.knowledge = persona.knowledge

  for r in agent.history.get_entries():
   new_state.history.push_back(r)

  for o in agent.pending_events:
   new_state.pending_events.push_back(o)

  for s in agent.states: # Record the current states
   var value = s.value

   var s_actions = s._get_actions(agent)
   for s_action in s_actions:
     new_state.functions.push_back(s_action.str())
     new_state.function_impls.push_back(s_action)

   if value == null: # Skip null values
     continue

   var cloned = State.new(s.sname, s.value)
   new_state.states.push_back(cloned)

  return new_state
