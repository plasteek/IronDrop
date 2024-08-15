class_name ChatGeneration
extends LlamaGD

# Injecting Conversational Chat Template into a model

const sys_role = "system"
const user_role = "user"
const agent_role = "assistant"

@export_category("Configuration")
@export var markup_style: Markup.Style
@export_multiline var system_prompt := "You are a helpful assistant that answers descriptively"

var messages := [] # Of Messages
var markup: Markup;

func _ready():
  # Always initialize system prompt
  add_system_message(system_prompt)
  markup = Markup.create(markup_style)

func add_system_message(msg: String):
  _add_message(sys_role, msg)
func add_assistant_message(msg: String):
  _add_message(agent_role, msg)
func add_user_message(msg: String):
  _add_message(user_role, msg)
  
func clear_messages():
  messages = []
  add_system_message(system_prompt)

func create_chat_completion(prompt: String) -> String:
  add_user_message(prompt)
  var payload := markup.apply_chat_template(messages)
  var generation_payload := markup.append_start_token("assistant", payload)

  create_completion_async(generation_payload)
  var response = await generation_completed
  add_assistant_message(response)

  return response

func _add_message(role: String, message: String):
  messages.append(Markup.Message.new(role, message))