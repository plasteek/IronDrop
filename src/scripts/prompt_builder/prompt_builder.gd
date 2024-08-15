class_name PromptBuilder
extends Node

func make_prompt(_state: AgentState, _include_bos=true):
  push_error("ERROR: Not implemented")

func make_few_shots_prompt(_few_shots: Array): # Array[Agent]
  push_error("ERROR: Not implemented")

func embed_system_prompt(_prompt: String):
  push_error("ERROR: Not implemented")

func is_stop_token(_s: String):
  push_error("ERROR: Not implemented")
