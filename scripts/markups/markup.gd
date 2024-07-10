class_name Markup
extends RefCounted

# Base class for chat model markups
# Yes they ideally should be static methods, but godot is very crap
# and will scream at me because "you have to use the Markup instance directly
# bohoo warning.

func apply_chat_template(array_of_messages: Array) -> String:
  push_error("NOT IMPLEMENTED: apply_chat_template", array_of_messages)
  return ""

func apply_template_to_message(message: Message) -> String:
  return apply_chat_template([message])

func create_chat_template(role: String, msg: String) -> String:
  return apply_chat_template([
   Message.new(role, msg)
  ])

func create_start_token(role: String) -> String:
  push_error("NOT IMPLEMENTED: create_start_token", role)
  return ""

func append_start_token(role: String, payload: String) -> String:
  return payload + "\n" + create_start_token(role) + "\n"

func is_stop_token(token: String) -> bool:
  push_error("NOT IMPLEMENTED: is_stop_token", token)
  return false

class Message:
  var role: String
  var content: String

  func _init(author: String, msg: String):
   self.role = author
   self.content = msg

# Factory function for better separation of convern
# We combine it here because MarkupFactory sounds weird

enum Style {CHATML, PHI, LLAMA, BLANK}

static func create(style: Style):
  match style:
   Style.CHATML:
     return ChatMLMarkup.new()
   Style.PHI:
     return PhiMarkup.new()
   Style.LLAMA:
     return LlamaMarkup.new()
   Style.BLANK:
     return BlankMarkup.new()
   _:
     return ChatMLMarkup.new()
