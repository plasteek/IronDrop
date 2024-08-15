class_name PhiMarkup
extends Markup

static var start_token_template = "<|{role}|>"
static var end_token = "<|end|>"

func make(role: String, content: String):
  return "{start}\n{content}{end}".format({
   "start": create_start_token(role),
   "content": content,
   "end": end_token,
  })

func apply_chat_template(messages):
  var result = ""
  for i in range(messages.size()):
   var message = messages[i]
   var role = message.role
   var content = message.content

   result += make(role, content)
   if i != messages.size() - 1:
     result += "\n"
  return result

func create_start_token(role):
  return start_token_template.format({
   "role": role
  })

func is_stop_token(t):
  return t == end_token
