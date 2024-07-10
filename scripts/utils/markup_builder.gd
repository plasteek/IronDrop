class_name MarkupBuilder
extends RefCounted

# Utility class that helps constructing chat markup

var machine: Markup
var messages: Array[Markup.Message] = []

func _init(target_markup: Markup):
  machine = target_markup

func add_message(tag: String, message: String):
  messages.append(Markup.Message.new(tag, message))
func clear_messages():
  messages = []

func build():
  return machine.apply_chat_template(messages)
