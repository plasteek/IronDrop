class_name BlankMarkup
extends Markup

# Does absolutely nothing

func make(_role: String, content: String):
  return content

func apply_chat_template(messages):
  return "\n".join(messages)

func create_start_token(_role):
  return "\n"

func is_stop_token(_t):
  return false