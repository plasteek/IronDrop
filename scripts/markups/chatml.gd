class_name ChatMLMarkup
extends Markup

static var start_token = "<|im_start|>"
static var end_token = "<|im_end|>"

func make(role: String, content: String):
  return "{start}{role}\n{content}{end}".format({
   "start": start_token,
   "content": content,
   "end": end_token,
   "role": role,
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
  return "{start}{role}".format({
   "start": start_token,
   "role": role
  })

func is_stop_token(t):
  return t == end_token
