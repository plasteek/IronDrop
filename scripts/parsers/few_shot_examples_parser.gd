class_name FewShotExamplesParser
extends RefCounted

# Parse agent objects with their history as few-shots example

var chara_state_template := ""
var world_state_template := ""
var chara_description_template := ""

static func parse(s: String) -> Array[Agent]:
  var agents = JSON.parse_string(s)
  if agents == null:
   push_error("Invalid when parsing JSON file")

  var result: Array[Agent] = []
  for agent in agents:
   result.append(_parse_persona(agent))
  
  return result

static func _parse_persona(agent: Dictionary):
  var chara_name = agent["name"]
  var traits = agent['personality_traits']
  var desc = agent['description']

  var new_agent = Agent.new()
  new_agent.persona.persona_name = chara_name
  new_agent.persona.attributes = traits
  new_agent.persona.profile = desc

  for obv_object in agent["events"]:
   var obv = _parse_persona_events(obv_object)
   new_agent.state_history.append(obv)

  return new_agent

static func _parse_persona_events(event: Dictionary) -> AgentState:
  var agent_state = AgentState.new()

  # Expected JSON
  var goal = event['goal'] # String
  var knowledge_base = event['knowledge'] # Array[String]
  var recent = event['recent'] # Array[String]

  var occurences = event['occurrences'] # Array[String]
  var observed = event['observed'] # Dict<String, String>
  var actions = event['functions'] # Array[String]
  var response = event['response'] # Array[String]

  agent_state.goal = goal
  agent_state.knowledge = Util.list_array(knowledge_base, "- ")
  for e in recent:
   agent_state.history.append(e)

  for occurence in occurences:
   agent_state.pending_events.append(occurence)
  for state_name in observed:
   var state_value = observed[state_name]
   agent_state.states.append(State.new(state_name, state_value))
  for a in actions:
   agent_state.functions.append(a)
  agent_state.response = "\n".join(response)

  return agent_state
